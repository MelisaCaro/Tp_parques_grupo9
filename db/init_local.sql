
/*
============================================================
  Universidad: Universidad nacional de la matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri villalba Santino; Llanos Franco; Vazquez Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Creacion de la base de datos ParquesNacionales
               y configuracion inicial.
============================================================
*/
 
USE master;
GO
 
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END
GO

 
CREATE DATABASE ParquesNacionalesDB;
GO
 
/*
============================================================
  Fecha:      12/6/2026
  Descripcion: Creación de esquemas, tablas, PKs, FKs y
            restricciones del sistema de Parques Nacionales.
    - maestros:     Tablas de referencia y configuracion
    - parques:      Gestion de parques y personal
    - ventas:       Tickets, entradas y pagos
    - atracciones:  Atracciones, tours y guias
    - concesiones:  Concesionarios, concesiones y canon
    - importacion:  Log de importaciones y clima
============================================================
*/

USE ParquesNacionalesDB;
GO

-- ESQUEMAS
CREATE SCHEMA maestros;
GO
CREATE SCHEMA parques;
GO
CREATE SCHEMA ventas;
GO
CREATE SCHEMA atracciones;
GO
CREATE SCHEMA concesiones;
GO
CREATE SCHEMA importacion;
GO


/*ESQUEMA: maestros
TipoParque, TipoVisitante, FormaPago*/


CREATE TABLE maestros.TipoParque (
    idTipoParque  INT           IDENTITY(1,1) NOT NULL,
    nombre        VARCHAR(100)  NOT NULL,
    descripcion   VARCHAR(500)  NULL,
    CONSTRAINT PK_TipoParque        PRIMARY KEY (idTipoParque),
    CONSTRAINT UQ_TipoParque_nombre UNIQUE (nombre)
);


CREATE TABLE maestros.TipoVisitante (
    idTipoVisitante  INT           IDENTITY(1,1) NOT NULL,
    nombre           VARCHAR(100)  NOT NULL,
    descuentoPct     DECIMAL(5,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_TipoVisitante        PRIMARY KEY (idTipoVisitante),
    CONSTRAINT UQ_TipoVisitante_nombre UNIQUE (nombre),
    CONSTRAINT CHK_TipoVisitante_descuento CHECK (descuentoPct BETWEEN 0 AND 100)
);


CREATE TABLE maestros.FormaPago (
    idFormaPago  INT          IDENTITY(1,1) NOT NULL,
    descripcion  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_FormaPago             PRIMARY KEY (idFormaPago),
    CONSTRAINT UQ_FormaPago_descripcion UNIQUE (descripcion)
);

/*
-- ESQUEMA: parques
-- Parque, Guardaparque, AsignacionParque, PuntoVenta*/

CREATE TABLE parques.Parque (
    idParque      INT            IDENTITY(1,1) NOT NULL,
    idTipoParque  INT            NOT NULL,
    nombre        VARCHAR(200)   NOT NULL,
    ubicacion     VARCHAR(300)   NOT NULL,
    superficieHa  DECIMAL(12,2)  NULL,
    descripcion   VARCHAR(1000)  NULL,
    activo        BIT            NOT NULL DEFAULT 1,
    CONSTRAINT PK_Parque PRIMARY KEY (idParque),
    CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (idTipoParque)
        REFERENCES maestros.TipoParque (idTipoParque),
    CONSTRAINT CHK_Parque_superficie CHECK (superficieHa IS NULL OR superficieHa > 0)
);

CREATE TABLE parques.Guardaparque (
    idGuardaparque  INT          IDENTITY(1,1) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    dni             VARCHAR(20)  NOT NULL,
    legajo          VARCHAR(50)  NOT NULL,
    email           VARCHAR(150) NULL,
    telefono        VARCHAR(50)  NULL,
    CONSTRAINT PK_Guardaparque        PRIMARY KEY (idGuardaparque),
    CONSTRAINT UQ_Guardaparque_dni    UNIQUE (dni),
    CONSTRAINT UQ_Guardaparque_legajo UNIQUE (legajo)
);


CREATE TABLE parques.AsignacionParque (
    idAsignacion    INT          IDENTITY(1,1) NOT NULL,
    idGuardaparque  INT          NOT NULL,
    idParque        INT          NOT NULL,
    fechaIngreso    DATE         NOT NULL,
    fechaEgreso     DATE         NULL,
    motivoEgreso    VARCHAR(500) NULL,
    CONSTRAINT PK_AsignacionParque PRIMARY KEY (idAsignacion),
    CONSTRAINT FK_AsignacionParque_Guardaparque FOREIGN KEY (idGuardaparque)
        REFERENCES parques.Guardaparque (idGuardaparque),
    CONSTRAINT FK_AsignacionParque_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_AsignacionParque_fechas
        CHECK (fechaEgreso IS NULL OR fechaEgreso >= fechaIngreso)
);


CREATE TABLE parques.PuntoVenta (
    idPuntoVenta     INT          IDENTITY(1,1) NOT NULL,
    idParque         INT          NOT NULL,
    nombre           VARCHAR(150) NOT NULL,
    ubicacionFisica  VARCHAR(300) NULL,
    activo           BIT          NOT NULL DEFAULT 1,
    CONSTRAINT PK_PuntoVenta PRIMARY KEY (idPuntoVenta),
    CONSTRAINT FK_PuntoVenta_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque)
);



/*ESQUEMA: ventas
Visitante, PrecioEntrada, Ticket, ItemTicket, Entrada*/

CREATE TABLE ventas.Visitante (
    idVisitante       INT          IDENTITY(1,1) NOT NULL,
    idTipoVisitante   INT          NOT NULL,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    dniPasaporte      VARCHAR(30)  NOT NULL,
    email             VARCHAR(150) NULL,
    nacionalidad      VARCHAR(100) NULL,
    esAgenciaTurismo  BIT          NOT NULL DEFAULT 0,
    CONSTRAINT PK_Visitante     PRIMARY KEY (idVisitante),
    CONSTRAINT UQ_Visitante_dni UNIQUE (dniPasaporte),
    CONSTRAINT FK_Visitante_TipoVisitante FOREIGN KEY (idTipoVisitante)
        REFERENCES maestros.TipoVisitante (idTipoVisitante)
);


CREATE TABLE ventas.PrecioEntrada (
    idPrecioEntrada  INT            IDENTITY(1,1) NOT NULL,
    idParque         INT            NOT NULL,
    idTipoVisitante  INT            NOT NULL,
    monto            DECIMAL(12,2)  NOT NULL,
    vigenciaDesde    DATE           NOT NULL,
    vigenciaHasta    DATE           NULL,
    moneda           VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    CONSTRAINT PK_PrecioEntrada PRIMARY KEY (idPrecioEntrada),
    CONSTRAINT FK_PrecioEntrada_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT FK_PrecioEntrada_TipoVisitante FOREIGN KEY (idTipoVisitante)
        REFERENCES maestros.TipoVisitante (idTipoVisitante),
    CONSTRAINT CHK_PrecioEntrada_monto  CHECK (monto >= 0),
    CONSTRAINT CHK_PrecioEntrada_fechas
        CHECK (vigenciaHasta IS NULL OR vigenciaHasta >= vigenciaDesde)
);


