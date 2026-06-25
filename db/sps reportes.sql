/*
============================================================
  Universidad: Universidad Nacional de la Matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri Villalba, Santino; Llanos, Franco; Vazquez, Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Stored Procedures de reportes.
               Los reportes 2 y 5 retornan XML segun
               lo requerido por el enunciado.
               Reportes:
                 1. Visitas por semana, mes y año por parque
                 2. Ingresos por parque por periodo (XML)
                 3. Deudores: concesiones atrasadas en pagos
                 4. Matriz de visitas: Pivot por mes y parque
                 5. Parques y concesiones anidadas (XML)
============================================================
*/
 
USE ParquesNacionalesDB;
GO
 
-- ============================================================
-- REPORTE 1: Visitas por semana, mes y año por parque
-- Descripcion: Cuenta la cantidad de entradas activas
--   agrupadas por parque y periodo (semana, mes, año).
--   Permite filtrar por parque y rango de fechas.
--
-- Parametros:
--   @idParque    : filtrar por parque especifico (NULL = todos)
--   @fechaDesde  : fecha de inicio del rango (NULL = sin limite)
--   @fechaHasta  : fecha de fin del rango (NULL = sin limite)
--   @agrupacion  : 'SEMANA', 'MES' o 'ANIO'
-- ============================================================
 
CREATE PROCEDURE sp_ReporteVisitasPorPeriodo
    @idParque   INT          = NULL,
    @fechaDesde DATE         = NULL,
    @fechaHasta DATE         = NULL,
    @agrupacion VARCHAR(10)  = 'MES'
AS
BEGIN
    SET NOCOUNT ON;
 
    IF @agrupacion NOT IN ('SEMANA', 'MES', 'ANIO')
    BEGIN
        RAISERROR('- Agrupacion invalida. Valores permitidos: SEMANA, MES, ANIO.', 16, 1);
        RETURN;
    END
 
    IF @agrupacion = 'ANIO'
    BEGIN
        SELECT
            p.nombre                          AS parque,
            YEAR(e.fechaAcceso)               AS anio,
            COUNT(e.idEntrada)                AS cantidadVisitas,
            SUM(e.montoPagado)                AS totalRecaudado
        FROM ventas.Entrada e
        JOIN parques.Parque p ON p.idParque = e.idParque
        WHERE e.estado = 'Activa'
          AND (@idParque   IS NULL OR e.idParque    = @idParque)
          AND (@fechaDesde IS NULL OR e.fechaAcceso >= @fechaDesde)
          AND (@fechaHasta IS NULL OR e.fechaAcceso <= @fechaHasta)
        GROUP BY p.nombre, YEAR(e.fechaAcceso)
        ORDER BY p.nombre, anio;
    END
 
    ELSE IF @agrupacion = 'MES'
    BEGIN
        SELECT
            p.nombre                          AS parque,
            YEAR(e.fechaAcceso)               AS anio,
            MONTH(e.fechaAcceso)              AS mes,
            FORMAT(e.fechaAcceso, 'MMMM', 'es-AR') AS nombreMes,
            COUNT(e.idEntrada)                AS cantidadVisitas,
            SUM(e.montoPagado)                AS totalRecaudado
        FROM ventas.Entrada e
        JOIN parques.Parque p ON p.idParque = e.idParque
        WHERE e.estado = 'Activa'
          AND (@idParque   IS NULL OR e.idParque    = @idParque)
          AND (@fechaDesde IS NULL OR e.fechaAcceso >= @fechaDesde)
          AND (@fechaHasta IS NULL OR e.fechaAcceso <= @fechaHasta)
        GROUP BY p.nombre, YEAR(e.fechaAcceso), MONTH(e.fechaAcceso),
                 FORMAT(e.fechaAcceso, 'MMMM', 'es-AR')
        ORDER BY p.nombre, anio, mes;
    END
 
    ELSE IF @agrupacion = 'SEMANA'
    BEGIN
        SELECT
            p.nombre                          AS parque,
            YEAR(e.fechaAcceso)               AS anio,
            DATEPART(WEEK, e.fechaAcceso)     AS semana,
            MIN(e.fechaAcceso)                AS inicioSemana,
            MAX(e.fechaAcceso)                AS finSemana,
            COUNT(e.idEntrada)                AS cantidadVisitas,
            SUM(e.montoPagado)                AS totalRecaudado
        FROM ventas.Entrada e
        JOIN parques.Parque p ON p.idParque = e.idParque
        WHERE e.estado = 'Activa'
          AND (@idParque   IS NULL OR e.idParque    = @idParque)
          AND (@fechaDesde IS NULL OR e.fechaAcceso >= @fechaDesde)
          AND (@fechaHasta IS NULL OR e.fechaAcceso <= @fechaHasta)
        GROUP BY p.nombre, YEAR(e.fechaAcceso), DATEPART(WEEK, e.fechaAcceso)
        ORDER BY p.nombre, anio, semana;
    END
