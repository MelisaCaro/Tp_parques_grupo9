/*
============================================================
  Descripcion: Cifrado de datos sensibles mediante
               EncryptByPassPhrase sobre columnas de DNI
               y CUIT en las tablas del sistema.
               Datos sensibles:
                 - ventas.Visitante.dniPasaporte
                 - concesiones.Concesionario.cuit
                 - parques.Guardaparque.dni
                 - atracciones.GuiaAutorizado.dni
               El cifrado agrega una columna VARBINARY por
               cada campo sensible y cifra los datos existentes.
               La columna original se mantiene por
               compatibilidad con SPs existentes
============================================================
*/

USE ParquesNacionalesDB;
GO


-- ventas.Visitante — cifrado de dniPasaporte

ALTER TABLE ventas.Visitante
ADD dniPasaporteCifrado VARBINARY(256) NULL;
GO

DECLARE @fraseClave NVARCHAR(128) = '@ParquesNac2026!';

UPDATE ventas.Visitante
SET dniPasaporteCifrado = EncryptByPassPhrase(
    @fraseClave,
    dniPasaporte,
    1,
    CONVERT(VARBINARY, idVisitante)
);
GO

-- concesiones.Concesionario — cifrado de cuit


ALTER TABLE concesiones.Concesionario
ADD cuitCifrado VARBINARY(256) NULL;
GO

DECLARE @fraseClave NVARCHAR(128) = '@ParquesNac2026!';

UPDATE concesiones.Concesionario
SET cuitCifrado = EncryptByPassPhrase(
    @fraseClave,
    cuit,
    1,
    CONVERT(VARBINARY, idConcesionario)
);
GO


-- parques.Guardaparque — cifrado de dni


ALTER TABLE parques.Guardaparque
ADD dniCifrado VARBINARY(256) NULL;
GO

DECLARE @fraseClave NVARCHAR(128) = '@ParquesNac2026!';

UPDATE parques.Guardaparque
SET dniCifrado = EncryptByPassPhrase(
    @fraseClave,
    dni,
    1,
    CONVERT(VARBINARY, idGuardaparque)
);
GO


-- atracciones.GuiaAutorizado — cifrado de dni


ALTER TABLE atracciones.GuiaAutorizado
ADD dniCifrado VARBINARY(256) NULL;
GO

DECLARE @fraseClave NVARCHAR(128) = '@ParquesNac2026!';

UPDATE atracciones.GuiaAutorizado
SET dniCifrado = EncryptByPassPhrase(
    @fraseClave,
    dni,
    1,
    CONVERT(VARBINARY, idGuia)
);
GO

-- ============================================================
-- VERIFICACION
-- Ejecutar para confirmar que el cifrado funciono
-- dniOriginal debe ser igual a dniDescifrado
-- ============================================================

/*
DECLARE @fraseClave NVARCHAR(128) = '@ParquesNac2026!';

-- Verificar Visitantes
SELECT
    idVisitante,
    dniPasaporte AS dniOriginal,
    CONVERT(VARCHAR(30), DecryptByPassPhrase(
        @fraseClave, dniPasaporteCifrado, 1, CONVERT(VARBINARY, idVisitante)
    )) AS dniDescifrado
FROM ventas.Visitante;
select *
from ventas.Visitante
-- Verificar Guardaparques
SELECT
    idGuardaparque,
    dni AS dniOriginal,
    CONVERT(VARCHAR(20), DecryptByPassPhrase(
        @fraseClave, dniCifrado, 1, CONVERT(VARBINARY, idGuardaparque)
    )) AS dniDescifrado
FROM parques.Guardaparque;

-- Verificar Guias
SELECT
    idGuia,
    dni AS dniOriginal,
    CONVERT(VARCHAR(20), DecryptByPassPhrase(
        @fraseClave, dniCifrado, 1, CONVERT(VARBINARY, idGuia)
    )) AS dniDescifrado
FROM atracciones.GuiaAutorizado;

-- Verificar Concesionarios
SELECT
    idConcesionario,
    cuit AS cuitOriginal,
    CONVERT(VARCHAR(13), DecryptByPassPhrase(
        @fraseClave, cuitCifrado, 1, CONVERT(VARBINARY, idConcesionario)
    )) AS cuitDescifrado
FROM concesiones.Concesionario;
*/