CREATE TABLE ventas.Ticket (
    idTicket               INT            IDENTITY(1,1) NOT NULL,
    idPuntoVenta           INT            NOT NULL,
    nroTicket              INT            NOT NULL,
    tipoComprobante        VARCHAR(50)    NOT NULL DEFAULT 'Ticket',
    compradorNombreRazon   VARCHAR(200)   NULL,
    compradorCultDni       VARCHAR(30)    NULL,
    idFormaPago            INT            NOT NULL,
    fechaEmision           DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    total                  DECIMAL(12,2)  NOT NULL DEFAULT 0,
    moneda                 VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    tipoCambio             DECIMAL(10,4)  NOT NULL DEFAULT 1,
    estado                 VARCHAR(50)    NOT NULL DEFAULT 'Emitido',
    CONSTRAINT PK_Ticket       PRIMARY KEY (idTicket),
    CONSTRAINT UQ_Ticket_pvNro UNIQUE (idPuntoVenta, nroTicket),
    CONSTRAINT FK_Ticket_PuntoVenta FOREIGN KEY (idPuntoVenta)
        REFERENCES parques.PuntoVenta (idPuntoVenta),
    CONSTRAINT FK_Ticket_FormaPago FOREIGN KEY (idFormaPago)
        REFERENCES maestros.FormaPago (idFormaPago),
    CONSTRAINT CHK_Ticket_total  CHECK (total >= 0),
    CONSTRAINT CHK_Ticket_cambio CHECK (tipoCambio > 0),
    CONSTRAINT CHK_Ticket_estado CHECK (estado IN ('Emitido','Anulado'))
);

CREATE TABLE ventas.ItemTicket (
    idItem          INT            IDENTITY(1,1) NOT NULL,
    idTicket        INT            NOT NULL,
    cantidad        INT            NOT NULL DEFAULT 1,
    precioUnitario  DECIMAL(12,2)  NOT NULL,
    subtotal        DECIMAL(12,2)  NOT NULL,
    CONSTRAINT PK_ItemTicket PRIMARY KEY (idItem),
    CONSTRAINT FK_ItemTicket_Ticket FOREIGN KEY (idTicket)
        REFERENCES ventas.Ticket (idTicket),
    CONSTRAINT CHK_ItemTicket_cantidad CHECK (cantidad > 0),
    CONSTRAINT CHK_ItemTicket_precio   CHECK (precioUnitario >= 0),
    CONSTRAINT CHK_ItemTicket_subtotal CHECK (subtotal >= 0)
);

CREATE TABLE ventas.Entrada (
    idEntrada    INT            IDENTITY(1,1) NOT NULL,
    idItem       INT            NOT NULL,
    idVisitante  INT            NOT NULL,
    idParque     INT            NOT NULL,
    idPrecio     INT            NOT NULL,
    fechaAcceso  DATE           NOT NULL,
    montoPagado  DECIMAL(12,2)  NOT NULL,
    estado       VARCHAR(50)    NOT NULL DEFAULT 'Activa',
    CONSTRAINT PK_Entrada PRIMARY KEY (idEntrada),
    CONSTRAINT FK_Entrada_ItemTicket FOREIGN KEY (idItem)
        REFERENCES ventas.ItemTicket (idItem),
    CONSTRAINT FK_Entrada_Visitante FOREIGN KEY (idVisitante)
        REFERENCES ventas.Visitante (idVisitante),
    CONSTRAINT FK_Entrada_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT FK_Entrada_PrecioEntrada FOREIGN KEY (idPrecio)
        REFERENCES ventas.PrecioEntrada (idPrecioEntrada),
    CONSTRAINT CHK_Entrada_monto  CHECK (montoPagado >= 0),
    CONSTRAINT CHK_Entrada_estado CHECK (estado IN ('Activa','Anulada'))
);

-- ESQUEMA: atracciones
-- Atraccion, PrecioAtraccion, GuiaAutorizado, HabilitacionGuia,
-- Tour, TourGuia, ContratacionActividad
CREATE TABLE atracciones.Atraccion (
    idAtraccion  INT           IDENTITY(1,1) NOT NULL,
    idParque     INT           NOT NULL,
    nombre       VARCHAR(200)  NOT NULL,
    tipo         VARCHAR(100)  NOT NULL,
    duracionMin  INT           NULL,
    cupoMaximo   INT           NULL,
    activa       BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_Atraccion PRIMARY KEY (idAtraccion),
    CONSTRAINT FK_Atraccion_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_Atraccion_duracion CHECK (duracionMin IS NULL OR duracionMin > 0),
    CONSTRAINT CHK_Atraccion_cupo    CHECK (cupoMaximo  IS NULL OR cupoMaximo  > 0)
);


CREATE TABLE atracciones.PrecioAtraccion (
    idPrecioAtraccion  INT            IDENTITY(1,1) NOT NULL,
    idAtraccion        INT            NOT NULL,
    monto              DECIMAL(12,2)  NOT NULL,
    vigenciaDesde      DATE           NOT NULL,
    vigenciaHasta      DATE           NULL,
    moneda             VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    CONSTRAINT PK_PrecioAtraccion PRIMARY KEY (idPrecioAtraccion),
    CONSTRAINT FK_PrecioAtraccion_Atraccion FOREIGN KEY (idAtraccion)
        REFERENCES atracciones.Atraccion (idAtraccion),
    CONSTRAINT CHK_PrecioAtraccion_monto  CHECK (monto >= 0),
    CONSTRAINT CHK_PrecioAtraccion_fechas
        CHECK (vigenciaHasta IS NULL OR vigenciaHasta >= vigenciaDesde)
);

CREATE TABLE atracciones.GuiaAutorizado (
    idGuia        INT          IDENTITY(1,1) NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    apellido      VARCHAR(100) NOT NULL,
    dni           VARCHAR(20)  NOT NULL,
    especialidad  VARCHAR(150) NULL,
    titulo        VARCHAR(150) NULL,
    activo        BIT          NOT NULL DEFAULT 1,
    CONSTRAINT PK_GuiaAutorizado     PRIMARY KEY (idGuia),
    CONSTRAINT UQ_GuiaAutorizado_dni UNIQUE (dni)
);

CREATE TABLE atracciones.HabilitacionGuia (
    idHabilitacion  INT          IDENTITY(1,1) NOT NULL,
    idGuia          INT          NOT NULL,
    descripcion     VARCHAR(300) NOT NULL,
    fechaVigencia   DATE         NOT NULL,
    CONSTRAINT PK_HabilitacionGuia PRIMARY KEY (idHabilitacion),
    CONSTRAINT FK_HabilitacionGuia_Guia FOREIGN KEY (idGuia)
        REFERENCES atracciones.GuiaAutorizado (idGuia)
);

CREATE TABLE atracciones.Tour (
    idTour           INT          IDENTITY(1,1) NOT NULL,
    idAtraccion      INT          NOT NULL,
    fechaHoraInicio  DATETIME     NOT NULL,
    cupoDisponible   INT          NOT NULL,
    estado           VARCHAR(50)  NOT NULL DEFAULT 'Programado',
    CONSTRAINT PK_Tour PRIMARY KEY (idTour),
    CONSTRAINT FK_Tour_Atraccion FOREIGN KEY (idAtraccion)
        REFERENCES atracciones.Atraccion (idAtraccion),
    CONSTRAINT CHK_Tour_cupo   CHECK (cupoDisponible >= 0),
    CONSTRAINT CHK_Tour_estado CHECK (estado IN ('Programado','EnCurso','Finalizado','Cancelado'))
);

