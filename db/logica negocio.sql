/*
============================================================
  Universidad: Universidad Nacional de la Matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri Villalba, Santino; Llanos, Franco; Vazquez, Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Stored Procedures de logica de negocio.
               Operaciones que afectan multiples tablas,
               implementadas con transacciones para garantizar
               la integridad de los datos.
               Modulos cubiertos:
                 - Venta de entradas
                 - Contratacion de actividades/tours
                 - Asignacion de guias a tours
                 - Gestion de concesiones (pago y estado)
                 - Importacion de datos externos (log)
============================================================
*/
 
USE ParquesNacionalesDB;
GO
 
-- ============================================================
-- SP: sp_VentaEntradas
-- Descripcion: Registra una venta completa de entradas.
--   1. Crea el Ticket (cabecera de comprobante).
--   2. Por cada entrada, inserta un ItemTicket y una Entrada.
--   3. Actualiza el total del Ticket al finalizar.
--   Todo dentro de una transaccion. Si algo falla, hace ROLLBACK.
--
-- Parametros de cabecera del ticket:
--   @idPuntoVenta          : punto de venta emisor
--   @nroTicket             : numero de comprobante
--   @tipoComprobante       : 'Ticket', 'Factura A', etc.
--   @compradorNombreRazon  : nombre o razon social del comprador (opcional)
--   @compradorCuitDni      : CUIT o DNI del comprador (opcional)
--   @idFormaPago           : forma de pago
--   @fechaEmision          : fecha de emision (default hoy)
--   @moneda                : moneda del comprobante (default 'ARS')
--   @tipoCambio            : tipo de cambio (default 1)
--
-- Parametros del detalle de entradas (tabla tipo):
--   @entradas : TVP con columnas:
--       idVisitante  INT
--       idParque     INT
--       fechaAcceso  DATE
--   El SP buscara automaticamente el precio vigente para
--   cada combinacion (parque, tipo de visitante, fecha).
-- ============================================================
 
-- Primero creamos el tipo de tabla para pasar el detalle de entradas
IF NOT EXISTS (
    SELECT 1 FROM sys.types WHERE name = 'TipoEntradaDetalle' AND is_table_type = 1
)
BEGIN
    CREATE TYPE dbo.TipoEntradaDetalle AS TABLE (
        idVisitante INT  NOT NULL,
        idParque    INT  NOT NULL,
        fechaAcceso DATE NOT NULL
    );
END
GO
 
