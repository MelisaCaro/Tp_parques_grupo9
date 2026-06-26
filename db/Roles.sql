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

-- ============================================================
-- CREACION DE ROLES
-- ============================================================

CREATE ROLE rol_admin;
GO
CREATE ROLE rol_ventas;
GO
CREATE ROLE rol_consulta;
GO
CREATE ROLE rol_importador;
GO

/* rol_admin
puede ejecutar todos los SPs y acceder
directamente a todas las tablas.
*/

GRANT EXECUTE ON SCHEMA::maestros    TO rol_admin;
GRANT EXECUTE ON SCHEMA::parques     TO rol_admin;
GRANT EXECUTE ON SCHEMA::ventas      TO rol_admin;
GRANT EXECUTE ON SCHEMA::atracciones TO rol_admin;
GRANT EXECUTE ON SCHEMA::concesiones TO rol_admin;
GRANT EXECUTE ON SCHEMA::importacion TO rol_admin;

GRANT SELECT ON SCHEMA::maestros    TO rol_admin;
GRANT SELECT ON SCHEMA::parques     TO rol_admin;
GRANT SELECT ON SCHEMA::ventas      TO rol_admin;
GRANT SELECT ON SCHEMA::atracciones TO rol_admin;
GRANT SELECT ON SCHEMA::concesiones TO rol_admin;
GRANT SELECT ON SCHEMA::importacion TO rol_admin;
GO


/* rol_ventas
Puede registrar ventas de entradas, contratar tours
y consultar parques, precios y visitantes.
No puede acceder directamente a las tablas.
*/

-- SPs de negocio de ventas
GRANT EXECUTE ON sp_VentaEntradas         TO rol_ventas;
GRANT EXECUTE ON sp_ContratarActividad    TO rol_ventas;
GRANT EXECUTE ON sp_AsignarGuiaATour      TO rol_ventas;

-- SPs ABM necesarios para operar
GRANT EXECUTE ON sp_Visitante_Insertar    TO rol_ventas;
GRANT EXECUTE ON sp_Visitante_Actualizar  TO rol_ventas;
GRANT EXECUTE ON sp_PuntoVenta_Insertar   TO rol_ventas;
GRANT EXECUTE ON sp_PuntoVenta_Actualizar TO rol_ventas;

-- Denegar acceso directo a todas las tablas
DENY SELECT ON SCHEMA::ventas      TO rol_ventas;
DENY SELECT ON SCHEMA::maestros    TO rol_ventas;
DENY SELECT ON SCHEMA::parques     TO rol_ventas;
DENY SELECT ON SCHEMA::atracciones TO rol_ventas;
DENY SELECT ON SCHEMA::concesiones TO rol_ventas;
GO


/* rol_consulta
Solo puede ejecutar SPs de reportes.
No puede modificar datos ni acceder a tablas directamente.
*/

GRANT EXECUTE ON sp_ReporteVisitasPorPeriodo      TO rol_consulta;
GRANT EXECUTE ON sp_ReporteIngresosPorParqueXML   TO rol_consulta;
GRANT EXECUTE ON sp_ReporteDeudores               TO rol_consulta;
GRANT EXECUTE ON sp_MatrizVisitas                 TO rol_consulta;
GRANT EXECUTE ON sp_ReporteParquesYConcesionesXML TO rol_consulta;

DENY SELECT ON SCHEMA::ventas      TO rol_consulta;
DENY SELECT ON SCHEMA::maestros    TO rol_consulta;
DENY SELECT ON SCHEMA::parques     TO rol_consulta;
DENY SELECT ON SCHEMA::atracciones TO rol_consulta;
DENY SELECT ON SCHEMA::concesiones TO rol_consulta;
DENY SELECT ON SCHEMA::importacion TO rol_consulta;
GO


/*rol_importador
-- Solo puede ejecutar SPs de importacion de datasets.
-- No puede modificar datos del negocio ni ver reportes.
*/

GRANT EXECUTE ON sp_ImportarWDPA  TO rol_importador;
GRANT EXECUTE ON sp_Importar_APRN  TO rol_importador;

DENY SELECT ON SCHEMA::ventas      TO rol_importador;
DENY SELECT ON SCHEMA::maestros    TO rol_importador;
DENY SELECT ON SCHEMA::parques     TO rol_importador;
DENY SELECT ON SCHEMA::atracciones TO rol_importador;
DENY SELECT ON SCHEMA::concesiones TO rol_importador;
DENY SELECT ON SCHEMA::importacion TO rol_importador;
GO

/*
-- CREACION DE LOGINS Y USUARIOS
-- Un login por rol para demostrar la asignacion
*/

-- Login administrador
CREATE LOGIN usr_admin
    WITH PASSWORD      = 'Admin2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_admin FOR LOGIN usr_admin;
GO
ALTER ROLE rol_admin ADD MEMBER usr_admin;
GO

-- Login ventas
CREATE LOGIN usr_ventas
    WITH PASSWORD      = 'Ventas2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_ventas FOR LOGIN usr_ventas;
GO
ALTER ROLE rol_ventas ADD MEMBER usr_ventas;
GO

-- Login consulta
CREATE LOGIN usr_consulta
    WITH PASSWORD      = 'Consulta2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_consulta FOR LOGIN usr_consulta;
GO
ALTER ROLE rol_consulta ADD MEMBER usr_consulta;
GO

-- Login importador
CREATE LOGIN usr_importador
    WITH PASSWORD      = 'Import2026!',
         DEFAULT_DATABASE = ParquesNacionalesDB,
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = ON;
GO
CREATE USER usr_importador FOR LOGIN usr_importador;
GO
ALTER ROLE rol_importador ADD MEMBER usr_importador;
GO