/*
============================================================
  Descripcion: Creacion de roles de seguridad siguiendo el
               Principio del Minimo Privilegio (POLP).
               Roles definidos:
                 - rol_admin       : acceso total
                 - rol_ventas      : venta de entradas y tours
                 - rol_consulta    : solo lectura via SPs
                 - rol_importador  : importacion de datasets
               Ningun rol tiene acceso directo a las tablas.
               Todos operan exclusivamente a traves de SPs.
permisos:
  
  | Permiso          | admin    | ventas    | consulta  | importador    |

  | EXEC sp ABM      | SI       | parcial   | NO        | NO            |
  | EXEC sp negocio  | SI       | SI        | NO        | NO            |
  | EXEC sp reportes | SI       | NO        | SI        | NO            |
  | EXEC sp import   | SI       | NO        | NO        | SI            |
  | SELECT tablas    | SI       | NO        | NO        | NO            |
  | INSERT/UPDATE    | SI       | NO        | NO        | NO            |
 
============================================================
*/

USE ParquesNacionalesDB;
GO



-- CREACION DE ROLES


CREATE ROLE rol_admin;
GO
CREATE ROLE rol_ventas;
GO
CREATE ROLE rol_consulta;
GO
CREATE ROLE rol_importador;
GO


-- ROL: rol_admin
-- Acceso total: ejecuta todos los SPs y puede consultar
-- tablas directamente.


GRANT EXECUTE ON SCHEMA::maestros    TO rol_admin;
GRANT EXECUTE ON SCHEMA::parques     TO rol_admin;
GRANT EXECUTE ON SCHEMA::ventas      TO rol_admin;
GRANT EXECUTE ON SCHEMA::atracciones TO rol_admin;
GRANT EXECUTE ON SCHEMA::concesiones TO rol_admin;
GRANT EXECUTE ON SCHEMA::importacion TO rol_admin;
GRANT EXECUTE ON SCHEMA::dbo         TO rol_admin;

GRANT SELECT ON SCHEMA::maestros     TO rol_admin;
GRANT SELECT ON SCHEMA::parques      TO rol_admin;
GRANT SELECT ON SCHEMA::ventas       TO rol_admin;
GRANT SELECT ON SCHEMA::atracciones  TO rol_admin;
GRANT SELECT ON SCHEMA::concesiones  TO rol_admin;
GRANT SELECT ON SCHEMA::importacion  TO rol_admin;
GO


-- ROL: rol_ventas
-- Ejecuta SPs de logica de negocio y ABM de visitantes
-- y puntos de venta. No accede directamente a tablas.


-- SPs de logica de negocio (estan en dbo)
GRANT EXECUTE ON OBJECT::dbo.sp_VentaEntradas         TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_ContratarActividad    TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_AsignarGuiaATour      TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_AnularTicket          TO rol_ventas;

-- SPs ABM necesarios para operar
GRANT EXECUTE ON OBJECT::dbo.sp_Visitante_Insertar    TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_Visitante_Actualizar  TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_PuntoVenta_Insertar   TO rol_ventas;
GRANT EXECUTE ON OBJECT::dbo.sp_PuntoVenta_Actualizar TO rol_ventas;

-- Denegar DML directo (DENY es correcto aqui: nunca debe
-- hacerse INSERT/UPDATE/DELETE directo sobre las tablas)
DENY INSERT ON SCHEMA::ventas      TO rol_ventas;
DENY INSERT ON SCHEMA::maestros    TO rol_ventas;
DENY INSERT ON SCHEMA::parques     TO rol_ventas;
DENY INSERT ON SCHEMA::atracciones TO rol_ventas;
DENY INSERT ON SCHEMA::concesiones TO rol_ventas;

DENY UPDATE ON SCHEMA::ventas      TO rol_ventas;
DENY UPDATE ON SCHEMA::maestros    TO rol_ventas;
DENY UPDATE ON SCHEMA::parques     TO rol_ventas;
DENY UPDATE ON SCHEMA::atracciones TO rol_ventas;
DENY UPDATE ON SCHEMA::concesiones TO rol_ventas;

DENY DELETE ON SCHEMA::ventas      TO rol_ventas;
DENY DELETE ON SCHEMA::maestros    TO rol_ventas;
DENY DELETE ON SCHEMA::parques     TO rol_ventas;
DENY DELETE ON SCHEMA::atracciones TO rol_ventas;
DENY DELETE ON SCHEMA::concesiones TO rol_ventas;

-- SELECT directo: no se otorga (REVOKE implicito).
GO


-- ROL: rol_consulta
-- Solo ejecuta SPs de reportes. No modifica datos
-- ni accede directamente a tablas.


