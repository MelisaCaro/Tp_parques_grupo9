/*
  Descripcion: SP de importacion del dataset GeoJSON de Areas
               Protegidas de Argentina provisto por el IGN
               (Instituto Geografico Nacional).
               Fuente: https://www.ign.gob.ar/
               Formato: GeoJSON
               Lee el archivo con OPENROWSET(BULK),
               parsea el JSON con OPENJSON y calcula el
               centroide de cada poligono para obtener
               latitud y longitud.
               Implementa logica de Upsert: inserta si no
               existe, actualiza si ya existe.
               Registra el proceso en importacion.ImportacionLog.
============================================================
*/

USE ParquesNacionalesDB;
GO
/*
-- Habilitar Ad Hoc Distributed Queries para OPENROWSET
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1; RECONFIGURE;
GO
*/



IF OBJECT_ID('dbo.sp_ImportarGeoJSONAreasProtegidas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ImportarGeoJSONAreasProtegidas;
GO
 
CREATE PROCEDURE sp_ImportarGeoJSONAreasProtegidas
    @rutaArchivo VARCHAR(500) = 'C:\Datasets\area_protegida.geojson'
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @idImportacion  INT;
    DECLARE @procesados     INT = 0;
    DECLARE @ok             INT = 0;
    DECLARE @errores        INT = 0;
    DECLARE @estadoFinal    VARCHAR(50);
    DECLARE @jsonContent    NVARCHAR(MAX);
    DECLARE @sql            NVARCHAR(MAX);
 

    -- 1. Abrir registro en el log

    INSERT INTO importacion.ImportacionLog
        (idParque, fuente, formato, fechaEjecucion,
         registrosProcesados, registrosOk, registrosError, estado)
    VALUES
        (NULL, @rutaArchivo, 'GeoJSON', GETDATE(), 0, 0, 0, 'EnProceso');
 
    SET @idImportacion = SCOPE_IDENTITY();
 
 
    -- 2. Leer el archivo GeoJSON completo con OPENROWSET

    BEGIN TRY
        SET @sql = N'
            SELECT @json = CONVERT(NVARCHAR(MAX), BulkColumn)
            FROM OPENROWSET(BULK ''' + @rutaArchivo + ''',
                SINGLE_CLOB
            ) AS j';
 
        EXEC sp_executesql @sql, N'@json NVARCHAR(MAX) OUTPUT', @json = @jsonContent OUTPUT;
 
        -- Corregir encoding UTF-8 mal interpretado (caracteres latinos)
        SET @jsonContent = REPLACE(@jsonContent, 'Ã¡', 'á');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã©', 'é');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã­', 'í');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã³', 'ó');
        SET @jsonContent = REPLACE(@jsonContent, 'Ãº', 'ú');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã±', 'ñ');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã', 'Á');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã‰', 'É');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã"', 'Ó');
        SET @jsonContent = REPLACE(@jsonContent, 'Ãœ', 'Ü');
        SET @jsonContent = REPLACE(@jsonContent, 'Â¡', '¡');
        SET @jsonContent = REPLACE(@jsonContent, 'Â°', '°');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã¼', 'ü');
        SET @jsonContent = REPLACE(@jsonContent, 'â€™', '''');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã‡', 'Ç');
        SET @jsonContent = REPLACE(@jsonContent, 'Ã§', 'ç');
    END TRY
    BEGIN CATCH
        UPDATE importacion.ImportacionLog
        SET estado = 'Fallido',
            registrosProcesados = 0,
            registrosOk = 0,
            registrosError = 0
        WHERE idImportacion = @idImportacion;
 
        THROW;
    END CATCH
 
  
    -- 3. Parsear features del GeoJSON con OPENJSON
    --    Extraer: nombre (fna), coordenadas del primer anillo
    --    del primer poligono para calcular el centroide.

    IF OBJECT_ID('tempdb..#AreasRaw') IS NOT NULL
        DROP TABLE #AreasRaw;
 
    CREATE TABLE #AreasRaw (
        nombre      NVARCHAR(500),
        nombreCorto NVARCHAR(300),
        tipoArea    NVARCHAR(200),
        coordsJSON  NVARCHAR(MAX)
    );
 
    INSERT INTO #AreasRaw (nombre, nombreCorto, tipoArea, coordsJSON)
    SELECT
        JSON_VALUE(feature.value, '$.properties.fna')   AS nombre,
        JSON_VALUE(feature.value, '$.properties.nam')   AS nombreCorto,
        JSON_VALUE(feature.value, '$.properties.objeto') AS tipoArea,
        -- Primer anillo del primer poligono para calcular centroide
        JSON_QUERY(feature.value, '$.geometry.coordinates[0][0]') AS coordsJSON
    FROM OPENJSON(@jsonContent, '$.features') AS feature
    WHERE JSON_VALUE(feature.value, '$.properties.fna') IS NOT NULL
      AND JSON_VALUE(feature.value, '$.geometry.type') IN ('Polygon', 'MultiPolygon');
 

    -- 4. Calcular centroide y hacer Upsert en parques.Parque

    DECLARE
        @nombre         NVARCHAR(500),
        @nombreCorto    NVARCHAR(300),
        @tipoArea       NVARCHAR(200),
        @coordsJSON     NVARCHAR(MAX),
        @latitud        DECIMAL(9,6),
        @longitud       DECIMAL(9,6),
        @idTipoParque   INT,
        @idParque       INT,
        @sumLat         FLOAT,
        @sumLon         FLOAT,
        @cntCoords      INT;
 
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT nombre, nombreCorto, tipoArea, coordsJSON
        FROM #AreasRaw;
 
    OPEN cur;
    FETCH NEXT FROM cur INTO @nombre, @nombreCorto, @tipoArea, @coordsJSON;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @procesados += 1;
        SET @idParque     = NULL;
        SET @idTipoParque = NULL;
        SET @latitud      = NULL;
        SET @longitud     = NULL;
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            -- Truncar nombre si es muy largo
            IF LEN(@nombre) > 200
                SET @nombre = LEFT(@nombre, 200);
 
            -- Calcular centroide promediando las coordenadas del anillo
            IF @coordsJSON IS NOT NULL
            BEGIN
                SELECT
                    @sumLat   = AVG(CAST(JSON_VALUE(coord.value, '$[1]') AS FLOAT)),
                    @sumLon   = AVG(CAST(JSON_VALUE(coord.value, '$[0]') AS FLOAT)),
                    @cntCoords = COUNT(*)
                FROM OPENJSON(@coordsJSON) AS coord
                WHERE JSON_VALUE(coord.value, '$[0]') IS NOT NULL
                  AND JSON_VALUE(coord.value, '$[1]') IS NOT NULL
                  AND TRY_CAST(JSON_VALUE(coord.value, '$[0]') AS FLOAT) IS NOT NULL
                  AND TRY_CAST(JSON_VALUE(coord.value, '$[1]') AS FLOAT) IS NOT NULL;
 
                IF @cntCoords > 0
                BEGIN
                    SET @latitud  = CAST(@sumLat AS DECIMAL(9,6));
                    SET @longitud = CAST(@sumLon AS DECIMAL(9,6));
                END
            END
 
            -- Upsert TipoParque
            SELECT @idTipoParque = idTipoParque
            FROM maestros.TipoParque
            WHERE nombre = ISNULL(@tipoArea, 'Area Protegida');
 
            IF @idTipoParque IS NULL
            BEGIN
                INSERT INTO maestros.TipoParque (nombre, descripcion)
                VALUES (ISNULL(@tipoArea, 'Area Protegida'), 'Importado desde IGN GeoJSON');
                SET @idTipoParque = SCOPE_IDENTITY();
            END
 
            -- Upsert Parque
            SELECT @idParque = idParque
            FROM parques.Parque
            WHERE nombre = @nombre;
 
            IF @idParque IS NULL
            BEGIN
                INSERT INTO parques.Parque
                    (idTipoParque, nombre, ubicacion, superficieHa,
                     descripcion, activo, latitud, longitud)
                VALUES
                    (@idTipoParque, @nombre, 'Argentina', NULL,
                     'Importado desde IGN GeoJSON. Nombre corto: ' + ISNULL(@nombreCorto, ''),
                     1, @latitud, @longitud);
            END
            ELSE
            BEGIN
                UPDATE parques.Parque
                SET latitud      = ISNULL(@latitud, latitud),
                    longitud     = ISNULL(@longitud, longitud),
                    idTipoParque = @idTipoParque
                WHERE idParque = @idParque;
            END
 
            COMMIT TRANSACTION;
            SET @ok += 1;
 
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @errores += 1;
        END CATCH
 
        FETCH NEXT FROM cur INTO @nombre, @nombreCorto, @tipoArea, @coordsJSON;
    END
 
    CLOSE cur;
    DEALLOCATE cur;
 
    DROP TABLE #AreasRaw;
 
    -- 5. Cerrar el log

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
 
    SELECT
        @idImportacion AS idImportacion,
        @procesados    AS registrosProcesados,
        @ok            AS registrosOk,
        @errores       AS registrosError,
        @estadoFinal   AS estado;
END
GO
 

-- Para ejecutar:
/*EXEC sp_ImportarGeoJSONAreasProtegidas @rutaArchivo = 'C:\Datasets\area_protegida.geojson';
*/
