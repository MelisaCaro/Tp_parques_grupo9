use ParquesNacionalesDB

/*
============================================================
  Descripcion: Testing de permisos por rol.
               Demuestra que cada usuario puede hacer
               exactamente lo que su rol permite y nada mas.
               Cada bloque usa EXECUTE AS USER para simular
               el login del usuario sin necesidad de
               reconectarse.

  Roles y lo que pueden hacer:
    usr_admin     : todo
    usr_ventas    : vender entradas, anular, gestionar visitantes
    usr_consulta  : solo ejecutar SPs de reportes
    usr_importador: solo ejecutar SPs de importacion
============================================================
*/

USE ParquesNacionalesDB;
GO


-- BLOQUE 1: usr_ventas


PRINT '=== TESTS usr_ventas (rol_ventas) ===';
GO

-- TEST V.1: PERMITIDO - Puede ver visitantes (SELECT directo)
-- Resultado esperado: lista de visitantes
PRINT '--- V.1: SELECT ventas.Visitante (PERMITIDO) ---';
EXECUTE AS USER = 'usr_ventas';
    SELECT TOP 3 idVisitante, nombre, apellido FROM ventas.Visitante;
REVERT;
GO

-- TEST V.2: PERMITIDO - Puede ver parques (SELECT directo)
-- Resultado esperado: lista de parques
PRINT '--- V.2: SELECT parques.Parque (PERMITIDO) ---';
EXECUTE AS USER = 'usr_ventas';
    SELECT TOP 3 idParque, nombre FROM parques.Parque WHERE activo = 1;
REVERT;
GO

-- TEST V.3: PERMITIDO - Puede ver tickets (SELECT directo)
-- Resultado esperado: lista de tickets
PRINT '--- V.3: SELECT ventas.Ticket (PERMITIDO) ---';
EXECUTE AS USER = 'usr_ventas';
    SELECT TOP 3 idTicket, nroTicket, total, estado FROM ventas.Ticket ORDER BY idTicket DESC;
REVERT;
GO

-- TEST V.4: PERMITIDO - Puede insertar visitante via SP
-- Resultado esperado: visitante creado
PRINT '--- V.4: sp_Visitante_Insertar (PERMITIDO) ---';
EXECUTE AS USER = 'usr_ventas';
    EXEC sp_Visitante_Insertar
        @idTipoVisitante = 1,
        @nombre          = 'Test',
        @apellido        = 'Permisos',
        @dniPasaporte    = 'TEST99999',
        @nacionalidad    = 'Argentina';
REVERT;
GO

-- TEST V.5: PERMITIDO - Puede anular ticket via SP
-- Resultado esperado: ticket anulado (si el idTicket existe y esta Emitido)
PRINT '--- V.5: sp_AnularTicket (PERMITIDO) ---';
EXECUTE AS USER = 'usr_ventas';
    -- Usamos el ultimo ticket emitido
    DECLARE @idUltimoTicket INT;
    SELECT TOP 1 @idUltimoTicket = idTicket
    FROM ventas.Ticket
    WHERE estado = 'Emitido'
    ORDER BY idTicket DESC;
    IF @idUltimoTicket IS NOT NULL
        EXEC sp_AnularTicket @idTicket = @idUltimoTicket;
    ELSE
        PRINT 'No hay tickets emitidos para anular';
REVERT;
GO

-- TEST V.6: DENEGADO - No puede hacer INSERT directo en ventas.Ticket
-- Resultado esperado: ERROR - The INSERT permission was denied
PRINT '--- V.6: INSERT directo en ventas.Ticket (DENEGADO) ---';
EXECUTE AS USER = 'usr_ventas';
BEGIN TRY
    INSERT INTO ventas.Ticket (idPuntoVenta, nroTicket, idFormaPago, fechaEmision, total, estado)
    VALUES (1, 9998, 1, GETDATE(), 0, 'Emitido');
    PRINT 'ERROR: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST V.7: DENEGADO - No puede hacer SELECT en atracciones
-- Resultado esperado: ERROR - The SELECT permission was denied
PRINT '--- V.7: SELECT atracciones.Atraccion (DENEGADO) ---';
EXECUTE AS USER = 'usr_ventas';
BEGIN TRY
    SELECT TOP 1 * FROM atracciones.Atraccion;
    PRINT 'ERROR: no deberia poder ver atracciones';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST V.8: DENEGADO - No puede ejecutar SPs de reportes