CREATE TABLE atracciones.TourGuia (
    idTourGuia  INT          IDENTITY(1,1) NOT NULL,
    idTour      INT          NOT NULL,
    idGuia      INT          NOT NULL,
    rol         VARCHAR(100) NOT NULL DEFAULT 'Principal',
    CONSTRAINT PK_TourGuia          PRIMARY KEY (idTourGuia),
    CONSTRAINT UQ_TourGuia_tourGuia UNIQUE (idTour, idGuia),
    CONSTRAINT FK_TourGuia_Tour FOREIGN KEY (idTour)
        REFERENCES atracciones.Tour (idTour),
    CONSTRAINT FK_TourGuia_Guia FOREIGN KEY (idGuia)
        REFERENCES atracciones.GuiaAutorizado (idGuia)
);

CREATE TABLE atracciones.ContratacionActividad (
    idContratacion   INT            IDENTITY(1,1) NOT NULL,
    idItem           INT            NOT NULL,
    idTour           INT            NOT NULL,
    idVisitante      INT            NOT NULL,
    cantidadPersonas INT            NOT NULL DEFAULT 1,
    monto            DECIMAL(12,2)  NOT NULL,
    estado           VARCHAR(50)    NOT NULL DEFAULT 'Confirmada',
    CONSTRAINT PK_ContratacionActividad PRIMARY KEY (idContratacion),
    CONSTRAINT FK_ContratacionActividad_Item FOREIGN KEY (idItem)
        REFERENCES ventas.ItemTicket (idItem),
    CONSTRAINT FK_ContratacionActividad_Tour FOREIGN KEY (idTour)
        REFERENCES atracciones.Tour (idTour),
    CONSTRAINT FK_ContratacionActividad_Visitante FOREIGN KEY (idVisitante)
        REFERENCES ventas.Visitante (idVisitante),
    CONSTRAINT CHK_ContratacionActividad_personas CHECK (cantidadPersonas > 0),
    CONSTRAINT CHK_ContratacionActividad_monto    CHECK (monto >= 0),
    CONSTRAINT CHK_ContratacionActividad_estado
        CHECK (estado IN ('Confirmada','Cancelada'))
);

-- ESQUEMA: concesiones
-- Concesionario, Concesion, PagoCanon
CREATE TABLE concesiones.Concesionario (
    idConcesionario  INT          IDENTITY(1,1) NOT NULL,
    razonSocial      VARCHAR(200) NOT NULL,
    cuit             VARCHAR(13)  NOT NULL,
    email            VARCHAR(150) NULL,
    telefono         VARCHAR(50)  NULL,
    contacto         VARCHAR(150) NULL,
    CONSTRAINT PK_Concesionario      PRIMARY KEY (idConcesionario),
    CONSTRAINT UQ_Concesionario_cuit UNIQUE (cuit)
);

CREATE TABLE concesiones.Concesion (
    idConcesion          INT            IDENTITY(1,1) NOT NULL,
    idConcesionario      INT            NOT NULL,
    idParque             INT            NOT NULL,
    tipoActividad        VARCHAR(200)   NOT NULL,
    fechaInicio          DATE           NOT NULL,
    fechaFin             DATE           NOT NULL,
    diaVencimientoPago   INT            NOT NULL DEFAULT 10,
    canonMensual         DECIMAL(12,2)  NOT NULL,
    moneda               VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    estado               VARCHAR(50)    NOT NULL DEFAULT 'Vigente',
    CONSTRAINT PK_Concesion PRIMARY KEY (idConcesion),
    CONSTRAINT FK_Concesion_Concesionario FOREIGN KEY (idConcesionario)
        REFERENCES concesiones.Concesionario (idConcesionario),
    CONSTRAINT FK_Concesion_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_Concesion_fechas CHECK (fechaFin > fechaInicio),
    CONSTRAINT CHK_Concesion_canon  CHECK (canonMensual > 0),
    CONSTRAINT CHK_Concesion_estado
        CHECK (estado IN ('Vigente','Vencida','Rescindida')),
    CONSTRAINT CHK_Concesion_diaVencimiento
        CHECK (diaVencimientoPago BETWEEN 1 AND 28)
);

CREATE TABLE concesiones.PagoCanon (
    idPago       INT            IDENTITY(1,1) NOT NULL,
    idConcesion  INT            NOT NULL,
    idFormaPago  INT            NOT NULL,
    fechaPago    DATE           NOT NULL,
    monto        DECIMAL(12,2)  NOT NULL,
    comprobante  VARCHAR(200)   NULL,
    periodo      VARCHAR(7)     NOT NULL,
    CONSTRAINT PK_PagoCanon PRIMARY KEY (idPago),
    CONSTRAINT FK_PagoCanon_Concesion FOREIGN KEY (idConcesion)
        REFERENCES concesiones.Concesion (idConcesion),
    CONSTRAINT FK_PagoCanon_FormaPago FOREIGN KEY (idFormaPago)
        REFERENCES maestros.FormaPago (idFormaPago),
    CONSTRAINT CHK_PagoCanon_monto CHECK (monto > 0)
);


-- ESQUEMA: importacion
-- ImportacionLog, CondicionClimatica

CREATE TABLE importacion.ImportacionLog (
    idImportacion        INT          IDENTITY(1,1) NOT NULL,
    idParque             INT          NULL,
    fuente               VARCHAR(300) NOT NULL,
    formato              VARCHAR(50)  NOT NULL,
    fechaEjecucion       DATETIME     NOT NULL DEFAULT GETDATE(),
    registrosProcesados  INT          NOT NULL DEFAULT 0,
    registrosOk          INT          NOT NULL DEFAULT 0,
    registrosError       INT          NOT NULL DEFAULT 0,
    estado               VARCHAR(50)  NOT NULL DEFAULT 'Pendiente',
    CONSTRAINT PK_ImportacionLog PRIMARY KEY (idImportacion),
    CONSTRAINT FK_ImportacionLog_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_ImportacionLog_estado
        CHECK (estado IN ('Pendiente','EnProceso','Completado','CompletadoConErrores','Fallido'))
);

CREATE TABLE importacion.CondicionClimatica (
    idCondicion      INT            IDENTITY(1,1) NOT NULL,
    idParque         INT            NOT NULL,
    fecha            DATE           NOT NULL,
    tempMax          DECIMAL(5,2)   NULL,
    tempMin          DECIMAL(5,2)   NULL,
    precipitacionMm  DECIMAL(7,2)   NULL,
    diaLluvioso      BIT            NOT NULL DEFAULT 0,
    fuenteApi        VARCHAR(200)   NULL,
    CONSTRAINT PK_CondicionClimatica PRIMARY KEY (idCondicion),
    CONSTRAINT FK_CondicionClimatica_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT UQ_CondicionClimatica_parqueFecha UNIQUE (idParque, fecha)
);

-- INDICES

CREATE INDEX IX_Entrada_fechaAcceso       ON ventas.Entrada (fechaAcceso);
CREATE INDEX IX_Entrada_idParque          ON ventas.Entrada (idParque);
CREATE INDEX IX_Ticket_fechaEmision       ON ventas.Ticket (fechaEmision);
CREATE INDEX IX_Concesion_estado          ON concesiones.Concesion (estado);
CREATE INDEX IX_PagoCanon_periodo         ON concesiones.PagoCanon (periodo);
CREATE INDEX IX_Tour_fechaHoraInicio      ON atracciones.Tour (fechaHoraInicio);
CREATE INDEX IX_AsignacionParque_idGuarda ON parques.AsignacionParque (idGuardaparque);


/*
============================================================
  Fecha:       12/06/2026
  Descripcion: Stored Procedures de ABM
               Cada SP acumula todos los errores de validacion
               en una variable y los reporta en un unico mensaje.
============================================================
*/

USE ParquesNacionalesDB;
GO

-- maestros.TipoParque

