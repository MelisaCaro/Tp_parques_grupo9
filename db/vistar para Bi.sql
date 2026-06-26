/*
============================================================
  Descripcion: Vistas para conectar Power BI a la base de datos.
               Cada vista corresponde a un reporte de la Entrega 7.
               Power BI se conecta directamente a estas vistas
               sin necesidad de ejecutar los SPs manualmente.

  Vistas creadas:
    bi.vw_VisitasPorMes       -> Reporte 1: visitas por mes y parque
    bi.vw_IngresosPorParque   -> Reporte 2: ingresos por parque y mes
    bi.vw_Deudores            -> Reporte 3: concesiones con pagos atrasados
    bi.vw_MatrizVisitas       -> Reporte 4: pivot de visitas por mes
    bi.vw_ParquesConCesiones  -> Reporte 5: parques con sus concesiones
    bi.vw_Parques             -> Mapa: parques con latitud/longitud
============================================================
*/

USE ParquesNacionalesDB;
GO

-- Schema dedicado para las vistas de BI
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bi')
    EXEC('CREATE SCHEMA bi');
GO

-- VISTA 1: Visitas por mes y parque
-- Usada para: grafico de barras y lineas de visitantes



CREATE VIEW bi.vw_VisitasPorMes AS
SELECT
    p.nombre                                    AS parque,
    tp.nombre                                   AS tipoParque,
    YEAR(e.fechaAcceso)                         AS anio,
    MONTH(e.fechaAcceso)                        AS nroMes,
    FORMAT(e.fechaAcceso, 'MMMM', 'es-AR')     AS mes,
    -- Fecha del primer dia del mes (para que Power BI pueda ordenar cronologicamente)
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1) AS fechaMes,
    COUNT(e.idEntrada)                          AS cantidadVisitas,
    SUM(e.montoPagado)                          AS totalRecaudadoARS
FROM ventas.Entrada e
JOIN parques.Parque p       ON p.idParque       = e.idParque
JOIN maestros.TipoParque tp ON tp.idTipoParque  = p.idTipoParque
WHERE e.estado = 'Activa'
GROUP BY
    p.nombre,
    tp.nombre,
    YEAR(e.fechaAcceso),
    MONTH(e.fechaAcceso),
    FORMAT(e.fechaAcceso, 'MMMM', 'es-AR'),
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1);
GO

-- VISTA 2: Ingresos por parque (entradas + actividades)
-- Usada para: grafico de barras de ingresos totales



CREATE VIEW bi.vw_IngresosPorParque AS

-- Ingresos por entradas
SELECT
    p.nombre                                                AS parque,
    YEAR(e.fechaAcceso)                                     AS anio,
    MONTH(e.fechaAcceso)                                    AS nroMes,
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1) AS fechaMes,
    'Entradas'                                              AS concepto,
    COUNT(e.idEntrada)                                      AS cantidad,
    SUM(e.montoPagado)                                      AS totalARS
FROM ventas.Entrada e
JOIN parques.Parque p ON p.idParque = e.idParque
WHERE e.estado = 'Activa'
GROUP BY
    p.nombre,
    YEAR(e.fechaAcceso),
    MONTH(e.fechaAcceso),
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1)

UNION ALL

-- Ingresos por actividades/tours
SELECT
    p.nombre                                                AS parque,
    YEAR(t.fechaHoraInicio)                                 AS anio,
    MONTH(t.fechaHoraInicio)                                AS nroMes,
    DATEFROMPARTS(YEAR(t.fechaHoraInicio), MONTH(t.fechaHoraInicio), 1) AS fechaMes,
    'Actividades'                                           AS concepto,
    COUNT(ca.idContratacion)                                AS cantidad,
    SUM(ca.monto)                                           AS totalARS
FROM atracciones.ContratacionActividad ca
JOIN atracciones.Tour t     ON t.idTour     = ca.idTour
JOIN atracciones.Atraccion a ON a.idAtraccion = t.idAtraccion
JOIN parques.Parque p       ON p.idParque   = a.idParque
WHERE ca.estado = 'Confirmada'
GROUP BY
    p.nombre,
    YEAR(t.fechaHoraInicio),
    MONTH(t.fechaHoraInicio),
    DATEFROMPARTS(YEAR(t.fechaHoraInicio), MONTH(t.fechaHoraInicio), 1)

UNION ALL

-- Ingresos por canon de concesiones
SELECT
    p.nombre                                                AS parque,
    YEAR(pc.fechaPago)                                      AS anio,
    MONTH(pc.fechaPago)                                     AS nroMes,
    DATEFROMPARTS(YEAR(pc.fechaPago), MONTH(pc.fechaPago), 1) AS fechaMes,
    'Canon Concesiones'                                     AS concepto,
    COUNT(pc.idPago)                                   AS cantidad,
    SUM(pc.monto)                                           AS totalARS
FROM concesiones.PagoCanon pc
JOIN concesiones.Concesion c ON c.idConcesion = pc.idConcesion
JOIN parques.Parque p        ON p.idParque    = c.idParque
GROUP BY
    p.nombre,
    YEAR(pc.fechaPago),
    MONTH(pc.fechaPago),
    DATEFROMPARTS(YEAR(pc.fechaPago), MONTH(pc.fechaPago), 1);