-- Resultado esperado: ERROR - EXECUTE permission denied
PRINT '--- V.8: sp_ReporteDeudores (DENEGADO) ---';
EXECUTE AS USER = 'usr_ventas';
BEGIN TRY
    EXEC sp_ReporteDeudores;
    PRINT 'ERROR: no deberia poder ejecutar reportes';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO


-- BLOQUE 2: usr_consulta


PRINT '=== TESTS usr_consulta (rol_consulta) ===';
GO

-- TEST C.1: PERMITIDO - Puede ejecutar reporte de visitantes
-- Resultado esperado: datos del reporte
PRINT '--- C.1: sp_ReporteVisitasPorPeriodo (PERMITIDO) ---';
EXECUTE AS USER = 'usr_consulta';
    EXEC sp_ReporteVisitasPorPeriodo
        @fechaDesde = '2026-01-01',
        @fechaHasta = '2026-12-31';
REVERT;
GO

-- TEST C.2: PERMITIDO - Puede ejecutar reporte de deudores
-- Resultado esperado: concesiones con pagos atrasados
PRINT '--- C.2: sp_ReporteDeudores (PERMITIDO) ---';
EXECUTE AS USER = 'usr_consulta';
    EXEC sp_ReporteDeudores;
REVERT;
GO

-- TEST C.3: PERMITIDO - Puede ejecutar matriz de visitas
-- Resultado esperado: tabla pivot de visitas por parque y mes
PRINT '--- C.3: sp_MatrizVisitas (PERMITIDO) ---';
EXECUTE AS USER = 'usr_consulta';
    EXEC sp_MatrizVisitas;
REVERT;
GO

-- TEST C.4: DENEGADO - No puede hacer SELECT directo sobre tablas
-- Resultado esperado: ERROR - The SELECT permission was denied
PRINT '--- C.4: SELECT ventas.Ticket (DENEGADO) ---';
EXECUTE AS USER = 'usr_consulta';
BEGIN TRY
    SELECT TOP 1 * FROM ventas.Ticket;
    PRINT 'ERROR: no deberia poder ver tickets directamente';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST C.5: DENEGADO - No puede insertar visitantes
-- Resultado esperado: ERROR - EXECUTE permission denied
PRINT '--- C.5: sp_Visitante_Insertar (DENEGADO) ---';
EXECUTE AS USER = 'usr_consulta';
BEGIN TRY
    EXEC sp_Visitante_Insertar
        @idTipoVisitante = 1,
        @nombre          = 'Test',
        @apellido        = 'Consulta',
        @dniPasaporte    = 'CONS99999',
        @nacionalidad    = 'Argentina';
    PRINT 'ERROR: no deberia poder insertar';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST C.6: DENEGADO - No puede ejecutar SPs de venta
-- Resultado esperado: ERROR - EXECUTE permission denied
PRINT '--- C.6: sp_AnularTicket (DENEGADO) ---';
EXECUTE AS USER = 'usr_consulta';
BEGIN TRY
    EXEC sp_AnularTicket @idTicket = 1;
    PRINT 'ERROR: no deberia poder anular tickets';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- BLOQUE 3: usr_importador


PRINT '=== TESTS usr_importador (rol_importador) ===';
GO

use ParquesNacionalesDB
-- TEST I.1: PERMITIDO - Puede ejecutar importacion WDPA
-- Resultado esperado: error de archivo no encontrado, NO error de permisos
PRINT '--- I.1: sp_ImportarWDPA (PERMITIDO - ejecuta el SP) ---';

BEGIN TRY
    EXEC sp_ImportarWDPA @rutaArchivo = 'C:\Datasets\WDPA.csv';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%Cannot bulk load%' OR ERROR_MESSAGE() LIKE '%no se pudo%'
        PRINT 'OK - SP ejecutado (falla por archivo ausente, no por permisos)';
    ELSE IF ERROR_MESSAGE() LIKE '%EXECUTE permission%'
        PRINT 'ERROR - Permiso de ejecucion denegado';
    ELSE
        PRINT 'SP ejecutado - Error: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST I.2: DENEGADO - No puede hacer SELECT directo sobre ventas
