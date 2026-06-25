/*
============================================================
  Universidad: Universidad Nacional de la Matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri Villalba, Santino; Llanos, Franco; Vazquez, Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Script de importacion del dataset WDPA
               (World Database on Protected Areas).
               Importa areas protegidas de Argentina (ISO3 = 'ARG')
               desde un archivo CSV hacia las tablas:
                 - maestros.TipoParque
                 - parques.Parque
               Implementa logica de Upsert: inserta si no existe,
               actualiza si ya existe. Registra el proceso en
               importacion.ImportacionLog.
               IMPORTANTE: Cambiar @rutaArchivo por la ruta
               real del archivo en su equipo antes de ejecutar.
============================================================
*/
 
USE ParquesNacionalesDB;
GO
 
-- ============================================================
-- SP: sp_ImportarWDPA
-- Descripcion: Lee el archivo WDPA.csv, filtra registros de
--   Argentina (ISO3 = ARG), hace upsert en TipoParque y Parque,
--   y registra el resultado en ImportacionLog.
--
-- Parametros:
--   @rutaArchivo : ruta completa al archivo CSV en el servidor
--                  Ejemplo: 'C:\Datasets\WDPA.csv'
-- ============================================================
 
CREATE PROCEDURE sp_ImportarWDPA
    @rutaArchivo VARCHAR(500) = 'C:\Datasets\WDPA.csv'
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Variables de control
    DECLARE @idImportacion    INT;
    DECLARE @procesados       INT = 0;
    DECLARE @ok               INT = 0;
    DECLARE @errores          INT = 0;
    DECLARE @estadoFinal      VARCHAR(50);
    DECLARE @sql              VARCHAR(MAX);
 
    -- ============================================================
    -- 1. Abrir registro en el log
    -- ============================================================
    INSERT INTO importacion.ImportacionLog
        (idParque, fuente, formato, fechaEjecucion, registrosProcesados,
         registrosOk, registrosError, estado)
    VALUES
        (NULL, @rutaArchivo, 'CSV', GETDATE(), 0, 0, 0, 'EnProceso');
 
    SET @idImportacion = SCOPE_IDENTITY();
 
    -- ============================================================
    -- 2. Crear tabla temporal para cargar el CSV completo
    -- ============================================================
    IF OBJECT_ID('tempdb..#WDPA_Raw') IS NOT NULL
        DROP TABLE #WDPA_Raw;
 
    CREATE TABLE #WDPA_Raw (
        TYPE         VARCHAR(MAX)   NULL,
        SITE_ID      VARCHAR(MAX)   NULL,
        SITE_PID     VARCHAR(MAX)   NULL,
        SITE_TYPE    VARCHAR(MAX)   NULL,
        NAME_ENG     VARCHAR(MAX)  NULL,
        NAME         VARCHAR(MAX)  NULL,
        DESIG        VARCHAR(MAX)  NULL,
        DESIG_ENG    VARCHAR(MAX)  NULL,
        DESIG_TYPE   VARCHAR(MAX)  NULL,
        IUCN_CAT     VARCHAR(MAX)   NULL,
        INT_CRIT     VARCHAR(MAX)  NULL,
        REALM        VARCHAR(MAX)  NULL,
        REP_M_AREA   VARCHAR(MAX)   NULL,
        GIS_M_AREA   VARCHAR(MAX)   NULL,
        REP_AREA     VARCHAR(MAX)   NULL,
        GIS_AREA     VARCHAR(MAX)   NULL,
        NO_TAKE      VARCHAR(MAX)  NULL,
        NO_TK_AREA   VARCHAR(MAX)   NULL,
        STATUS       VARCHAR(MAX)  NULL,
        STATUS_YR    VARCHAR(MAX)   NULL,
        GOV_TYPE     VARCHAR(MAX)  NULL,
        GOVSUBTYPE   VARCHAR(MAX)  NULL,
        OWN_TYPE     VARCHAR(MAX)  NULL,
        OWNSUBTYPE   VARCHAR(MAX)  NULL,
        MANG_AUTH    VARCHAR(MAX)  NULL,
        MANG_PLAN    VARCHAR(MAX)  NULL,
        VERIF        VARCHAR(MAX)  NULL,
        METADATAID   VARCHAR(MAX)   NULL,
        PRNT_ISO3    VARCHAR(MAX)   NULL,
        ISO3         VARCHAR(MAX)   NULL,
        SUPP_INFO    VARCHAR(MAX)  NULL,
        CONS_OBJ     VARCHAR(MAX)  NULL,
        INLND_WTRS   VARCHAR(MAX)  NULL,
        OECM_ASMT   VARCHAR(MAX)  NULL
    );
 
    -- ============================================================
    -- 3. Cargar el CSV en la tabla temporal
    -- ============================================================
    BEGIN TRY
        DECLARE @bulkSQL NVARCHAR(MAX);
        SET @bulkSQL = N'
            BULK INSERT #WDPA_Raw
            FROM ''' + @rutaArchivo + '''
            WITH (
                FIRSTROW        = 2,
                   FIELDTERMINATOR = '','',
                    ROWTERMINATOR = ''0x0a'',
                    FIELDQUOTE      = ''"'',
                    CODEPAGE = ''65001'',
                    TABLOCK,
                    MAXERRORS       = 1000
                );';
    PRINT @bulkSQL;
        EXEC sp_executesql @bulkSQL;
 
    END TRY
    BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_LINE() AS ErrorLine;

    THROW;