GRANT EXECUTE ON OBJECT::dbo.sp_ReporteVisitasPorPeriodo      TO rol_consulta;
GRANT EXECUTE ON OBJECT::dbo.sp_ReporteIngresosPorParqueXML   TO rol_consulta;
GRANT EXECUTE ON OBJECT::dbo.sp_ReporteDeudores               TO rol_consulta;
GRANT EXECUTE ON OBJECT::dbo.sp_MatrizVisitas                 TO rol_consulta;
GRANT EXECUTE ON OBJECT::dbo.sp_ReporteParquesYConcesionesXML TO rol_consulta;

DENY INSERT ON SCHEMA::ventas      TO rol_consulta;
DENY INSERT ON SCHEMA::maestros    TO rol_consulta;
DENY INSERT ON SCHEMA::parques     TO rol_consulta;
DENY INSERT ON SCHEMA::atracciones TO rol_consulta;
DENY INSERT ON SCHEMA::concesiones TO rol_consulta;
DENY INSERT ON SCHEMA::importacion TO rol_consulta;

DENY UPDATE ON SCHEMA::ventas      TO rol_consulta;
DENY UPDATE ON SCHEMA::maestros    TO rol_consulta;
DENY UPDATE ON SCHEMA::parques     TO rol_consulta;
DENY UPDATE ON SCHEMA::atracciones TO rol_consulta;
DENY UPDATE ON SCHEMA::concesiones TO rol_consulta;
DENY UPDATE ON SCHEMA::importacion TO rol_consulta;

DENY DELETE ON SCHEMA::ventas      TO rol_consulta;
DENY DELETE ON SCHEMA::maestros    TO rol_consulta;
DENY DELETE ON SCHEMA::parques     TO rol_consulta;
DENY DELETE ON SCHEMA::atracciones TO rol_consulta;
DENY DELETE ON SCHEMA::concesiones TO rol_consulta;
DENY DELETE ON SCHEMA::importacion TO rol_consulta;

-- SELECT directo: no se otorga (sin DENY para no romper SPs)
GO


-- ROL: rol_importador
-- Solo ejecuta SPs de importacion masiva.
-- Sin DENY en maestros, parques ni importacion porque los
-- SPs de importacion hacen upsert en esos schemas internamente.


GRANT EXECUTE ON OBJECT::dbo.sp_ImportarWDPA   TO rol_importador;
GRANT EXECUTE ON OBJECT::dbo.sp_Importar_APRN  TO rol_importador;

DENY INSERT ON SCHEMA::ventas      TO rol_importador;
DENY INSERT ON SCHEMA::atracciones TO rol_importador;
DENY INSERT ON SCHEMA::concesiones TO rol_importador;

DENY UPDATE ON SCHEMA::ventas      TO rol_importador;
DENY UPDATE ON SCHEMA::atracciones TO rol_importador;
DENY UPDATE ON SCHEMA::concesiones TO rol_importador;

DENY DELETE ON SCHEMA::ventas      TO rol_importador;
DENY DELETE ON SCHEMA::maestros    TO rol_importador;
DENY DELETE ON SCHEMA::parques     TO rol_importador;
DENY DELETE ON SCHEMA::atracciones TO rol_importador;
DENY DELETE ON SCHEMA::concesiones TO rol_importador;
DENY DELETE ON SCHEMA::importacion TO rol_importador;

-- SELECT e INSERT/UPDATE en maestros, parques e importacion:
-- no se otorga ni deniega (los SPs los necesitan internamente)
GO


-- CREACION DE LOGINS Y USUARIOS

CREATE LOGIN usr_admin
    WITH PASSWORD        = 'Admin2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_admin FOR LOGIN usr_admin;
GO
ALTER ROLE rol_admin ADD MEMBER usr_admin;
GO

CREATE LOGIN usr_ventas
    WITH PASSWORD        = 'Ventas2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_ventas FOR LOGIN usr_ventas;
GO
ALTER ROLE rol_ventas ADD MEMBER usr_ventas;
GO

CREATE LOGIN usr_consulta
    WITH PASSWORD        = 'Consulta2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_consulta FOR LOGIN usr_consulta;
GO
ALTER ROLE rol_consulta ADD MEMBER usr_consulta;
GO

CREATE LOGIN usr_importador
    WITH PASSWORD        = 'Import2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_importador FOR LOGIN usr_importador;
GO
ALTER ROLE rol_importador ADD MEMBER usr_importador;
GO

-- VERIFICACION: permisos efectivos por rol

SELECT
    dp.name             AS rol,
    o.name              AS sp_nombre,
    p.permission_name   AS permiso,
    p.state_desc        AS estado
FROM sys.database_permissions p
JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
LEFT JOIN sys.objects o         ON o.object_id      = p.major_id
WHERE dp.name IN ('rol_admin','rol_ventas','rol_consulta','rol_importador')
ORDER BY dp.name, p.permission_name, o.name;
GO





 
SELECT
    s.name  AS schema_nombre,
    o.name  AS sp_nombre,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type = 'P'
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name;
-- Resultado esperado: ninguna fila con schema_nombre = 'dbo'
-- Todos los SPs deben aparecer bajo maestros, parques, ventas,
-- atracciones, concesiones, importacion o negocio.
GO

