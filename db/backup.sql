/*
============================================================
  Descripcion: Scripts de backup para ParquesNacionalesDB.

  MODELO DE RECUPERACION: FULL
  SQL Server Express soporta backup de log de transacciones
  siempre que el modelo sea FULL (no SIMPLE).
  La unica limitacion de Express es que no tiene SQL Agent
  para automatizar, por lo que se usa el Programador de
  Tareas de Windows con sqlcmd.

  ESTRATEGIA:
    - FULL    : domingos 02:00
    - DIFERENCIAL: lunes a sabado 02:00
    - LOG     : cada 4 horas durante horario operativo

  RPO: 4 horas (maximo datos perdidos entre backups de log)
  RTO: estimado 2 horas (FULL + DIFERENCIAL + logs)

  Almacenamiento: C:\SQLBackup\PARQUES_NAC\ (local)
============================================================
*/

USE master;
GO


-- PASO 1: Cambiar modelo de recuperacion a FULL

ALTER DATABASE ParquesNacionalesDB
SET RECOVERY FULL;
GO

/*PASO 2: BACKUP COMPLETO (FULL)
Ejecutar los domingos a las 02:00
Obligatorio antes de poder hacer backup de log*/


BACKUP DATABASE ParquesNacionalesDB
TO DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_FULL.bak'
WITH
    NAME        = 'ParquesNacionales - Backup Completo',
    DESCRIPTION = 'Backup semanal completo - domingos 02:00',
 
    STATS = 10;
GO


/*PASO 3: BACKUP DIFERENCIAL
Ejecutar de lunes a sabado a las 02:00
Solo incluye cambios desde el ultimo FULL*/

BACKUP DATABASE ParquesNacionalesDB
TO DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_DIFF.bak'
WITH
    DIFFERENTIAL,
    NAME        = 'ParquesNacionales - Backup Diferencial',
    DESCRIPTION = 'Backup diferencial diario - lunes a sabado 02:00',

    STATS = 10;
GO


/*PASO 4: BACKUP DE LOG DE TRANSACCIONES
Ejecutar cada 4 horas durante horario operativo
Requiere que el modelo sea FULL y que exista un FULL previo
*/

BACKUP LOG ParquesNacionalesDB
TO DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_LOG.bak'
WITH
    NAME        = 'ParquesNacionales - Backup Log',
    DESCRIPTION = 'Backup de log cada 4 horas',
    STATS = 10;
GO


/* RESTAURACION COMPLETA
Orden obligatorio: FULL -> DIFF -> cada LOG -> ultimo LOG */


/*
USE master;
GO

-- Paso 1: Restaurar FULL
RESTORE DATABASE ParquesNacionalesDB
FROM DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_FULL.bak'
WITH
    NORECOVERY,
    REPLACE,
    MOVE 'ParquesNacionales_data' TO 'C:\SQLData\PARQUES_NAC\ParquesNacionales.mdf',
    MOVE 'ParquesNacionales_log'  TO 'C:\SQLLogs\PARQUES_NAC\ParquesNacionales.ldf',
    STATS = 10;
GO

-- Paso 2: Aplicar DIFERENCIAL
RESTORE DATABASE ParquesNacionalesDB
FROM DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_DIFF.bak'
WITH NORECOVERY, STATS = 10;
GO

-- Paso 3: Aplicar backups de LOG en orden cronologico
RESTORE LOG ParquesNacionalesDB
FROM DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_LOG.bak'
WITH NORECOVERY, STATS = 10;
GO

-- Paso 4: Ultimo LOG con RECOVERY — deja la DB lista
RESTORE LOG ParquesNacionalesDB
FROM DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_LOG.bak'
WITH RECOVERY, STATS = 10;
GO
*/

/* VERIFICACION
-- Ejecutar para confirmar integridad*/

RESTORE VERIFYONLY
FROM DISK = 'C:\SQLBackup\PARQUES_NAC\ParquesNacionales_FULL.bak';
GO