END CATCH
 
    -- ============================================================
    -- 4. Filtrar solo registros de Argentina con datos validos
    -- ============================================================
    IF OBJECT_ID('tempdb..#WDPA_ARG') IS NOT NULL
        DROP TABLE #WDPA_ARG;
 
    SELECT
        LTRIM(RTRIM(SITE_ID))    AS SITE_ID,
        LTRIM(RTRIM(NAME))       AS nombre,
        LTRIM(RTRIM(DESIG_ENG))  AS tipoParque,
        LTRIM(RTRIM(ISO3))       AS pais,
        -- Convertir GIS_AREA de km2 a hectareas (* 100)
        CASE
            WHEN ISNULL(LTRIM(RTRIM(GIS_AREA)), '') = ''
              OR LTRIM(RTRIM(GIS_AREA)) = 'Not Applicable'
            THEN NULL
            ELSE TRY_CAST(LTRIM(RTRIM(GIS_AREA)) AS DECIMAL(12,2)) * 100
        END AS superficieHa,
        LTRIM(RTRIM(STATUS_YR))  AS anioDesignacion
    INTO #WDPA_ARG
    FROM #WDPA_Raw
    WHERE LTRIM(RTRIM(ISO3)) = 'ARG'
      AND NULLIF(LTRIM(RTRIM(NAME)), '') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(SITE_ID)), '') IS NOT NULL;
 
    -- ============================================================
    -- 5. Procesar cada registro con Upsert
    -- ============================================================
    DECLARE
        @siteid          VARCHAR(20),
        @nombre          VARCHAR(200),
        @tipoParque      VARCHAR(300),
        @superficieHa    DECIMAL(12,2),
        @anio            VARCHAR(10),
        @idTipoParque    INT,
        @idParque        INT,
        @ubicacion       VARCHAR(300);
 
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT SITE_ID, nombre, tipoParque, superficieHa, anioDesignacion
        FROM #WDPA_ARG;
 
    OPEN cur;
    FETCH NEXT FROM cur INTO @siteid, @nombre, @tipoParque, @superficieHa, @anio;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @procesados += 1;
        SET @idParque = NULL;      
        SET @idTipoParque = NULL; 
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            -- Truncar nombre a 200 caracteres si es muy largo
            IF LEN(@nombre) > 200
                SET @nombre = LEFT(@nombre, 200);
 
            -- Truncar tipo a 100 caracteres si es muy largo
            IF LEN(@tipoParque) > 100
                SET @tipoParque = LEFT(@tipoParque, 100);
 
            SET @ubicacion = 'Argentina';
 
            -- ---- Upsert TipoParque ----
            SELECT @idTipoParque = idTipoParque
            FROM maestros.TipoParque
            WHERE nombre = @tipoParque;
 
            IF @idTipoParque IS NULL
            BEGIN
                INSERT INTO maestros.TipoParque (nombre, descripcion)
                VALUES (@tipoParque, 'Importado desde WDPA');
                SET @idTipoParque = SCOPE_IDENTITY();
            END
 
            -- ---- Upsert Parque ----
            -- Buscamos por nombre y tipo para identificar duplicados
            SELECT @idParque = idParque
            FROM parques.Parque
            WHERE nombre = @nombre AND idTipoParque = @idTipoParque;
 
            IF @idParque IS NULL
            BEGIN
                -- No existe: INSERT
                INSERT INTO parques.Parque
                    (idTipoParque, nombre, ubicacion, superficieHa, descripcion, activo)
                VALUES
                    (@idTipoParque, @nombre, @ubicacion, @superficieHa,
                     'Importado desde WDPA. SITE_ID: ' + @siteid, 1);
            END
            ELSE
            BEGIN
                -- Ya existe: UPDATE solo si hay datos nuevos
                UPDATE parques.Parque
                SET superficieHa = ISNULL(@superficieHa, superficieHa),
                    ubicacion    = @ubicacion
                WHERE idParque = @idParque;
            END
 
            COMMIT TRANSACTION;
            SET @ok += 1;
 
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @errores += 1;
            -- Continua con el siguiente registro
        END CATCH
 
        FETCH NEXT FROM cur INTO @siteid, @nombre, @tipoParque, @superficieHa, @anio;
    END
 
    CLOSE cur;
    DEALLOCATE cur;
 
    -- ============================================================
    -- 6. Limpiar tablas temporales
    -- ============================================================
    DROP TABLE #WDPA_Raw;
    DROP TABLE #WDPA_ARG;
 
    -- ============================================================
    -- 7. Cerrar el log con los resultados
    -- ============================================================
    IF @errores = 0
        SET @estadoFinal = 'Completado';
    ELSE IF @ok > 0
        SET @estadoFinal = 'CompletadoConErrores';
    ELSE
        SET @estadoFinal = 'Fallido';
 
    UPDATE importacion.ImportacionLog
    SET registrosProcesados = @procesados,
        registrosOk         = @ok,
        registrosError      = @errores,
        estado              = @estadoFinal
    WHERE idImportacion = @idImportacion;
 
    -- ============================================================
    -- 8. Mostrar resumen
    -- ============================================================
    SELECT
        @idImportacion AS idImportacion,
        @procesados    AS registrosProcesados,
        @ok            AS registrosOk,
        @errores       AS registrosError,
        @estadoFinal   AS estado;
 
END
GO
 
-- ============================================================
-- Para ejecutar la importacion:
-- Cambiar la ruta por donde tengan guardado el archivo WDPA.csv
-- ============================================================
--EXEC sp_ImportarWDPA @rutaArchivo = 'C:\Datasets\WDPA.csv';