GO


-- VISTA 3: Concesiones deudoras
-- Usada para: tabla de deudores en Power BI



CREATE VIEW bi.vw_Deudores AS
SELECT
    co.razonSocial                          AS concesionario,
    p.nombre                                AS parque,
    c.tipoActividad,
    c.fechaInicio,
    c.fechaFin,
    c.canonMensual,
    c.moneda,
    c.estado,
    DATEDIFF(MONTH, c.fechaInicio,
        CASE WHEN c.fechaFin < CAST(GETDATE() AS DATE)
             THEN c.fechaFin
             ELSE CAST(GETDATE() AS DATE)
        END)                                AS mesesTranscurridos,
    (SELECT COUNT(*) FROM concesiones.PagoCanon pc
     WHERE pc.idConcesion = c.idConcesion) AS mesesPagados,
    DATEDIFF(MONTH, c.fechaInicio,
        CASE WHEN c.fechaFin < CAST(GETDATE() AS DATE)
             THEN c.fechaFin
             ELSE CAST(GETDATE() AS DATE)
        END)
    - (SELECT COUNT(*) FROM concesiones.PagoCanon pc
       WHERE pc.idConcesion = c.idConcesion) AS mesesAdeudados,
    (DATEDIFF(MONTH, c.fechaInicio,
        CASE WHEN c.fechaFin < CAST(GETDATE() AS DATE)
             THEN c.fechaFin
             ELSE CAST(GETDATE() AS DATE)
        END)
    - (SELECT COUNT(*) FROM concesiones.PagoCanon pc
       WHERE pc.idConcesion = c.idConcesion))
    * c.canonMensual                        AS montoAdeudado
FROM concesiones.Concesion c
JOIN concesiones.Concesionario co ON co.idConcesionario = c.idConcesionario
JOIN parques.Parque p             ON p.idParque         = c.idParque
WHERE c.estado IN ('Vigente', 'Vencida')
  AND DATEDIFF(MONTH, c.fechaInicio,
        CASE WHEN c.fechaFin < CAST(GETDATE() AS DATE)
             THEN c.fechaFin
             ELSE CAST(GETDATE() AS DATE)
        END)
    > (SELECT COUNT(*) FROM concesiones.PagoCanon pc
       WHERE pc.idConcesion = c.idConcesion);
GO


-- VISTA 4: Matriz de visitas por mes (para tabla en Power BI)
-- Usada para: matriz/pivot en Power BI


CREATE VIEW bi.vw_MatrizVisitas AS
SELECT
    p.nombre                                                    AS parque,
    YEAR(e.fechaAcceso)                                         AS anio,
    MONTH(e.fechaAcceso)                                        AS nroMes,
    FORMAT(e.fechaAcceso, 'MMMM', 'es-AR')                     AS mes,
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1) AS fechaMes,
    COUNT(e.idEntrada)                                          AS visitas
FROM parques.Parque p
LEFT JOIN ventas.Entrada e
    ON e.idParque = p.idParque
   AND e.estado   = 'Activa'
WHERE p.activo = 1
  AND e.idEntrada IS NOT NULL
GROUP BY
    p.nombre,
    YEAR(e.fechaAcceso),
    MONTH(e.fechaAcceso),
    FORMAT(e.fechaAcceso, 'MMMM', 'es-AR'),
    DATEFROMPARTS(YEAR(e.fechaAcceso), MONTH(e.fechaAcceso), 1);
GO


-- VISTA 5: Parques con coordenadas (para mapa en Power BI)
-- Usada para: visual de mapa con burbujas por visitas


CREATE VIEW bi.vw_Parques AS
SELECT
    p.idParque,
    p.nombre,
    p.ubicacion,
    tp.nombre                           AS tipoParque,
    p.superficieHa,
    p.latitud,
    p.longitud,
    p.activo,
    COUNT(e.idEntrada)                  AS totalVisitas,
    SUM(e.montoPagado)                  AS totalRecaudadoARS
FROM parques.Parque p
JOIN maestros.TipoParque tp ON tp.idTipoParque = p.idTipoParque
LEFT JOIN ventas.Entrada e
    ON e.idParque = p.idParque
   AND e.estado   = 'Activa'
WHERE p.activo = 1
GROUP BY
    p.idParque, p.nombre, p.ubicacion,
    tp.nombre, p.superficieHa, p.latitud, p.longitud, p.activo;
GO


-- GRANT: dar acceso de lectura a usr_admin sobre el schema bi


GRANT SELECT ON SCHEMA::bi TO rol_admin;
GO


-- VERIFICACION:


SELECT 'vw_VisitasPorMes'     AS vista, COUNT(*) AS filas FROM bi.vw_VisitasPorMes
UNION ALL
SELECT 'vw_IngresosPorParque',                COUNT(*) FROM bi.vw_IngresosPorParque
UNION ALL
SELECT 'vw_Deudores',                         COUNT(*) FROM bi.vw_Deudores
UNION ALL
SELECT 'vw_MatrizVisitas',                    COUNT(*) FROM bi.vw_MatrizVisitas
UNION ALL
SELECT 'vw_Parques',                          COUNT(*) FROM bi.vw_Parques;
GO