CREATE PROCEDURE sp_TipoParque_Insertar
    @nombre      VARCHAR(100),
    @descripcion VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del tipo de parque es obligatorio.' + CHAR(13);
    IF LEN(LTRIM(RTRIM(ISNULL(@nombre,'')))) > 100
        SET @errores += '- El nombre no puede superar los 100 caracteres.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.TipoParque WHERE nombre = @nombre)
        SET @errores += '- Ya existe un tipo de parque con ese nombre.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO maestros.TipoParque (nombre, descripcion)
    VALUES (@nombre, @descripcion);

    SELECT SCOPE_IDENTITY() AS idTipoParque;
END
GO

CREATE PROCEDURE sp_TipoParque_Actualizar
    @idTipoParque INT,
    @nombre       VARCHAR(100),
    @descripcion  VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.TipoParque WHERE idTipoParque = @idTipoParque)
        SET @errores += '- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.TipoParque WHERE nombre = @nombre AND idTipoParque <> @idTipoParque)
        SET @errores += '- Ya existe otro tipo de parque con ese nombre.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE maestros.TipoParque
    SET nombre = @nombre, descripcion = @descripcion
    WHERE idTipoParque = @idTipoParque;
END
GO

CREATE PROCEDURE sp_TipoParque_Eliminar
    @idTipoParque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.TipoParque WHERE idTipoParque = @idTipoParque)
        SET @errores += '- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE idTipoParque = @idTipoParque)
        SET @errores += '- No se puede eliminar: existen parques asociados a este tipo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM maestros.TipoParque WHERE idTipoParque = @idTipoParque;
END
GO
-- maestros.TipoVisitante
CREATE PROCEDURE sp_TipoVisitante_Insertar
    @nombre       VARCHAR(100),
    @descuentoPct DECIMAL(5,2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF @descuentoPct < 0 OR @descuentoPct > 100
        SET @errores += '- El descuento debe estar entre 0 y 100.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE nombre = @nombre)
        SET @errores += '- Ya existe un tipo de visitante con ese nombre.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO maestros.TipoVisitante (nombre, descuentoPct)
    VALUES (@nombre, @descuentoPct);

    SELECT SCOPE_IDENTITY() AS idTipoVisitante;
END
GO

CREATE PROCEDURE sp_TipoVisitante_Actualizar
    @idTipoVisitante INT,
    @nombre          VARCHAR(100),
    @descuentoPct    DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF @descuentoPct < 0 OR @descuentoPct > 100
        SET @errores += '- El descuento debe estar entre 0 y 100.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE nombre = @nombre AND idTipoVisitante <> @idTipoVisitante)
        SET @errores += '- Ya existe otro tipo de visitante con ese nombre.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE maestros.TipoVisitante
    SET nombre = @nombre, descuentoPct = @descuentoPct
    WHERE idTipoVisitante = @idTipoVisitante;
END
GO

CREATE PROCEDURE sp_TipoVisitante_Eliminar
    @idTipoVisitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Visitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- No se puede eliminar: existen visitantes asociados a este tipo.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- No se puede eliminar: existen precios de entrada asociados a este tipo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante;
END
GO

-- maestros.FormaPago

CREATE PROCEDURE sp_FormaPago_Insertar
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL
        SET @errores += '- La descripcion es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.FormaPago WHERE descripcion = @descripcion)
        SET @errores += '- Ya existe una forma de pago con esa descripcion.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO maestros.FormaPago (descripcion) VALUES (@descripcion);
    SELECT SCOPE_IDENTITY() AS idFormaPago;
END
GO

CREATE PROCEDURE sp_FormaPago_Actualizar
    @idFormaPago INT,
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago)
        SET @errores += '- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL
        SET @errores += '- La descripcion es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM maestros.FormaPago WHERE descripcion = @descripcion AND idFormaPago <> @idFormaPago)
        SET @errores += '- Ya existe otra forma de pago con esa descripcion.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE maestros.FormaPago SET descripcion = @descripcion WHERE idFormaPago = @idFormaPago;
END
GO

CREATE PROCEDURE sp_FormaPago_Eliminar
    @idFormaPago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago)
        SET @errores += '- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE idFormaPago = @idFormaPago)
        SET @errores += '- No se puede eliminar: existen tickets que usan esta forma de pago.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM maestros.FormaPago WHERE idFormaPago = @idFormaPago;
END
GO

-- parques.Parque

CREATE PROCEDURE sp_Parque_Insertar
    @idTipoParque INT,
    @nombre       VARCHAR(200),
    @ubicacion    VARCHAR(300),
    @superficieHa DECIMAL(12,2) = NULL,
    @descripcion  VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del parque es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@ubicacion)), '') IS NULL
        SET @errores += '- La ubicacion del parque es obligatoria.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.TipoParque WHERE idTipoParque = @idTipoParque)
        SET @errores += '- El tipo de parque indicado no existe.' + CHAR(13);
    IF @superficieHa IS NOT NULL AND @superficieHa <= 0
        SET @errores += '- La superficie debe ser mayor a cero.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.Parque (idTipoParque, nombre, ubicacion, superficieHa, descripcion, activo)
    VALUES (@idTipoParque, @nombre, @ubicacion, @superficieHa, @descripcion, 1);

    SELECT SCOPE_IDENTITY() AS idParque;
END
GO

CREATE PROCEDURE sp_Parque_Actualizar
    @idParque     INT,
    @idTipoParque INT,
    @nombre       VARCHAR(200),
    @ubicacion    VARCHAR(300),
    @superficieHa DECIMAL(12,2) = NULL,
    @descripcion  VARCHAR(1000) = NULL,
    @activo       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque)
        SET @errores += '- No existe un parque con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.TipoParque WHERE idTipoParque = @idTipoParque)
        SET @errores += '- El tipo de parque indicado no existe.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del parque es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@ubicacion)), '') IS NULL
        SET @errores += '- La ubicacion es obligatoria.' + CHAR(13);
    IF @superficieHa IS NOT NULL AND @superficieHa <= 0
        SET @errores += '- La superficie debe ser mayor a cero.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque
    SET idTipoParque = @idTipoParque, nombre = @nombre, ubicacion = @ubicacion,
        superficieHa = @superficieHa, descripcion = @descripcion, activo = @activo
    WHERE idParque = @idParque;
END
GO

CREATE PROCEDURE sp_Parque_Eliminar
    @idParque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque)
        SET @errores += '- No existe un parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Entrada WHERE idParque = @idParque)
        SET @errores += '- No se puede eliminar: el parque tiene entradas registradas. Use la baja logica (activo = 0).' + CHAR(13);
    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE idParque = @idParque)
        SET @errores += '- No se puede eliminar: el parque tiene concesiones asociadas.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque SET activo = 0 WHERE idParque = @idParque;
END
GO

-- parques.Guardaparque

CREATE PROCEDURE sp_Guardaparque_Insertar
    @nombre   VARCHAR(100),
    @apellido VARCHAR(100),
    @dni      VARCHAR(20),
    @legajo   VARCHAR(50),
    @email    VARCHAR(150) = NULL,
    @telefono VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '')   IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@dni)), '')      IS NULL SET @errores += '- El DNI es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@legajo)), '')   IS NULL SET @errores += '- El legajo es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Guardaparque WHERE dni    = @dni)
        SET @errores += '- Ya existe un guardaparque con ese DNI.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Guardaparque WHERE legajo = @legajo)
        SET @errores += '- Ya existe un guardaparque con ese legajo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.Guardaparque (nombre, apellido, dni, legajo, email, telefono)
    VALUES (@nombre, @apellido, @dni, @legajo, @email, @telefono);

    SELECT SCOPE_IDENTITY() AS idGuardaparque;