CREATE PROCEDURE sp_VentaEntradas
    -- Cabecera del ticket
    @idPuntoVenta         INT,
    @nroTicket            INT,
    @tipoComprobante      VARCHAR(50)   = 'Ticket',
    @compradorNombreRazon VARCHAR(200)  = NULL,
    @compradorCuitDni     VARCHAR(30)   = NULL,
    @idFormaPago          INT,
    @fechaEmision         DATE          = NULL,
    @moneda               VARCHAR(10)   = 'ARS',
    @tipoCambio           DECIMAL(10,4) = 1,
    -- Detalle de entradas
    @entradas             dbo.TipoEntradaDetalle READONLY
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores    VARCHAR(MAX) = '';
    DECLARE @idTicket   INT;
    DECLARE @idItem     INT;
    DECLARE @totalTicket DECIMAL(12,2) = 0;
 
    -- Fecha de emision por defecto = hoy
    IF @fechaEmision IS NULL
        SET @fechaEmision = CAST(GETDATE() AS DATE);
 
    -- ---- Validaciones de cabecera ----
    IF NOT EXISTS (SELECT 1 FROM parques.PuntoVenta WHERE idPuntoVenta = @idPuntoVenta AND activo = 1)
        SET @errores += '- El punto de venta no existe o no esta activo.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago)
        SET @errores += '- La forma de pago indicada no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE idPuntoVenta = @idPuntoVenta AND nroTicket = @nroTicket)
        SET @errores += '- Ya existe un ticket con ese numero en este punto de venta.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM @entradas)
        SET @errores += '- Debe incluir al menos una entrada.' + CHAR(13);
    IF @tipoCambio <= 0
        SET @errores += '- El tipo de cambio debe ser mayor a cero.' + CHAR(13);
 
    -- ---- Validaciones de cada entrada ----
    DECLARE @idVisitante INT, @idParque INT, @fechaAcceso DATE, @idPrecio INT, @monto DECIMAL(12,2);
    DECLARE @idTipoVisitante INT;
 
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT idVisitante, idParque, fechaAcceso FROM @entradas;
 
    OPEN cur;
    FETCH NEXT FROM cur INTO @idVisitante, @idParque, @fechaAcceso;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ventas.Visitante WHERE idVisitante = @idVisitante)
            SET @errores += '- Visitante ID ' + CAST(@idVisitante AS VARCHAR) + ' no existe.' + CHAR(13);
        IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
            SET @errores += '- Parque ID ' + CAST(@idParque AS VARCHAR) + ' no existe o no esta activo.' + CHAR(13);
        IF @fechaAcceso < @fechaEmision
            SET @errores += '- La fecha de acceso (' + CAST(@fechaAcceso AS VARCHAR) + ') no puede ser anterior a la fecha de emision.' + CHAR(13);
 
        -- Buscar precio vigente
        SELECT @idTipoVisitante = idTipoVisitante FROM ventas.Visitante WHERE idVisitante = @idVisitante;
 
        IF NOT EXISTS (
            SELECT 1 FROM ventas.PrecioEntrada
            WHERE idParque = @idParque
              AND idTipoVisitante = @idTipoVisitante
              AND vigenciaDesde <= @fechaAcceso
              AND (vigenciaHasta IS NULL OR vigenciaHasta >= @fechaAcceso)
        )
            SET @errores += '- No existe precio vigente para el visitante ID ' + CAST(@idVisitante AS VARCHAR)
                          + ' en el parque ID ' + CAST(@idParque AS VARCHAR)
                          + ' para la fecha ' + CAST(@fechaAcceso AS VARCHAR) + '.' + CHAR(13);
 
        FETCH NEXT FROM cur INTO @idVisitante, @idParque, @fechaAcceso;
    END
    CLOSE cur;
    DEALLOCATE cur;
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    -- ---- Transaccion ----
    BEGIN TRANSACTION;
    BEGIN TRY
 
        -- 1. Crear cabecera del ticket
        INSERT INTO ventas.Ticket
            (idPuntoVenta, nroTicket, tipoComprobante, compradorNombreRazon,
             compradorCultDni, idFormaPago, fechaEmision, total, moneda, tipoCambio, estado)
        VALUES
            (@idPuntoVenta, @nroTicket, @tipoComprobante, @compradorNombreRazon,
             @compradorCuitDni, @idFormaPago, @fechaEmision, 0, @moneda, @tipoCambio, 'Emitido');
 
        SET @idTicket = SCOPE_IDENTITY();
 
        -- 2. Por cada entrada: item + entrada
        DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
            SELECT idVisitante, idParque, fechaAcceso FROM @entradas;
 
        OPEN cur2;
        FETCH NEXT FROM cur2 INTO @idVisitante, @idParque, @fechaAcceso;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Obtener tipo de visitante y precio vigente
            SELECT @idTipoVisitante = idTipoVisitante
            FROM ventas.Visitante
            WHERE idVisitante = @idVisitante;
 
            SELECT TOP 1
                @idPrecio = idPrecioEntrada,
                @monto    = monto
            FROM ventas.PrecioEntrada
            WHERE idParque        = @idParque
              AND idTipoVisitante = @idTipoVisitante
              AND vigenciaDesde  <= @fechaAcceso
              AND (vigenciaHasta IS NULL OR vigenciaHasta >= @fechaAcceso)
            ORDER BY vigenciaDesde DESC;
 
            -- Insertar ItemTicket
            INSERT INTO ventas.ItemTicket (idTicket, cantidad, precioUnitario, subtotal)
            VALUES (@idTicket, 1, @monto, @monto);
 
            SET @idItem = SCOPE_IDENTITY();
 
            -- Insertar Entrada
            INSERT INTO ventas.Entrada
                (idItem, idVisitante, idParque, idPrecio, fechaAcceso, montoPagado, estado)
            VALUES
                (@idItem, @idVisitante, @idParque, @idPrecio, @fechaAcceso, @monto, 'Activa');
 
            SET @totalTicket += @monto;
 
            FETCH NEXT FROM cur2 INTO @idVisitante, @idParque, @fechaAcceso;
        END
        CLOSE cur2;
        DEALLOCATE cur2;
 
        -- 3. Actualizar total del ticket
        UPDATE ventas.Ticket SET total = @totalTicket WHERE idTicket = @idTicket;
 
        COMMIT TRANSACTION;
        SELECT @idTicket AS idTicket, @totalTicket AS totalTicket;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO
 
 