-- Resultado esperado: ERROR - The SELECT permission was denied
PRINT '--- I.2: SELECT ventas.Ticket (DENEGADO) ---';
EXECUTE AS USER = 'usr_importador';
BEGIN TRY
    SELECT TOP 1 * FROM ventas.Ticket;
    PRINT 'ERROR: no deberia poder ver tickets';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST I.3: DENEGADO - No puede ejecutar SPs de venta
-- Resultado esperado: ERROR - EXECUTE permission denied
PRINT '--- I.3: sp_AnularTicket (DENEGADO) ---';
EXECUTE AS USER = 'usr_importador';
BEGIN TRY
    EXEC sp_AnularTicket @idTicket = 1;
    PRINT 'ERROR: no deberia poder anular tickets';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST I.4: DENEGADO - No puede ejecutar SPs de reportes
-- Resultado esperado: ERROR - EXECUTE permission denied
PRINT '--- I.4: sp_ReporteDeudores (DENEGADO) ---';
EXECUTE AS USER = 'usr_importador';
BEGIN TRY
    EXEC sp_ReporteDeudores;
    PRINT 'ERROR: no deberia poder ver reportes';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- TEST I.5: DENEGADO - No puede borrar datos
-- Resultado esperado: ERROR - The DELETE permission was denied
PRINT '--- I.5: DELETE en parques.Parque (DENEGADO) ---';
EXECUTE AS USER = 'usr_importador';
BEGIN TRY
    DELETE FROM parques.Parque WHERE idParque = 9999;
    PRINT 'ERROR: no deberia poder borrar';
END TRY
BEGIN CATCH
    PRINT 'OK - Acceso denegado: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO


-- BLOQUE 4: usr_admin


PRINT '=== TESTS usr_admin (rol_admin) ===';
GO

-- TEST A.1: PERMITIDO - Puede hacer SELECT en cualquier tabla
-- Resultado esperado: datos de cada tabla
PRINT '--- A.1: SELECT en multiples schemas (PERMITIDO) ---';
EXECUTE AS USER = 'usr_admin';
    SELECT COUNT(*) AS tickets    FROM ventas.Ticket;
    SELECT COUNT(*) AS parques    FROM parques.Parque;
    SELECT COUNT(*) AS visitantes FROM ventas.Visitante;
    SELECT COUNT(*) AS logs       FROM importacion.ImportacionLog;
REVERT;
GO

-- TEST A.2: PERMITIDO - Puede ejecutar cualquier SP
-- Resultado esperado: reporte ejecutado correctamente
PRINT '--- A.2: sp_ReporteDeudores (PERMITIDO) ---';
EXECUTE AS USER = 'usr_admin';
    EXEC sp_ReporteDeudores;
REVERT;
GO

-- TEST A.3: PERMITIDO - Puede ejecutar SPs de importacion
-- Resultado esperado: SP ejecutado (falla por archivo, no por permisos)
PRINT '--- A.3: sp_ImportarWDPA (PERMITIDO) ---';
EXECUTE AS USER = 'usr_admin';
BEGIN TRY
    EXEC sp_ImportarWDPA @rutaArchivo = 'C:\Datasets\WDPA.csv';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%Cannot bulk load%' OR ERROR_MESSAGE() LIKE '%no se pudo%'
        PRINT 'OK - SP ejecutado (falla por archivo ausente, no por permisos)';
    ELSE
        PRINT 'SP ejecutado - Error: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- ============================================================
-- RESUMEN: permisos efectivos de todos los roles
-- ============================================================

PRINT '=== RESUMEN DE PERMISOS POR ROL ===';

SELECT
    dp.name           AS rol,
    p.permission_name AS permiso,
    p.state_desc      AS estado,
    ISNULL(o.name, s.name + ' (schema)') AS objeto
FROM sys.database_permissions p
JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
LEFT JOIN sys.objects o          ON o.object_id     = p.major_id
LEFT JOIN sys.schemas s          ON s.schema_id     = p.major_id
                                AND p.class = 3
WHERE dp.name IN ('rol_admin','rol_ventas','rol_consulta','rol_importador')
  AND p.state_desc IN ('GRANT', 'DENY')
ORDER BY dp.name, p.permission_name, objeto;
GO