END
GO

CREATE PROCEDURE sp_Guardaparque_Actualizar
    @idGuardaparque INT,
    @nombre         VARCHAR(100),
    @apellido       VARCHAR(100),
    @dni            VARCHAR(20),
    @legajo         VARCHAR(50),
    @email          VARCHAR(150) = NULL,
    @telefono       VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Guardaparque WHERE idGuardaparque = @idGuardaparque)
        SET @errores += '- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '')   IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@dni)), '')      IS NULL SET @errores += '- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Guardaparque WHERE dni    = @dni    AND idGuardaparque <> @idGuardaparque)
        SET @errores += '- Otro guardaparque ya tiene ese DNI.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Guardaparque WHERE legajo = @legajo AND idGuardaparque <> @idGuardaparque)
        SET @errores += '- Otro guardaparque ya tiene ese legajo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Guardaparque
    SET nombre = @nombre, apellido = @apellido, dni = @dni,
        legajo = @legajo, email = @email, telefono = @telefono
    WHERE idGuardaparque = @idGuardaparque;
END
GO

CREATE PROCEDURE sp_Guardaparque_Eliminar
    @idGuardaparque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Guardaparque WHERE idGuardaparque = @idGuardaparque)
        SET @errores += '- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.AsignacionParque WHERE idGuardaparque = @idGuardaparque AND fechaEgreso IS NULL)
        SET @errores += '- El guardaparque tiene una asignacion activa. Debe registrar su egreso antes de eliminarlo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM parques.Guardaparque WHERE idGuardaparque = @idGuardaparque;
END
GO

-- parques.AsignacionParque

CREATE PROCEDURE sp_AsignacionParque_Insertar
    @idGuardaparque INT,
    @idParque       INT,
    @fechaIngreso   DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Guardaparque WHERE idGuardaparque = @idGuardaparque)
        SET @errores += '- El guardaparque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
        SET @errores += '- El parque indicado no existe o no esta activo.' + CHAR(13);
    IF @fechaIngreso > CAST(GETDATE() AS DATE)
        SET @errores += '- La fecha de ingreso no puede ser futura.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.AsignacionParque WHERE idGuardaparque = @idGuardaparque AND fechaEgreso IS NULL)
        SET @errores += '- El guardaparque ya tiene una asignacion activa. Debe registrar su egreso antes de crear una nueva.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.AsignacionParque (idGuardaparque, idParque, fechaIngreso)
    VALUES (@idGuardaparque, @idParque, @fechaIngreso);

    SELECT SCOPE_IDENTITY() AS idAsignacion;
END
GO

CREATE PROCEDURE sp_AsignacionParque_Cerrar
    @idAsignacion INT,
    @fechaEgreso  DATE,
    @motivoEgreso VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
    DECLARE @fechaIngreso DATE;

    SELECT @fechaIngreso = fechaIngreso
    FROM parques.AsignacionParque
    WHERE idAsignacion = @idAsignacion;

    IF @fechaIngreso IS NULL
        SET @errores += '- No existe una asignacion con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.AsignacionParque WHERE idAsignacion = @idAsignacion AND fechaEgreso IS NOT NULL)
        SET @errores += '- La asignacion ya fue cerrada.' + CHAR(13);
    IF @fechaIngreso IS NOT NULL AND @fechaEgreso < @fechaIngreso
        SET @errores += '- La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE parques.AsignacionParque
    SET fechaEgreso = @fechaEgreso, motivoEgreso = @motivoEgreso
    WHERE idAsignacion = @idAsignacion;
END
GO


/* VALIDACIONES HECHAS HASTA ACA (MIN 10)
  --TIPO PARQUE
	nombre obligatorio, nombre duplicado, no eliminar si tiene parques asociados
   -TIPO VISITANTE
	nombre obligatorio, descento entre 0 y 100, nombre duplicado, no eliminar si tiene visitas asociadas, no elim si precios de entradas asoc
FORMA DE PAGO
	descripcion obligatoria, descripcion duplicada,no elim si tiene tickets
GUARDAPARQUE
	nombre oblig, apellido oblig, dni oblig, dni dup, legajo dup, no eliminar si tiene asignacion activa
ASIGNACION DE PARQUE
	guardaparque existente, parques existentes y activos, no crear si tiene asignacion activa
/

--falta sp de puntoventa, visitante, precio entrada, atraccion, precioatraccion, guia autorizado, habilitacionguia, tour, concesionario, consecion, pagoCanon, importacion log, condicion climatica
*/

-- parques.PuntoVenta

CREATE  PROCEDURE sp_PuntoVenta_Insertar
    @idParque        INT,
    @nombre          VARCHAR(150),
    @ubicacionFisica VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
        SET @errores += '- El parque indicado no existe o no esta activo.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del punto de venta es obligatorio.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.PuntoVenta (idParque, nombre, ubicacionFisica, activo)
    VALUES (@idParque, @nombre, @ubicacionFisica, 1);

    SELECT SCOPE_IDENTITY() AS idPuntoVenta;
END
GO

CREATE  PROCEDURE sp_PuntoVenta_Actualizar
    @idPuntoVenta    INT,
    @nombre          VARCHAR(150),
    @ubicacionFisica VARCHAR(300) = NULL,
    @activo          BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.PuntoVenta WHERE idPuntoVenta = @idPuntoVenta)
        SET @errores += '- No existe un punto de venta con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE parques.PuntoVenta
    SET nombre = @nombre, ubicacionFisica = @ubicacionFisica, activo = @activo
    WHERE idPuntoVenta = @idPuntoVenta;
END
GO

-- ventas.Visitante

CREATE PROCEDURE sp_Visitante_Insertar
    @idTipoVisitante  INT,
    @nombre           VARCHAR(100),
    @apellido         VARCHAR(100),
    @dniPasaporte     VARCHAR(30),
    @email            VARCHAR(150) = NULL,
    @nacionalidad     VARCHAR(100) = NULL,
    @esAgenciaTurismo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '')      IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '')    IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@dniPasaporte)), '') IS NULL SET @errores += '- El DNI/Pasaporte es obligatorio.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- El tipo de visitante indicado no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Visitante WHERE dniPasaporte = @dniPasaporte)
        SET @errores += '- Ya existe un visitante con ese DNI/Pasaporte.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO ventas.Visitante (idTipoVisitante, nombre, apellido, dniPasaporte, email, nacionalidad, esAgenciaTurismo)
    VALUES (@idTipoVisitante, @nombre, @apellido, @dniPasaporte, @email, @nacionalidad, @esAgenciaTurismo);

    SELECT SCOPE_IDENTITY() AS idVisitante;
END
GO

CREATE  PROCEDURE sp_Visitante_Actualizar
    @idVisitante      INT,
    @idTipoVisitante  INT,
    @nombre           VARCHAR(100),
    @apellido         VARCHAR(100),
    @dniPasaporte     VARCHAR(30),
    @email            VARCHAR(150) = NULL,
    @nacionalidad     VARCHAR(100) = NULL,
    @esAgenciaTurismo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.Visitante WHERE idVisitante = @idVisitante)
        SET @errores += '- No existe un visitante con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- El tipo de visitante indicado no existe.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '')   IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Visitante WHERE dniPasaporte = @dniPasaporte AND idVisitante <> @idVisitante)
        SET @errores += '- Otro visitante ya tiene ese DNI/Pasaporte.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.Visitante
    SET idTipoVisitante = @idTipoVisitante, nombre = @nombre, apellido = @apellido,
        dniPasaporte = @dniPasaporte, email = @email, nacionalidad = @nacionalidad,
        esAgenciaTurismo = @esAgenciaTurismo
    WHERE idVisitante = @idVisitante;