-- ============================================================
-- SP: sp_ContratarActividad
-- Descripcion: Registra la contratacion de un tour por parte
--   de un visitante, dentro de un ticket existente o creando
--   uno nuevo si @idTicket = NULL.
--   Controla el cupo disponible del tour y lo decrementa.
--   Aplica transaccion para garantizar integridad.
--
-- Parametros:
--   @idTicket        : ticket existente (NULL para crear uno nuevo)
--   @idPuntoVenta    : punto de venta (requerido si @idTicket es NULL)
--   @nroTicket       : numero de ticket (requerido si @idTicket es NULL)
--   @idFormaPago     : forma de pago (requerido si @idTicket es NULL)
--   @idTour          : tour a contratar
--   @idVisitante     : visitante que contrata
--   @cantidadPersonas: cantidad de personas para el tour
-- ============================================================
 
CREATE PROCEDURE sp_ContratarActividad
    @idTicket         INT          = NULL,
    @idPuntoVenta     INT          = NULL,
    @nroTicket        INT          = NULL,
    @idFormaPago      INT          = NULL,
    @idTour           INT,
    @idVisitante      INT,
    @cantidadPersonas INT          = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores       VARCHAR(MAX)  = '';
    DECLARE @cupoDisp      INT;
    DECLARE @montoUnitario DECIMAL(12,2);
    DECLARE @montoTotal    DECIMAL(12,2);
    DECLARE @idAtraccion   INT;
    DECLARE @idItem        INT;
    DECLARE @idNuevoTicket INT;
    DECLARE @fechaHoraInicio DATETIME;
 
    -- ---- Validaciones del tour ----
    SELECT
        @cupoDisp        = t.cupoDisponible,
        @idAtraccion     = t.idAtraccion,
        @fechaHoraInicio = t.fechaHoraInicio
    FROM atracciones.Tour t
    WHERE t.idTour = @idTour AND t.estado = 'Programado';
 
    IF @cupoDisp IS NULL
        SET @errores += '- El tour no existe o no esta en estado Programado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.Visitante WHERE idVisitante = @idVisitante)
        SET @errores += '- El visitante indicado no existe.' + CHAR(13);
    IF @cantidadPersonas <= 0
        SET @errores += '- La cantidad de personas debe ser mayor a cero.' + CHAR(13);
    IF @cupoDisp IS NOT NULL AND @cantidadPersonas > @cupoDisp
        SET @errores += '- No hay cupo suficiente. Cupo disponible: ' + CAST(@cupoDisp AS VARCHAR) + '.' + CHAR(13);
 
    -- Precio vigente de la atraccion
    SELECT TOP 1 @montoUnitario = monto
    FROM atracciones.PrecioAtraccion
    WHERE idAtraccion  = @idAtraccion
      AND vigenciaDesde <= CAST(GETDATE() AS DATE)
      AND (vigenciaHasta IS NULL OR vigenciaHasta >= CAST(GETDATE() AS DATE))
    ORDER BY vigenciaDesde DESC;
 
    -- Las atracciones gratuitas tienen monto 0; si no hay precio es error solo si es paga
    IF @montoUnitario IS NULL
        SET @montoUnitario = 0;  -- Sin precio configurado se trata como gratuita
 
    SET @montoTotal = @montoUnitario * @cantidadPersonas;
 
    -- Validar ticket existente o datos para crear uno nuevo
    IF @idTicket IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE idTicket = @idTicket AND estado = 'Emitido')
            SET @errores += '- El ticket indicado no existe o no esta en estado Emitido.' + CHAR(13);
    END
    ELSE
    BEGIN
        IF @idPuntoVenta IS NULL OR @nroTicket IS NULL OR @idFormaPago IS NULL
            SET @errores += '- Si no se indica un ticket existente, debe proveer idPuntoVenta, nroTicket e idFormaPago.' + CHAR(13);
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM parques.PuntoVenta WHERE idPuntoVenta = @idPuntoVenta AND activo = 1)
                SET @errores += '- El punto de venta no existe o no esta activo.' + CHAR(13);
            IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE idPuntoVenta = @idPuntoVenta AND nroTicket = @nroTicket)
                SET @errores += '- Ya existe un ticket con ese numero en este punto de venta.' + CHAR(13);
            IF NOT EXISTS (SELECT 1 FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago)
                SET @errores += '- La forma de pago indicada no existe.' + CHAR(13);
        END
    END
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    -- ---- Transaccion ----
    BEGIN TRANSACTION;
    BEGIN TRY
 
        -- Crear ticket nuevo si no se proporcionó uno
        IF @idTicket IS NULL
        BEGIN
            INSERT INTO ventas.Ticket
                (idPuntoVenta, nroTicket, tipoComprobante, idFormaPago,
                 fechaEmision, total, moneda, tipoCambio, estado)
            VALUES
                (@idPuntoVenta, @nroTicket, 'Ticket', @idFormaPago,
                 CAST(GETDATE() AS DATE), 0, 'ARS', 1, 'Emitido');
 
            SET @idTicket = SCOPE_IDENTITY();
        END
 
        -- Insertar ItemTicket
        INSERT INTO ventas.ItemTicket (idTicket, cantidad, precioUnitario, subtotal)
        VALUES (@idTicket, @cantidadPersonas, @montoUnitario, @montoTotal);
 
        SET @idItem = SCOPE_IDENTITY();
 
        -- Registrar la contratacion de actividad
        INSERT INTO atracciones.ContratacionActividad
            (idItem, idTour, idVisitante, cantidadPersonas, monto, estado)
        VALUES
            (@idItem, @idTour, @idVisitante, @cantidadPersonas, @montoTotal, 'Confirmada');
 
        -- Decrementar cupo disponible del tour
        UPDATE atracciones.Tour
        SET cupoDisponible = cupoDisponible - @cantidadPersonas
        WHERE idTour = @idTour;
 
        -- Actualizar total del ticket
        UPDATE ventas.Ticket
        SET total = total + @montoTotal
        WHERE idTicket = @idTicket;
 
        COMMIT TRANSACTION;
        SELECT @idTicket AS idTicket, SCOPE_IDENTITY() AS idContratacion, @montoTotal AS montoTotal;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO
 
 