END
GO
 
 
-- ============================================================
-- REPORTE 2: Ingresos por parque por periodo (XML)
-- Descripcion: Retorna en formato XML los ingresos de cada
--   parque desglosados por concepto (entradas, tours,
--   concesiones) y agrupados por año y mes.
--
-- Parametros:
--   @anio     : año a reportar (NULL = todos)
--   @idParque : filtrar por parque especifico (NULL = todos)
-- ============================================================
 
CREATE PROCEDURE sp_ReporteIngresosPorParqueXML
    @anio     INT = NULL,
    @idParque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Ingresos por entradas
    SELECT
        p.idParque,
        p.nombre                     AS nombreParque,
        YEAR(e.fechaAcceso)          AS anio,
        MONTH(e.fechaAcceso)         AS mes,
        SUM(e.montoPagado)           AS ingresosEntradas,
        COUNT(e.idEntrada)           AS cantidadEntradas
    INTO #IngresosEntradas
    FROM ventas.Entrada e
    JOIN parques.Parque p ON p.idParque = e.idParque
    WHERE e.estado = 'Activa'
      AND (@anio     IS NULL OR YEAR(e.fechaAcceso) = @anio)
      AND (@idParque IS NULL OR e.idParque          = @idParque)
    GROUP BY p.idParque, p.nombre, YEAR(e.fechaAcceso), MONTH(e.fechaAcceso);
 
    -- Ingresos por tours/actividades
    SELECT
        p.idParque,
        p.nombre                     AS nombreParque,
        YEAR(t.fechaHoraInicio)      AS anio,
        MONTH(t.fechaHoraInicio)     AS mes,
        SUM(ca.monto)                AS ingresosTours,
        COUNT(ca.idContratacion)     AS cantidadTours
    INTO #IngresosTours
    FROM atracciones.ContratacionActividad ca
    JOIN atracciones.Tour t         ON t.idTour       = ca.idTour
    JOIN atracciones.Atraccion a    ON a.idAtraccion  = t.idAtraccion
    JOIN parques.Parque p           ON p.idParque     = a.idParque
    WHERE ca.estado = 'Confirmada'
      AND (@anio     IS NULL OR YEAR(t.fechaHoraInicio) = @anio)
      AND (@idParque IS NULL OR p.idParque              = @idParque)
    GROUP BY p.idParque, p.nombre, YEAR(t.fechaHoraInicio), MONTH(t.fechaHoraInicio);
 
    -- Ingresos por concesiones (pagos de canon)
    SELECT
        p.idParque,
        p.nombre                     AS nombreParque,
        YEAR(pc.fechaPago)           AS anio,
        MONTH(pc.fechaPago)          AS mes,
        SUM(pc.monto)                AS ingresosConcesiones,
        COUNT(pc.idPago)             AS cantidadPagos
    INTO #IngresosConcesiones
    FROM concesiones.PagoCanon pc
    JOIN concesiones.Concesion c ON c.idConcesion = pc.idConcesion
    JOIN parques.Parque p        ON p.idParque    = c.idParque
    WHERE (@anio     IS NULL OR YEAR(pc.fechaPago) = @anio)
      AND (@idParque IS NULL OR p.idParque         = @idParque)
    GROUP BY p.idParque, p.nombre, YEAR(pc.fechaPago), MONTH(pc.fechaPago);
 
    -- Consolidar y retornar en XML
    SELECT
        p.nombre                                            AS [@nombre],
        p.idParque                                          AS [@idParque],
        (
            SELECT
                ie.anio                                     AS [@anio],
                ie.mes                                      AS [@mes],
                ISNULL(ie.ingresosEntradas, 0)              AS [@ingresosEntradas],
                ISNULL(ie.cantidadEntradas, 0)              AS [@cantidadEntradas],
                ISNULL(it.ingresosTours, 0)                 AS [@ingresosTours],
                ISNULL(it.cantidadTours, 0)                 AS [@cantidadTours],
                ISNULL(ic.ingresosConcesiones, 0)           AS [@ingresosConcesiones],
                ISNULL(ic.cantidadPagos, 0)                 AS [@cantidadPagos],
                ISNULL(ie.ingresosEntradas, 0)
                + ISNULL(it.ingresosTours, 0)
                + ISNULL(ic.ingresosConcesiones, 0)         AS [@totalIngresos]
            FROM #IngresosEntradas ie
            LEFT JOIN #IngresosTours it
                ON it.idParque = ie.idParque
               AND it.anio     = ie.anio
               AND it.mes      = ie.mes
            LEFT JOIN #IngresosConcesiones ic
                ON ic.idParque = ie.idParque
               AND ic.anio     = ie.anio
               AND ic.mes      = ie.mes
            WHERE ie.idParque = p.idParque
            ORDER BY ie.anio, ie.mes
            FOR XML PATH('periodo'), TYPE
        )
    FROM parques.Parque p
    WHERE EXISTS (
        SELECT 1 FROM #IngresosEntradas WHERE idParque = p.idParque
    )
    ORDER BY p.nombre
    FOR XML PATH('parque'), ROOT('reporteIngresos');
 
    DROP TABLE #IngresosEntradas;
    DROP TABLE #IngresosTours;
    DROP TABLE #IngresosConcesiones;