END
GO

CREATE PROCEDURE sp_Visitante_Eliminar
    @idVisitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.Visitante WHERE idVisitante = @idVisitante)
        SET @errores += '- No existe un visitante con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Entrada WHERE idVisitante = @idVisitante)
        SET @errores += '- No se puede eliminar: el visitante tiene entradas registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM atracciones.ContratacionActividad WHERE idVisitante = @idVisitante)
        SET @errores += '- No se puede eliminar: el visitante tiene contrataciones de actividades registradas.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM ventas.Visitante WHERE idVisitante = @idVisitante;
END
GO

-- ventas.PrecioEntrada

CREATE PROCEDURE sp_PrecioEntrada_Insertar
    @idParque        INT,
    @idTipoVisitante INT,
    @monto           DECIMAL(12,2),
    @vigenciaDesde   DATE,
    @vigenciaHasta   DATE = NULL,
    @moneda          VARCHAR(10) = 'ARS'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
        SET @errores += '- El parque indicado no existe o no esta activo.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM maestros.TipoVisitante WHERE idTipoVisitante = @idTipoVisitante)
        SET @errores += '- El tipo de visitante indicado no existe.' + CHAR(13);
    IF @monto < 0
        SET @errores += '- El monto no puede ser negativo.' + CHAR(13);
    IF @vigenciaHasta IS NOT NULL AND @vigenciaHasta < @vigenciaDesde
        SET @errores += '- La fecha de fin de vigencia no puede ser anterior a la de inicio.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM ventas.PrecioEntrada
        WHERE idParque = @idParque AND idTipoVisitante = @idTipoVisitante
          AND vigenciaDesde <= ISNULL(@vigenciaHasta, '9999-12-31')
          AND ISNULL(vigenciaHasta, '9999-12-31') >= @vigenciaDesde
    )
        SET @errores += '- Ya existe un precio vigente para ese parque y tipo de visitante en ese periodo.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO ventas.PrecioEntrada (idParque, idTipoVisitante, monto, vigenciaDesde, vigenciaHasta, moneda)
    VALUES (@idParque, @idTipoVisitante, @monto, @vigenciaDesde, @vigenciaHasta, @moneda);

    SELECT SCOPE_IDENTITY() AS idPrecioEntrada;
END
GO

CREATE PROCEDURE sp_PrecioEntrada_Actualizar
    @idPrecioEntrada INT,
    @monto           DECIMAL(12,2),
    @vigenciaHasta   DATE = NULL,
    @moneda          VARCHAR(10) = 'ARS'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
    DECLARE @vigenciaDesde DATE;

    SELECT @vigenciaDesde = vigenciaDesde FROM ventas.PrecioEntrada WHERE idPrecioEntrada = @idPrecioEntrada;

    IF @vigenciaDesde IS NULL
        SET @errores += '- No existe un precio de entrada con el ID indicado.' + CHAR(13);
    IF @monto < 0
        SET @errores += '- El monto no puede ser negativo.' + CHAR(13);
    IF @vigenciaHasta IS NOT NULL AND @vigenciaHasta < @vigenciaDesde
        SET @errores += '- La fecha de fin de vigencia no puede ser anterior a la de inicio.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.PrecioEntrada
    SET monto = @monto, vigenciaHasta = @vigenciaHasta, moneda = @moneda
    WHERE idPrecioEntrada = @idPrecioEntrada;
END
GO


-- atracciones.Atraccion


CREATE PROCEDURE sp_Atraccion_Insertar
    @idParque    INT,
    @nombre      VARCHAR(200),
    @tipo        VARCHAR(100),
    @duracionMin INT  = NULL,
    @cupoMaximo  INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
        SET @errores += '- El parque indicado no existe o no esta activo.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @errores += '- El nombre de la atraccion es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@tipo)), '')   IS NULL SET @errores += '- El tipo de atraccion es obligatorio.' + CHAR(13);
    IF @duracionMin IS NOT NULL AND @duracionMin <= 0 SET @errores += '- La duracion debe ser mayor a cero.' + CHAR(13);
    IF @cupoMaximo  IS NOT NULL AND @cupoMaximo  <= 0 SET @errores += '- El cupo maximo debe ser mayor a cero.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO atracciones.Atraccion (idParque, nombre, tipo, duracionMin, cupoMaximo, activa)
    VALUES (@idParque, @nombre, @tipo, @duracionMin, @cupoMaximo, 1);

    SELECT SCOPE_IDENTITY() AS idAtraccion;
END
GO

CREATE PROCEDURE sp_Atraccion_Actualizar
    @idAtraccion INT,
    @nombre      VARCHAR(200),
    @tipo        VARCHAR(100),
    @duracionMin INT  = NULL,
    @cupoMaximo  INT  = NULL,
    @activa      BIT  = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.Atraccion WHERE idAtraccion = @idAtraccion)
        SET @errores += '- No existe una atraccion con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@tipo)), '')   IS NULL SET @errores += '- El tipo es obligatorio.' + CHAR(13);
    IF @duracionMin IS NOT NULL AND @duracionMin <= 0 SET @errores += '- La duracion debe ser mayor a cero.' + CHAR(13);
    IF @cupoMaximo  IS NOT NULL AND @cupoMaximo  <= 0 SET @errores += '- El cupo maximo debe ser mayor a cero.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE atracciones.Atraccion
    SET nombre = @nombre, tipo = @tipo, duracionMin = @duracionMin,
        cupoMaximo = @cupoMaximo, activa = @activa
    WHERE idAtraccion = @idAtraccion;
END
GO

CREATE PROCEDURE sp_Atraccion_Eliminar
    @idAtraccion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.Atraccion WHERE idAtraccion = @idAtraccion)
        SET @errores += '- No existe una atraccion con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM atracciones.Tour WHERE idAtraccion = @idAtraccion AND estado IN ('Programado','EnCurso'))
        SET @errores += '- No se puede eliminar: la atraccion tiene tours activos.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE atracciones.Atraccion SET activa = 0 WHERE idAtraccion = @idAtraccion;
END
GO


-- atracciones.PrecioAtraccion


CREATE PROCEDURE sp_PrecioAtraccion_Insertar
    @idAtraccion   INT,
    @monto         DECIMAL(12,2),
    @vigenciaDesde DATE,
    @vigenciaHasta DATE = NULL,
    @moneda        VARCHAR(10) = 'ARS'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.Atraccion WHERE idAtraccion = @idAtraccion AND activa = 1)
        SET @errores += '- La atraccion indicada no existe o no esta activa.' + CHAR(13);
    IF @monto < 0
        SET @errores += '- El monto no puede ser negativo.' + CHAR(13);
    IF @vigenciaHasta IS NOT NULL AND @vigenciaHasta < @vigenciaDesde
        SET @errores += '- La fecha de fin de vigencia no puede ser anterior al inicio.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM atracciones.PrecioAtraccion
        WHERE idAtraccion = @idAtraccion
          AND vigenciaDesde <= ISNULL(@vigenciaHasta, '9999-12-31')
          AND ISNULL(vigenciaHasta, '9999-12-31') >= @vigenciaDesde
    )
        SET @errores += '- Ya existe un precio vigente para esa atraccion en el periodo indicado.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO atracciones.PrecioAtraccion (idAtraccion, monto, vigenciaDesde, vigenciaHasta, moneda)
    VALUES (@idAtraccion, @monto, @vigenciaDesde, @vigenciaHasta, @moneda);

    SELECT SCOPE_IDENTITY() AS idPrecioAtraccion;