-- ============================================================
-- SP: sp_AsignarGuiaATour
-- Descripcion: Asigna un guia autorizado a un tour.
--   Valida que el guia exista, este activo, que el tour
--   este en estado Programado y que el guia no este ya
--   asignado al mismo tour.
--
-- Parametros:
--   @idTour  : tour al que se asigna el guia
--   @idGuia  : guia a asignar
--   @rol     : rol del guia en el tour (default 'Principal')
-- ============================================================
 
CREATE PROCEDURE sp_AsignarGuiaATour
    @idTour INT,
    @idGuia INT,
    @rol    VARCHAR(100) = 'Principal'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
 
    IF NOT EXISTS (SELECT 1 FROM atracciones.Tour WHERE idTour = @idTour AND estado = 'Programado')
        SET @errores += '- El tour no existe o no esta en estado Programado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE idGuia = @idGuia AND activo = 1)
        SET @errores += '- El guia no existe o no esta activo.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@rol)), '') IS NULL
        SET @errores += '- El rol es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM atracciones.TourGuia WHERE idTour = @idTour AND idGuia = @idGuia)
        SET @errores += '- El guia ya esta asignado a este tour.' + CHAR(13);
 
    -- Verificar que el guia tenga habilitacion vigente
    IF NOT EXISTS (
        SELECT 1 FROM atracciones.HabilitacionGuia
        WHERE idGuia = @idGuia
          AND fechaVigencia >= CAST(GETDATE() AS DATE)
    )
        SET @errores += '- El guia no posee habilitacion vigente.' + CHAR(13);
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO atracciones.TourGuia (idTour, idGuia, rol)
        VALUES (@idTour, @idGuia, @rol);
 
        COMMIT TRANSACTION;
        SELECT SCOPE_IDENTITY() AS idTourGuia;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO
 
 