END
GO
 
 
-- ============================================================
-- REPORTE 3: Deudores - Concesiones atrasadas en pagos
-- Descripcion: Lista las concesiones que tienen meses sin
--   pagar desde su fecha de inicio hasta hoy.
--   Muestra cuantos meses adeudan y el monto total adeudado.
--
-- Parametros:
--   @idParque : filtrar por parque especifico (NULL = todos)
-- ============================================================
 
CREATE PROCEDURE sp_ReporteDeudores
    @idParque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Generar todos los periodos que deberian estar pagados
    -- para cada concesion vigente o vencida
    SELECT
        c.idConcesion,
        co.razonSocial                          AS concesionario,
        p.nombre                                AS parque,
        c.tipoActividad,
        c.fechaInicio,
        c.fechaFin,
        c.canonMensual,
        c.moneda,
        c.estado,
        -- Meses totales del contrato hasta hoy
        DATEDIFF(MONTH, c.fechaInicio,
            CASE WHEN c.fechaFin < CAST(GETDATE() AS DATE)
                 THEN c.fechaFin
                 ELSE CAST(GETDATE() AS DATE)
            END)                                AS mesesTranscurridos,
        -- Meses efectivamente pagados
        (SELECT COUNT(*) FROM concesiones.PagoCanon pc
         WHERE pc.idConcesion = c.idConcesion)  AS mesesPagados
    INTO #Concesiones
    FROM concesiones.Concesion c
    JOIN concesiones.Concesionario co ON co.idConcesionario = c.idConcesionario
    JOIN parques.Parque p             ON p.idParque         = c.idParque
    WHERE c.estado IN ('Vigente', 'Vencida')
      AND (@idParque IS NULL OR c.idParque = @idParque);
 
    -- Mostrar solo las que tienen meses sin pagar
    SELECT
        idConcesion,
        concesionario,
        parque,
        tipoActividad,
        fechaInicio,
        fechaFin,
        estado,
        canonMensual,
        moneda,
        mesesTranscurridos,
        mesesPagados,
        mesesTranscurridos - mesesPagados       AS mesesAdeudados,
        canonMensual * (mesesTranscurridos - mesesPagados) AS montoTotalAdeudado
    FROM #Concesiones
    WHERE mesesTranscurridos > mesesPagados
    ORDER BY montoTotalAdeudado DESC;
 
    DROP TABLE #Concesiones;
END
GO
 
 
-- ============================================================
-- REPORTE 4: Matriz de visitas - Pivot por mes y parque
-- Descripcion: Tabla cruzada que muestra la cantidad de
--   visitas por mes en columnas y parque en filas.
--   Cubre los 12 meses del año indicado.
--
-- Parametros:
--   @anio : año a reportar (default año actual)
-- ============================================================
 