END
GO

-- atracciones.GuiaAutorizado

CREATE PROCEDURE sp_GuiaAutorizado_Insertar
    @nombre      VARCHAR(100),
    @apellido    VARCHAR(100),
    @dni         VARCHAR(20),
    @especialidad VARCHAR(150) = NULL,
    @titulo      VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@nombre)), '')   IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@dni)), '')      IS NULL SET @errores += '- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE dni = @dni)
        SET @errores += '- Ya existe un guia con ese DNI.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO atracciones.GuiaAutorizado (nombre, apellido, dni, especialidad, titulo, activo)
    VALUES (@nombre, @apellido, @dni, @especialidad, @titulo, 1);

    SELECT SCOPE_IDENTITY() AS idGuia;
END
GO

CREATE  PROCEDURE sp_GuiaAutorizado_Actualizar
    @idGuia       INT,
    @nombre       VARCHAR(100),
    @apellido     VARCHAR(100),
    @dni          VARCHAR(20),
    @especialidad VARCHAR(150) = NULL,
    @titulo       VARCHAR(150) = NULL,
    @activo       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE idGuia = @idGuia)
        SET @errores += '- No existe un guia con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@nombre)), '')   IS NULL SET @errores += '- El nombre es obligatorio.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL SET @errores += '- El apellido es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE dni = @dni AND idGuia <> @idGuia)
        SET @errores += '- Otro guia ya tiene ese DNI.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE atracciones.GuiaAutorizado
    SET nombre = @nombre, apellido = @apellido, dni = @dni,
        especialidad = @especialidad, titulo = @titulo, activo = @activo
    WHERE idGuia = @idGuia;
END
GO

CREATE OR ALTER PROCEDURE sp_GuiaAutorizado_Eliminar
    @idGuia INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE idGuia = @idGuia)
        SET @errores += '- No existe un guia con el ID indicado.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM atracciones.TourGuia tg
        JOIN atracciones.Tour t ON tg.idTour = t.idTour
        WHERE tg.idGuia = @idGuia AND t.estado IN ('Programado','EnCurso')
    )
        SET @errores += '- No se puede eliminar: el guia tiene tours activos asignados.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE atracciones.GuiaAutorizado SET activo = 0 WHERE idGuia = @idGuia;
END
GO

-- atracciones.HabilitacionGuia


CREATE PROCEDURE sp_HabilitacionGuia_Insertar
    @idGuia        INT,
    @descripcion   VARCHAR(300),
    @fechaVigencia DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.GuiaAutorizado WHERE idGuia = @idGuia AND activo = 1)
        SET @errores += '- El guia indicado no existe o no esta activo.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL
        SET @errores += '- La descripcion de la habilitacion es obligatoria.' + CHAR(13);
    IF @fechaVigencia < CAST(GETDATE() AS DATE)
        SET @errores += '- La fecha de vigencia no puede ser anterior a hoy.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO atracciones.HabilitacionGuia (idGuia, descripcion, fechaVigencia)
    VALUES (@idGuia, @descripcion, @fechaVigencia);

    SELECT SCOPE_IDENTITY() AS idHabilitacion;
END
GO

CREATE PROCEDURE sp_HabilitacionGuia_Eliminar
    @idHabilitacion INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM atracciones.HabilitacionGuia WHERE idHabilitacion = @idHabilitacion)
    BEGIN
        RAISERROR('- No existe una habilitacion con el ID indicado.', 16, 1);
        RETURN;
    END

    DELETE FROM atracciones.HabilitacionGuia WHERE idHabilitacion = @idHabilitacion;
END
GO


-- atracciones.Tour


CREATE PROCEDURE sp_Tour_Insertar
    @idAtraccion     INT,
    @fechaHoraInicio DATETIME,
    @cupoDisponible  INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
    DECLARE @cupoMax INT;

    SELECT @cupoMax = cupoMaximo
    FROM atracciones.Atraccion
    WHERE idAtraccion = @idAtraccion AND activa = 1;

    IF @cupoMax IS NULL
        SET @errores += '- La atraccion indicada no existe o no esta activa.' + CHAR(13);
    IF @fechaHoraInicio <= GETDATE()
        SET @errores += '- La fecha y hora del tour debe ser futura.' + CHAR(13);
    IF @cupoDisponible <= 0
        SET @errores += '- El cupo disponible debe ser mayor a cero.' + CHAR(13);
    IF @cupoMax IS NOT NULL AND @cupoDisponible > @cupoMax
        SET @errores += '- El cupo disponible (' + CAST(@cupoDisponible AS VARCHAR) + ') no puede superar el cupo maximo de la atraccion (' + CAST(@cupoMax AS VARCHAR) + ').' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO atracciones.Tour (idAtraccion, fechaHoraInicio, cupoDisponible, estado)
    VALUES (@idAtraccion, @fechaHoraInicio, @cupoDisponible, 'Programado');

    SELECT SCOPE_IDENTITY() AS idTour;
END
GO

CREATE PROCEDURE sp_Tour_ActualizarEstado
    @idTour INT,
    @estado VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM atracciones.Tour WHERE idTour = @idTour)
        SET @errores += '- No existe un tour con el ID indicado.' + CHAR(13);
    IF @estado NOT IN ('Programado','EnCurso','Finalizado','Cancelado')
        SET @errores += '- Estado invalido. Valores permitidos: Programado, EnCurso, Finalizado, Cancelado.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE atracciones.Tour SET estado = @estado WHERE idTour = @idTour;
END
GO


-- concesiones.Concesionario


CREATE PROCEDURE sp_Concesionario_Insertar
    @razonSocial VARCHAR(200),
    @cuit        VARCHAR(13),
    @email       VARCHAR(150) = NULL,
    @telefono    VARCHAR(50)  = NULL,
    @contacto    VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NULLIF(LTRIM(RTRIM(@razonSocial)), '') IS NULL SET @errores += '- La razon social es obligatoria.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@cuit)), '')        IS NULL SET @errores += '- El CUIT es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM concesiones.Concesionario WHERE cuit = @cuit)
        SET @errores += '- Ya existe un concesionario con ese CUIT.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO concesiones.Concesionario (razonSocial, cuit, email, telefono, contacto)
    VALUES (@razonSocial, @cuit, @email, @telefono, @contacto);

    SELECT SCOPE_IDENTITY() AS idConcesionario;
END
GO

CREATE  PROCEDURE sp_Concesionario_Actualizar
    @idConcesionario INT,
    @razonSocial     VARCHAR(200),
    @cuit            VARCHAR(13),
    @email           VARCHAR(150) = NULL,
    @telefono        VARCHAR(50)  = NULL,
    @contacto        VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesionario WHERE idConcesionario = @idConcesionario)
        SET @errores += '- No existe un concesionario con el ID indicado.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@razonSocial)), '') IS NULL SET @errores += '- La razon social es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM concesiones.Concesionario WHERE cuit = @cuit AND idConcesionario <> @idConcesionario)
        SET @errores += '- Otro concesionario ya tiene ese CUIT.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE concesiones.Concesionario
    SET razonSocial = @razonSocial, cuit = @cuit,
        email = @email, telefono = @telefono, contacto = @contacto
    WHERE idConcesionario = @idConcesionario;
END
GO