-- ============================================================
-- SP: sp_RegistrarPagoCanonYActualizarEstado
-- Descripcion: Registra un pago de canon para una concesion
--   y actualiza automaticamente el estado de la concesion:
--   - Si la fecha de fin ya paso y no es 'Rescindida' -> 'Vencida'
--   - Si estaba 'Vencida' y se registra un pago y aun esta
--     dentro del plazo contractual -> vuelve a 'Vigente'
--   Aplica transaccion para garantizar integridad.
--
-- Parametros:
--   @idConcesion : concesion que paga
--   @idFormaPago : forma de pago utilizada
--   @fechaPago   : fecha del pago
--   @monto       : monto abonado
--   @comprobante : numero o referencia del comprobante (opcional)
--   @periodo     : periodo que se cancela (formato YYYY-MM)
-- ============================================================
 
CREATE PROCEDURE sp_RegistrarPagoCanonYActualizarEstado
    @idConcesion INT,
    @idFormaPago INT,
    @fechaPago   DATE,
    @monto       DECIMAL(12,2),
    @comprobante VARCHAR(200) = NULL,
    @periodo     VARCHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores    VARCHAR(MAX) = '';
    DECLARE @fechaFin   DATE;
    DECLARE @estadoAct  VARCHAR(50);
    DECLARE @idPago     INT;
 
    -- Obtener datos de la concesion
    SELECT @fechaFin  = fechaFin,
           @estadoAct = estado
    FROM concesiones.Concesion
    WHERE idConcesion = @idConcesion;
 
    IF @fechaFin IS NULL
        SET @errores += '- La concesion indicada no existe.' + CHAR(13);
    IF @estadoAct = 'Rescindida'
        SET @errores += '- No se puede registrar un pago en una concesion rescindida.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago)
        SET @errores += '- La forma de pago indicada no existe.' + CHAR(13);
    IF @monto <= 0
        SET @errores += '- El monto del pago debe ser mayor a cero.' + CHAR(13);
    IF @fechaPago > CAST(GETDATE() AS DATE)
        SET @errores += '- La fecha de pago no puede ser futura.' + CHAR(13);
    IF @periodo NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
        SET @errores += '- El periodo debe tener formato YYYY-MM (ejemplo: 2026-05).' + CHAR(13);
    IF EXISTS (SELECT 1 FROM concesiones.PagoCanon WHERE idConcesion = @idConcesion AND periodo = @periodo)
        SET @errores += '- Ya existe un pago registrado para esa concesion en el periodo ' + @periodo + '.' + CHAR(13);
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    BEGIN TRANSACTION;
    BEGIN TRY
 
        -- Registrar el pago
        INSERT INTO concesiones.PagoCanon
            (idConcesion, idFormaPago, fechaPago, monto, comprobante, periodo)
        VALUES
            (@idConcesion, @idFormaPago, @fechaPago, @monto, @comprobante, @periodo);
 
        SET @idPago = SCOPE_IDENTITY();
 
        -- Actualizar estado de la concesion segun reglas de negocio
        DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
 
        IF @fechaFin < @hoy AND @estadoAct <> 'Rescindida'
        BEGIN
            -- La concesion ya vencio contractualmente
            UPDATE concesiones.Concesion SET estado = 'Vencida' WHERE idConcesion = @idConcesion;
        END
        ELSE IF @estadoAct = 'Vencida' AND @fechaFin >= @hoy
        BEGIN
            -- Estaba marcada como vencida pero aun esta dentro del plazo; el pago la reactiva
            UPDATE concesiones.Concesion SET estado = 'Vigente' WHERE idConcesion = @idConcesion;
        END
 
        COMMIT TRANSACTION;
        SELECT @idPago AS idPago;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO
 
 
-- ============================================================
-- SP: sp_ImportarDatosExternos
-- Descripcion: SP de soporte para importaciones masivas.
--   Abre un registro en ImportacionLog, ejecuta la logica
--   de upsert (a implementar por cada dataset), y cierra
--   el log con los resultados.
--   Este SP gestiona el ciclo de vida del log; los SPs
--   especificos de cada dataset lo invocan y reportan
--   sus contadores al finalizar.
--
-- Parametros:
--   @idParque            : parque al que pertenecen los datos (NULL si es global)
--   @fuente              : nombre o URL del archivo/fuente
--   @formato             : 'CSV', 'XML', 'JSON', etc.
--   @registrosProcesados : total de filas procesadas
--   @registrosOk         : filas importadas correctamente
--   @registrosError      : filas con error
--   @estadoFinal         : 'Completado', 'CompletadoConErrores' o 'Fallido'
-- ============================================================
 