CREATE PROCEDURE sp_MatrizVisitas
    @anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    IF @anio IS NULL
        SET @anio = YEAR(GETDATE());
 
    SELECT
        p.nombre AS parque,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 1  THEN 1 ELSE 0 END) AS Enero,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 2  THEN 1 ELSE 0 END) AS Febrero,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 3  THEN 1 ELSE 0 END) AS Marzo,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 4  THEN 1 ELSE 0 END) AS Abril,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 5  THEN 1 ELSE 0 END) AS Mayo,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 6  THEN 1 ELSE 0 END) AS Junio,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 7  THEN 1 ELSE 0 END) AS Julio,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 8  THEN 1 ELSE 0 END) AS Agosto,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 9  THEN 1 ELSE 0 END) AS Septiembre,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 10 THEN 1 ELSE 0 END) AS Octubre,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 11 THEN 1 ELSE 0 END) AS Noviembre,
        SUM(CASE WHEN MONTH(e.fechaAcceso) = 12 THEN 1 ELSE 0 END) AS Diciembre,
        COUNT(e.idEntrada)                                           AS Total
    FROM parques.Parque p
    LEFT JOIN ventas.Entrada e
        ON e.idParque = p.idParque
       AND e.estado   = 'Activa'
       AND YEAR(e.fechaAcceso) = @anio
    WHERE p.activo = 1
    GROUP BY p.nombre
    ORDER BY Total DESC, p.nombre;
END
GO
 
 
-- ============================================================
-- REPORTE 5: Parques y concesiones anidadas (XML)
-- Descripcion: Retorna en formato XML un listado de parques
--   con sus concesiones anidadas como vector, incluyendo
--   fecha de inicio, titular, servicio y estado de cada una.
--
-- Parametros:
--   @idParque : filtrar por parque especifico (NULL = todos)
--   @estado   : filtrar concesiones por estado (NULL = todas)
-- ============================================================
 
CREATE PROCEDURE sp_ReporteParquesYConcesionesXML
    @idParque INT         = NULL,
    @estado   VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        p.nombre                                        AS [@nombre],
        p.idParque                                      AS [@idParque],
        p.ubicacion                                     AS [@ubicacion],
        tp.nombre                                       AS [@tipoParque],
        p.superficieHa                                  AS [@superficieHa],
        (
            SELECT
                c.idConcesion                           AS [@idConcesion],
                co.razonSocial                          AS [@titular],
                co.cuit                                 AS [@cuit],
                c.tipoActividad                         AS [@servicio],
                CONVERT(VARCHAR(10), c.fechaInicio, 23) AS [@fechaInicio],
                CONVERT(VARCHAR(10), c.fechaFin, 23)    AS [@fechaFin],
                c.canonMensual                          AS [@canonMensual],
                c.moneda                                AS [@moneda],
                c.estado                                AS [@estado],
                -- Cantidad de pagos realizados
                (SELECT COUNT(*) FROM concesiones.PagoCanon pc
                 WHERE pc.idConcesion = c.idConcesion)  AS [@pagosRealizados],
                -- Monto total cobrado
                (SELECT ISNULL(SUM(monto), 0)
                 FROM concesiones.PagoCanon pc
                 WHERE pc.idConcesion = c.idConcesion)  AS [@montoTotalCobrado]
            FROM concesiones.Concesion c
            JOIN concesiones.Concesionario co
                ON co.idConcesionario = c.idConcesionario
            WHERE c.idParque = p.idParque
              AND (@estado IS NULL OR c.estado = @estado)
            ORDER BY c.fechaInicio
            FOR XML PATH('concesion'), TYPE
        )
    FROM parques.Parque p
    JOIN maestros.TipoParque tp ON tp.idTipoParque = p.idTipoParque
    WHERE p.activo = 1
      AND (@idParque IS NULL OR p.idParque = @idParque)
    ORDER BY p.nombre
    FOR XML PATH('parque'), ROOT('reporteParquesYConcesiones');
END
GO
 


 /* 
 para usar los reportes hago:

 Reporte 1 — Visitas por periodo:
 EXEC sp_ReporteVisitasPorPeriodo @agrupacion = 'MES';
EXEC sp_ReporteVisitasPorPeriodo @agrupacion = 'ANIO';
EXEC sp_ReporteVisitasPorPeriodo @idParque = 1, @agrupacion = 'SEMANA';

Reporte 2 — Ingresos por parque (XML):
EXEC sp_ReporteIngresosPorParqueXML @anio = 2026;

Reporte 3 — Deudores:
EXEC sp_ReporteDeudores;

Reporte 4 — Matriz de visitas (Pivot):
EXEC sp_MatrizVisitas @anio = 2026;


Reporte 5 — Parques y concesiones (XML):
EXEC sp_ReporteParquesYConcesionesXML;
EXEC sp_ReporteParquesYConcesionesXML @estado = 'Vigente';

*/