CREATE OR ALTER PROCEDURE sp_Concesionario_Eliminar
    @idConcesionario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesionario WHERE idConcesionario = @idConcesionario)
        SET @errores += '- No existe un concesionario con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE idConcesionario = @idConcesionario)
        SET @errores += '- No se puede eliminar: el concesionario tiene concesiones asociadas.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    DELETE FROM concesiones.Concesionario WHERE idConcesionario = @idConcesionario;
END
GO


-- concesiones.Concesion

CREATE  PROCEDURE sp_Concesion_Insertar
    @idConcesionario   INT,
    @idParque          INT,
    @tipoActividad     VARCHAR(200),
    @fechaInicio       DATE,
    @fechaFin          DATE,
    @diaVencimientoPago INT = 10,
    @canonMensual      DECIMAL(12,2),
    @moneda            VARCHAR(10) = 'ARS'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesionario WHERE idConcesionario = @idConcesionario)
        SET @errores += '- El concesionario indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque AND activo = 1)
        SET @errores += '- El parque indicado no existe o no esta activo.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@tipoActividad)), '') IS NULL
        SET @errores += '- El tipo de actividad es obligatorio.' + CHAR(13);
    IF @fechaFin <= @fechaInicio
        SET @errores += '- La fecha de fin debe ser posterior a la fecha de inicio.' + CHAR(13);
    IF @canonMensual <= 0
        SET @errores += '- El canon mensual debe ser mayor a cero.' + CHAR(13);
    IF @diaVencimientoPago < 1 OR @diaVencimientoPago > 28
        SET @errores += '- El dia de vencimiento de pago debe estar entre 1 y 28.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO concesiones.Concesion
        (idConcesionario, idParque, tipoActividad, fechaInicio, fechaFin,
         diaVencimientoPago, canonMensual, moneda, estado)
    VALUES
        (@idConcesionario, @idParque, @tipoActividad, @fechaInicio, @fechaFin,
         @diaVencimientoPago, @canonMensual, @moneda, 'Vigente');

    SELECT SCOPE_IDENTITY() AS idConcesion;
END
GO

CREATE PROCEDURE sp_Concesion_Actualizar
    @idConcesion        INT,
    @tipoActividad      VARCHAR(200),
    @fechaFin           DATE,
    @diaVencimientoPago INT,
    @canonMensual       DECIMAL(12,2),
    @moneda             VARCHAR(10),
    @estado             VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';
    DECLARE @fechaInicio DATE;

    SELECT @fechaInicio = fechaInicio FROM concesiones.Concesion WHERE idConcesion = @idConcesion;

    IF @fechaInicio IS NULL SET @errores += '- No existe una concesion con el ID indicado.' + CHAR(13);
    IF @fechaFin <= @fechaInicio  SET @errores += '- La fecha de fin debe ser posterior al inicio.' + CHAR(13);
    IF @canonMensual <= 0        SET @errores += '- El canon debe ser mayor a cero.' + CHAR(13);
    IF @estado NOT IN ('Vigente','Vencida','Rescindida')
        SET @errores += '- Estado invalido. Valores permitidos: Vigente, Vencida, Rescindida.' + CHAR(13);
    IF @diaVencimientoPago < 1 OR @diaVencimientoPago > 28
        SET @errores += '- El dia de vencimiento debe estar entre 1 y 28.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE concesiones.Concesion
    SET tipoActividad = @tipoActividad, fechaFin = @fechaFin,
        diaVencimientoPago = @diaVencimientoPago, canonMensual = @canonMensual,
        moneda = @moneda, estado = @estado
    WHERE idConcesion = @idConcesion;
END
GO


-- concesiones.PagoCanon


CREATE PROCEDURE sp_PagoCanon_Insertar
    @idConcesion INT,
    @idFormaPago INT,
    @fechaPago   DATE,
    @monto       DECIMAL(12,2),
    @comprobante VARCHAR(200) = NULL,
    @periodo     VARCHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE idConcesion = @idConcesion)
        SET @errores += '- La concesion indicada no existe.' + CHAR(13);
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

    INSERT INTO concesiones.PagoCanon (idConcesion, idFormaPago, fechaPago, monto, comprobante, periodo)
    VALUES (@idConcesion, @idFormaPago, @fechaPago, @monto, @comprobante, @periodo);

    SELECT SCOPE_IDENTITY() AS idPago;
END
GO


-- importacion.ImportacionLog

CREATE PROCEDURE sp_ImportacionLog_Insertar
    @idParque   INT = NULL,
    @fuente     VARCHAR(300),
    @formato    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF @idParque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque)
        SET @errores += '- El parque indicado no existe.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@fuente)), '')  IS NULL SET @errores += '- La fuente es obligatoria.' + CHAR(13);
    IF NULLIF(LTRIM(RTRIM(@formato)), '') IS NULL SET @errores += '- El formato es obligatorio.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO importacion.ImportacionLog (idParque, fuente, formato, fechaEjecucion, estado)
    VALUES (@idParque, @fuente, @formato, GETDATE(), 'Pendiente');

    SELECT SCOPE_IDENTITY() AS idImportacion;
END
GO

CREATE PROCEDURE sp_ImportacionLog_Actualizar
    @idImportacion       INT,
    @registrosProcesados INT,
    @registrosOk         INT,
    @registrosError      INT,
    @estado              VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM importacion.ImportacionLog WHERE idImportacion = @idImportacion)
        SET @errores += '- No existe un registro de importacion con el ID indicado.' + CHAR(13);
    IF @estado NOT IN ('Pendiente','EnProceso','Completado','CompletadoConErrores','Fallido')
        SET @errores += '- Estado invalido.' + CHAR(13);
    IF @registrosProcesados < 0 SET @errores += '- Los registros procesados no pueden ser negativos.' + CHAR(13);
    IF @registrosOk < 0         SET @errores += '- Los registros ok no pueden ser negativos.' + CHAR(13);
    IF @registrosError < 0      SET @errores += '- Los registros con error no pueden ser negativos.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    UPDATE importacion.ImportacionLog
    SET registrosProcesados = @registrosProcesados,
        registrosOk         = @registrosOk,
        registrosError      = @registrosError,
        estado              = @estado
    WHERE idImportacion = @idImportacion;
END
GO


-- importacion.CondicionClimatica
CREATE PROCEDURE sp_CondicionClimatica_Insertar
    @idParque        INT,
    @fecha           DATE,
    @tempMax         DECIMAL(5,2) = NULL,
    @tempMin         DECIMAL(5,2) = NULL,
    @precipitacionMm DECIMAL(7,2) = NULL,
    @diaLluvioso     BIT = 0,
    @fuenteApi       VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE idParque = @idParque)
        SET @errores += '- El parque indicado no existe.' + CHAR(13);
    IF @tempMax IS NOT NULL AND @tempMin IS NOT NULL AND @tempMax < @tempMin
        SET @errores += '- La temperatura maxima no puede ser menor a la minima.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM importacion.CondicionClimatica WHERE idParque = @idParque AND fecha = @fecha)
        SET @errores += '- Ya existe un registro climatico para ese parque y fecha.' + CHAR(13);

    IF @errores <> ''
    BEGIN
        RAISERROR(@errores, 16, 1);
        RETURN;
    END

    INSERT INTO importacion.CondicionClimatica
        (idParque, fecha, tempMax, tempMin, precipitacionMm, diaLluvioso, fuenteApi)
    VALUES
        (@idParque, @fecha, @tempMax, @tempMin, @precipitacionMm, @diaLluvioso, @fuenteApi);

    SELECT SCOPE_IDENTITY() AS idCondicion;
END
GO