CREATE PROCEDURE sp_ImportarDatosExternos
    @idParque            INT          = NULL,
    @fuente              VARCHAR(300),
    @formato             VARCHAR(50),
    @registrosProcesados INT,
    @registrosOk         INT,
    @registrosError      INT,
    @estadoFinal         VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores       VARCHAR(MAX) = '';
    DECLARE @idImportacion INT;
 
    -- Validaciones
    IF NULLIF(LTRIM(RTRIM(@fuente)), '')  IS NULL SET @errores += '- La fuente es obligatoria.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@formato)), '') IS NULL SET @errores += '- El formato es obligatorio.' + CHAR(13);
    IF @idParque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque)
        SET @errores += '- El parque indicado no existe.' + CHAR(13);
    IF @estadoFinal NOT IN ('Completado','CompletadoConErrores','Fallido')
        SET @errores += '- Estado final invalido. Valores: Completado, CompletadoConErrores, Fallido.' + CHAR(13);
    IF @registrosProcesados < 0 SET @errores += '- Los registros procesados no pueden ser negativos.' + CHAR(13);
    IF @registrosOk         < 0 SET @errores += '- Los registros ok no pueden ser negativos.' + CHAR(13);
    IF @registrosError      < 0 SET @errores += '- Los registros con error no pueden ser negativos.' + CHAR(13);
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    BEGIN TRANSACTION;
    BEGIN TRY
 
        -- Abrir log en estado EnProceso
        INSERT INTO importacion.ImportacionLog
            (idParque, fuente, formato, fechaEjecucion, registrosProcesados, registrosOk, registrosError, estado)
        VALUES
            (@idParque, @fuente, @formato, GETDATE(), 0, 0, 0, 'EnProceso');
 
        SET @idImportacion = SCOPE_IDENTITY();
 
        -- Cerrar log con resultados finales
        UPDATE importacion.ImportacionLog
        SET registrosProcesados = @registrosProcesados,
            registrosOk         = @registrosOk,
            registrosError      = @registrosError,
            estado              = @estadoFinal
        WHERE idImportacion = @idImportacion;
 
        COMMIT TRANSACTION;
        SELECT @idImportacion AS idImportacion;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO
 
 
-- ============================================================
-- SP: sp_AnularTicket
-- Descripcion: Anula un ticket y todas sus entradas/
--   contrataciones asociadas, de forma atomica.
--   No permite anular tickets ya anulados.
--
-- Parametros:
--   @idTicket : ticket a anular
-- ============================================================
 
CREATE PROCEDURE sp_AnularTicket
    @idTicket INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
    DECLARE @estado  VARCHAR(50);
 
    SELECT @estado = estado FROM ventas.Ticket WHERE idTicket = @idTicket;
 
    IF @estado IS NULL
        SET @errores += '- No existe un ticket con el ID indicado.' + CHAR(13);
    IF @estado = 'Anulado'
        SET @errores += '- El ticket ya se encuentra anulado.' + CHAR(13);
 
    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END
 
    BEGIN TRANSACTION;
    BEGIN TRY
 
        -- Anular entradas asociadas a los items del ticket
        UPDATE ventas.Entrada
        SET estado = 'Anulada'
        WHERE idItem IN (SELECT idItem FROM ventas.ItemTicket WHERE idTicket = @idTicket);
 
        -- Cancelar contrataciones de actividad asociadas a los items del ticket
        UPDATE atracciones.ContratacionActividad
        SET estado = 'Cancelada'
        WHERE idItem IN (SELECT idItem FROM ventas.ItemTicket WHERE idTicket = @idTicket);
 
        -- Restaurar cupo de los tours afectados
        UPDATE atracciones.Tour
        SET cupoDisponible = cupoDisponible + ca.cantidadPersonas
        FROM atracciones.Tour t
        JOIN atracciones.ContratacionActividad ca ON ca.idTour = t.idTour
        JOIN ventas.ItemTicket it ON it.idItem = ca.idItem
        WHERE it.idTicket = @idTicket
          AND ca.estado   = 'Cancelada';
 
        -- Anular el ticket
        UPDATE ventas.Ticket SET estado = 'Anulado' WHERE idTicket = @idTicket;
 
        COMMIT TRANSACTION;
        SELECT @idTicket AS idTicketAnulado;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO