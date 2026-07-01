/*
============================================================

  Descripcion: Tests del SP sp_ObtenerTipoCambioDolar y de
               sp_VentaEntradas con pago en USD.
               Demuestra que la API se consume directamente
               desde T-SQL sin intervencion externa.

  Datos de referencia del seed:
    Parque 2 = Iguazu
    TipoVisitante 1 = Residente   (precio ARS 5.000)
    TipoVisitante 2 = Extranjero  (precio ARS 12.000)
    PuntoVenta 1 = Nahuel Huapi Test - Boleteria Principal
    FormaPago 1  = Efectivo
    Visitante 3  = John Smith (Extranjero, Estados Unidos)
============================================================
*/

USE ParquesNacionalesDB;
GO


-- TEST 1: Verificar que sp_ObtenerTipoCambioDolar conecta
--         con dolarapi.com y devuelve un valor valido
--
-- Resultado esperado:
--   tipoCambio: numero mayor a 0 (ej: 1510.00)
--   fuente:     'dolarapi.com - Dolar Blue'



DECLARE @tc     DECIMAL(10,4);
DECLARE @fuente VARCHAR(100);

EXEC sp_ObtenerTipoCambioDolar
    @tipoCambio = @tc     OUTPUT,
    @fuente     = @fuente OUTPUT;

SELECT
    @tc     AS tipoCambio,
    @fuente AS fuente,
    CASE WHEN @tc > 0 THEN 'OK - API respondio correctamente'
         ELSE 'ERROR - No se obtuvo tipo de cambio'
    END AS resultado;
GO


-- TEST 2: Venta en USD con tipo de cambio automatico
--         El SP detecta @moneda = 'USD' y @tipoCambio = 1
--         y llama a sp_ObtenerTipoCambioDolar automaticamente.
--
-- Visitante: John Smith (ID 3, Extranjero)
-- Parque:    Iguazu (ID 2)
-- Precio:    ARS 12.000
-- El SP calcula cuantos USD equivalen usando la API.
--
-- Resultado esperado:
--   totalARS:  12000.00
--   totalUSD:  12000 / tipoCambio (ej: 7.95 si tc=1510)
--   tipoCambio: valor real obtenido de dolarapi.com
--   fuenteTipoCambio: 'dolarapi.com - Dolar Blue'
--   resumen: 'El visitante paga USD X.XX (equivale a ARS 12000)'



DECLARE @entradas dbo.TipoEntradaDetalle;
INSERT INTO @entradas (idVisitante, idParque, fechaAcceso)
VALUES (2, 2, '2026-12-01'); -- , Iguazu, fecha futura

EXEC sp_VentaEntradas
    @idPuntoVenta     = 1,
    @nroTicket        = 8002,
    @idFormaPago      = 1,
    @moneda           = 'USD',
    @tipoCambio       = 1,    -- <-- default: el SP consulta la API automaticamente
    @entradas         = @entradas;
GO

SELECT idVisitante, nombre, apellido, idTipoVisitante 
FROM ventas.Visitante 
WHERE idVisitante = 2;
-- Verificar que el ticket quedo guardado con los datos correctos
SELECT
    idTicket,
    nroTicket,
    moneda,
    total           AS totalARS,
    totalUSD,
    tipoCambio,
    fuenteTipoCambio,
    estado
FROM ventas.Ticket
WHERE nroTicket = 8001;
-- Resultado esperado:
--   moneda = 'USD'
--   totalARS > 0
--   totalUSD > 0
--   tipoCambio = valor real de la API (no 1)
--   fuenteTipoCambio = 'dolarapi.com - Dolar Blue'
GO


-- TEST 3: Venta en ARS (sin API)
--         Cuando la moneda es ARS la API no se consulta.
--         totalUSD debe quedar NULL.
--
-- Visitante: Juan Perez (ID 1, Residente)
-- Parque:    Iguazu (ID 2)
-- Precio:    ARS 5.000
--
-- Resultado esperado:
--   totalARS:  5000.00
--   totalUSD:  NULL
--   tipoCambio: 1
--   fuenteTipoCambio: NULL




DECLARE @entradas2 dbo.TipoEntradaDetalle;
INSERT INTO @entradas2 (idVisitante, idParque, fechaAcceso)
VALUES (1, 2, '2026-12-01'); -- Juan Perez, Iguazu

EXEC sp_VentaEntradas
    @idPuntoVenta = 1,
    @nroTicket    = 8003,
    @idFormaPago  = 1,
    @moneda       = 'ARS',
    @entradas     = @entradas2;
GO

SELECT
    idTicket, nroTicket, moneda,
    total AS totalARS, totalUSD, tipoCambio, fuenteTipoCambio
FROM ventas.Ticket
WHERE nroTicket = 8003;
-- Resultado esperado: totalUSD = NULL, tipoCambio = 1, fuenteTipoCambio = NULL
GO


-- TEST 4: Validacion - USD con tipoCambio invalido pasado
--         Si se pasa @tipoCambio = 0, debe fallar la validacion.
--
-- Resultado esperado: error '- El tipo de cambio debe ser mayor a cero.'




BEGIN TRY
    DECLARE @entradas3 dbo.TipoEntradaDetalle;
    INSERT INTO @entradas3 VALUES (3, 2, '2026-12-01');

    EXEC sp_VentaEntradas
        @idPuntoVenta = 1,
        @nroTicket    = 8004,
        @idFormaPago  = 1,
        @moneda       = 'USD',
        @tipoCambio   = 0,   -- invalido
        @entradas     = @entradas3;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_obtenido;
    -- Resultado esperado: '- El tipo de cambio debe ser mayor a cero.'
END CATCH
GO
