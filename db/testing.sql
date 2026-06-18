/*
============================================================
  Universidad: Universidad Nacional de la Matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri Villalba, Santino; Llanos, Franco; Vazquez, Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Scripts de testing para SPs de ABM y logica de negocio.
               Incluye casos exitosos y casos que demuestran
               el comportamiento de las validaciones cuando no
               se cumplen. Cada bloque indica el resultado esperado
               en comentarios.
============================================================
*/
 
USE ParquesNacionalesDB;
GO
 
-- ============================================================
-- PREPARACION: datos base minimos para los tests
-- ============================================================
 
-- Tipo de parque
EXEC sp_TipoParque_Insertar @nombre = 'Parque Nacional', @descripcion = 'Parque de prueba';
-- Resultado esperado: idTipoParque = 1 (o el siguiente disponible)
 
-- Parque activo
EXEC sp_Parque_Insertar
    @idTipoParque = 1,
    @nombre       = 'Parque Nahuel Huapi Test',
    @ubicacion    = 'Bariloche, Rio Negro',
    @superficieHa = 705000;
-- Resultado esperado: idParque = 1
 
-- Tipo de visitante
EXEC sp_TipoVisitante_Insertar @nombre = 'Residente', @descuentoPct = 0;
-- Resultado esperado: idTipoVisitante = 1
 
EXEC sp_TipoVisitante_Insertar @nombre = 'Extranjero', @descuentoPct = 0;
-- Resultado esperado: idTipoVisitante = 2
 
-- Forma de pago
EXEC sp_FormaPago_Insertar @descripcion = 'Efectivo';
-- Resultado esperado: idFormaPago = 1
 
EXEC sp_FormaPago_Insertar @descripcion = 'Tarjeta de debito';
-- Resultado esperado: idFormaPago = 2
 
-- Punto de venta
EXEC sp_PuntoVenta_Insertar @idParque = 1, @nombre = 'Boleteria Principal', @ubicacionFisica = 'Entrada norte';
-- Resultado esperado: idPuntoVenta = 1
 
-- Visitante residente
EXEC sp_Visitante_Insertar
    @idTipoVisitante  = 1,
    @nombre           = 'Juan',
    @apellido         = 'Perez',
    @dniPasaporte     = '30111222',
    @nacionalidad     = 'Argentina';
-- Resultado esperado: idVisitante = 1
 
-- Visitante extranjero
EXEC sp_Visitante_Insertar
    @idTipoVisitante  = 2,
    @nombre           = 'John',
    @apellido         = 'Smith',
    @dniPasaporte     = 'AA123456',
    @nacionalidad     = 'Estados Unidos';
-- Resultado esperado: idVisitante = 2
 
-- Precio de entrada vigente para residente en parque 1
EXEC sp_PrecioEntrada_Insertar
    @idParque        = 1,
    @idTipoVisitante = 1,
    @monto           = 5000,
    @vigenciaDesde   = '2026-01-01';
-- Resultado esperado: idPrecioEntrada = 1
 
-- Precio de entrada vigente para extranjero en parque 1
EXEC sp_PrecioEntrada_Insertar
    @idParque        = 1,
    @idTipoVisitante = 2,
    @monto           = 15000,
    @vigenciaDesde   = '2026-01-01';
-- Resultado esperado: idPrecioEntrada = 2
 
-- Atraccion en el parque
EXEC sp_Atraccion_Insertar
    @idParque    = 1,
    @nombre      = 'Trekking Cerro Lopez',
    @tipo        = 'Excursion',
    @duracionMin = 240,
    @cupoMaximo  = 20;
-- Resultado esperado: idAtraccion = 1
 
-- Precio de atraccion vigente
EXEC sp_PrecioAtraccion_Insertar
    @idAtraccion   = 1,
    @monto         = 3000,
    @vigenciaDesde = '2026-01-01';
-- Resultado esperado: idPrecioAtraccion = 1
 
-- Tour programado
EXEC sp_Tour_Insertar
    @idAtraccion     = 1,
    @fechaHoraInicio = '20261215 09:00:00',
    @cupoDisponible  = 10;
-- Resultado esperado: idTour = 1
 
-- Guia autorizado
EXEC sp_GuiaAutorizado_Insertar
    @nombre      = 'Carlos',
    @apellido    = 'Gomez',
    @dni         = '25333444',
    @especialidad = 'Montana',
    @titulo      = 'Guia de Montana Certificado';
-- Resultado esperado: idGuia = 1
 
-- Habilitacion vigente para el guia
EXEC sp_HabilitacionGuia_Insertar
    @idGuia        = 1,
    @descripcion   = 'Habilitacion trekking zona cordillerana',
    @fechaVigencia = '2027-12-31';
-- Resultado esperado: idHabilitacion = 1
 
-- Concesionario
EXEC sp_Concesionario_Insertar
    @razonSocial = 'Patagonia Gastronomia SRL',
    @cuit        = '30-71234567-8',
    @email       = 'contacto@patagoniagastro.com';
-- Resultado esperado: idConcesionario = 1
 
-- Concesion vigente
EXEC sp_Concesion_Insertar
    @idConcesionario    = 1,
    @idParque           = 1,
    @tipoActividad      = 'Restaurante',
    @fechaInicio        = '2026-01-01',
    @fechaFin           = '2027-12-31',
    @diaVencimientoPago = 10,
    @canonMensual       = 150000;
-- Resultado esperado: idConcesion = 1
 
GO
 
-- ============================================================
-- BLOQUE 1: TESTS DE ABM - maestros.TipoParque
-- ============================================================
 
PRINT '--- TEST 1.1: Insertar TipoParque con nombre duplicado ---';
-- Resultado esperado: ERROR - ya existe un tipo de parque con ese nombre
EXEC sp_TipoParque_Insertar @nombre = 'Parque Nacional';
GO
 
PRINT '--- TEST 1.2: Insertar TipoParque con nombre vacio ---';
-- Resultado esperado: ERROR - el nombre es obligatorio
EXEC sp_TipoParque_Insertar @nombre = '   ';
GO
 
PRINT '--- TEST 1.3: Eliminar TipoParque con parques asociados ---';
-- Resultado esperado: ERROR - existen parques asociados a este tipo
EXEC sp_TipoParque_Eliminar @idTipoParque = 1;
GO
 
PRINT '--- TEST 1.4: Actualizar TipoParque exitosamente ---';
-- Resultado esperado: OK - sin filas de resultado, UPDATE exitoso
EXEC sp_TipoParque_Actualizar @idTipoParque = 1, @nombre = 'Parque Nacional (actualizado)', @descripcion = 'Actualizado en test';
GO
 
PRINT '--- TEST 1.5: Actualizar TipoParque con ID inexistente ---';
-- Resultado esperado: ERROR - no existe un tipo de parque con el ID indicado
EXEC sp_TipoParque_Actualizar @idTipoParque = 9999, @nombre = 'Inexistente';
GO
 
 
-- ============================================================
-- BLOQUE 2: TESTS DE ABM - maestros.TipoVisitante
-- ============================================================
 
PRINT '--- TEST 2.1: Insertar TipoVisitante con descuento invalido ---';
-- Resultado esperado: ERROR - el descuento debe estar entre 0 y 100
EXEC sp_TipoVisitante_Insertar @nombre = 'VIP', @descuentoPct = 150;
GO
 
PRINT '--- TEST 2.2: Insertar TipoVisitante con nombre duplicado ---';
-- Resultado esperado: ERROR - ya existe un tipo de visitante con ese nombre
EXEC sp_TipoVisitante_Insertar @nombre = 'Residente', @descuentoPct = 10;
GO
 
PRINT '--- TEST 2.3: Eliminar TipoVisitante con visitantes asociados ---';
-- Resultado esperado: ERROR - existen visitantes asociados + precios asociados
EXEC sp_TipoVisitante_Eliminar @idTipoVisitante = 1;
GO
 
PRINT '--- TEST 2.4: Insertar TipoVisitante exitosamente ---';
-- Resultado esperado: OK - devuelve nuevo idTipoVisitante
EXEC sp_TipoVisitante_Insertar @nombre = 'Jubilado', @descuentoPct = 50;
GO
 
 
-- ============================================================
-- BLOQUE 3: TESTS DE ABM - maestros.FormaPago
-- ============================================================
 
PRINT '--- TEST 3.1: Insertar FormaPago con descripcion duplicada ---';
-- Resultado esperado: ERROR - ya existe una forma de pago con esa descripcion
EXEC sp_FormaPago_Insertar @descripcion = 'Efectivo';
GO
 
PRINT '--- TEST 3.2: Insertar FormaPago con descripcion vacia ---';
-- Resultado esperado: ERROR - la descripcion es obligatoria
EXEC sp_FormaPago_Insertar @descripcion = '';
GO
 
PRINT '--- TEST 3.3: Eliminar FormaPago con tickets asociados ---';
-- Resultado esperado: ERROR - existen tickets que usan esta forma de pago
-- (se ejecuta luego de crear al menos un ticket en los tests de logica de negocio)
-- Por ahora no hay tickets, se espera exito
EXEC sp_FormaPago_Eliminar @idFormaPago = 2;
GO
-- Volvemos a insertar para no romper tests siguientes
EXEC sp_FormaPago_Insertar @descripcion = 'Tarjeta de debito';
GO
 
 
-- ============================================================
-- BLOQUE 4: TESTS DE ABM - parques.Parque
-- ============================================================
 
PRINT '--- TEST 4.1: Insertar Parque con tipo inexistente ---';
-- Resultado esperado: ERROR - el tipo de parque indicado no existe
EXEC sp_Parque_Insertar @idTipoParque = 9999, @nombre = 'Parque X', @ubicacion = 'En ninguna parte';
GO
 
PRINT '--- TEST 4.2: Insertar Parque con superficie negativa ---';
-- Resultado esperado: ERROR - la superficie debe ser mayor a cero
EXEC sp_Parque_Insertar @idTipoParque = 1, @nombre = 'Parque Y', @ubicacion = 'Buenos Aires', @superficieHa = -100;
GO
 
PRINT '--- TEST 4.3: Insertar Parque exitosamente ---';
-- Resultado esperado: OK - devuelve nuevo idParque
EXEC sp_Parque_Insertar
    @idTipoParque = 1,
    @nombre       = 'Parque Los Glaciares Test',
    @ubicacion    = 'Santa Cruz',
    @superficieHa = 726927;
GO
 
 
-- ============================================================
-- BLOQUE 5: TESTS DE ABM - parques.Guardaparque y AsignacionParque
-- ============================================================
 
PRINT '--- TEST 5.1: Insertar Guardaparque exitosamente ---';
-- Resultado esperado: OK - devuelve idGuardaparque
EXEC sp_Guardaparque_Insertar
    @nombre   = 'Maria',
    @apellido = 'Lopez',
    @dni      = '28999111',
    @legajo   = 'GP-001',
    @email    = 'mlopez@parques.gob.ar';
GO
 
PRINT '--- TEST 5.2: Insertar Guardaparque con DNI duplicado ---';
-- Resultado esperado: ERROR - ya existe un guardaparque con ese DNI
EXEC sp_Guardaparque_Insertar
    @nombre   = 'Otro',
    @apellido = 'Guardaparque',
    @dni      = '28999111',
    @legajo   = 'GP-002';
GO
 
PRINT '--- TEST 5.3: Asignar Guardaparque a parque activo ---';
-- Resultado esperado: OK - devuelve idAsignacion
EXEC sp_AsignacionParque_Insertar
    @idGuardaparque = 1,
    @idParque       = 1,
    @fechaIngreso   = '2026-01-15';
GO
 
PRINT '--- TEST 5.4: Intentar segunda asignacion activa para el mismo guardaparque ---';
-- Resultado esperado: ERROR - el guardaparque ya tiene una asignacion activa
EXEC sp_AsignacionParque_Insertar
    @idGuardaparque = 1,
    @idParque       = 1,
    @fechaIngreso   = '2026-02-01';
GO
 
PRINT '--- TEST 5.5: Intentar eliminar Guardaparque con asignacion activa ---';
-- Resultado esperado: ERROR - tiene asignacion activa, debe registrarse egreso primero
EXEC sp_Guardaparque_Eliminar @idGuardaparque = 1;
GO
 
PRINT '--- TEST 5.6: Cerrar asignacion con fecha de egreso anterior a ingreso ---';
-- Resultado esperado: ERROR - la fecha de egreso no puede ser anterior a la de ingreso
EXEC sp_AsignacionParque_Cerrar @idAsignacion = 1, @fechaEgreso = '2025-12-01';
GO
 
PRINT '--- TEST 5.7: Cerrar asignacion correctamente ---';
-- Resultado esperado: OK - asignacion cerrada
EXEC sp_AsignacionParque_Cerrar
    @idAsignacion = 1,
    @fechaEgreso  = '2026-06-01',
    @motivoEgreso = 'Reasignacion administrativa';
GO
 
 
-- ============================================================
-- BLOQUE 6: TESTS DE ABM - atracciones.Atraccion y Tour
-- ============================================================
 
PRINT '--- TEST 6.1: Insertar Atraccion con duracion cero ---';
-- Resultado esperado: ERROR - la duracion debe ser mayor a cero
EXEC sp_Atraccion_Insertar
    @idParque    = 1,
    @nombre      = 'Atraccion invalida',
    @tipo        = 'Observacion',
    @duracionMin = 0;
GO
 
PRINT '--- TEST 6.2: Insertar Tour con cupo mayor al maximo de la atraccion ---';
-- Resultado esperado: ERROR - el cupo disponible no puede superar el cupo maximo (20)
EXEC sp_Tour_Insertar
    @idAtraccion     = 1,
    @fechaHoraInicio = '20261215 09:00:00',
    @cupoDisponible  = 50;
GO
 
PRINT '--- TEST 6.3: Insertar Tour con fecha pasada ---';
-- Resultado esperado: ERROR - la fecha y hora del tour debe ser futura
EXEC sp_Tour_Insertar
    @idAtraccion     = 1,
    @fechaHoraInicio = '20261215 09:00:00',
    @cupoDisponible  = 5;
GO
 
PRINT '--- TEST 6.4: Actualizar estado de tour a valor invalido ---';
-- Resultado esperado: ERROR - estado invalido
EXEC sp_Tour_ActualizarEstado @idTour = 1, @estado = 'Suspendido';
GO
 
PRINT '--- TEST 6.5: Actualizar estado de tour exitosamente ---';
-- Resultado esperado: OK
EXEC sp_Tour_ActualizarEstado @idTour = 1, @estado = 'Programado';
GO
 
 
-- ============================================================
-- BLOQUE 7: TESTS DE ABM - atracciones.GuiaAutorizado y Habilitacion
-- ============================================================
 
PRINT '--- TEST 7.1: Insertar Guia con DNI duplicado ---';
-- Resultado esperado: ERROR - ya existe un guia con ese DNI
EXEC sp_GuiaAutorizado_Insertar
    @nombre   = 'Pedro',
    @apellido = 'Ramirez',
    @dni      = '25333444';
GO
 
PRINT '--- TEST 7.2: Insertar Habilitacion con fecha pasada ---';
-- Resultado esperado: ERROR - la fecha de vigencia no puede ser anterior a hoy
EXEC sp_HabilitacionGuia_Insertar
    @idGuia        = 1,
    @descripcion   = 'Habilitacion vencida',
    @fechaVigencia = '2020-01-01';
GO
 
PRINT '--- TEST 7.3: Eliminar guia con tours activos asignados ---';
-- Resultado esperado: ERROR - el guia tiene tours activos asignados
-- (primero asignamos el guia al tour para que haya conflicto)
EXEC sp_AsignarGuiaATour @idTour = 1, @idGuia = 1, @rol = 'Principal';
EXEC sp_GuiaAutorizado_Eliminar @idGuia = 1;
GO
 
 
-- ============================================================
-- BLOQUE 8: TESTS DE ABM - concesiones
-- ============================================================
 
PRINT '--- TEST 8.1: Insertar Concesionario con CUIT duplicado ---';
-- Resultado esperado: ERROR - ya existe un concesionario con ese CUIT
EXEC sp_Concesionario_Insertar
    @razonSocial = 'Otra empresa',
    @cuit        = '30-71234567-8';
GO
 
PRINT '--- TEST 8.2: Insertar Concesion con fecha fin anterior a inicio ---';
-- Resultado esperado: ERROR - la fecha de fin debe ser posterior a la de inicio
EXEC sp_Concesion_Insertar
    @idConcesionario = 1,
    @idParque        = 1,
    @tipoActividad   = 'Tienda de souvenirs',
    @fechaInicio     = '2026-06-01',
    @fechaFin        = '2026-01-01',
    @canonMensual    = 80000;
GO
 
PRINT '--- TEST 8.3: Insertar Concesion con dia de vencimiento fuera de rango ---';
-- Resultado esperado: ERROR - el dia de vencimiento debe estar entre 1 y 28
EXEC sp_Concesion_Insertar
    @idConcesionario    = 1,
    @idParque           = 1,
    @tipoActividad      = 'Tienda de souvenirs',
    @fechaInicio        = '2026-06-01',
    @fechaFin           = '2027-06-01',
    @diaVencimientoPago = 31,
    @canonMensual       = 80000;
GO
 
PRINT '--- TEST 8.4: Insertar PagoCanon con periodo duplicado ---';
-- Resultado esperado: ERROR - ya existe un pago para esa concesion en ese periodo
EXEC sp_PagoCanon_Insertar
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-02-10',
    @monto       = 150000,
    @periodo     = '2026-02';
 
EXEC sp_PagoCanon_Insertar
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-02-15',
    @monto       = 150000,
    @periodo     = '2026-02';
GO
 
PRINT '--- TEST 8.5: Insertar PagoCanon con formato de periodo invalido ---';
-- Resultado esperado: ERROR - el periodo debe tener formato YYYY-MM
EXEC sp_PagoCanon_Insertar
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-03-10',
    @monto       = 150000,
    @periodo     = '03-2026';
GO
 
 
-- ============================================================
-- BLOQUE 9: TESTS DE LOGICA DE NEGOCIO - sp_VentaEntradas
-- ============================================================
 
PRINT '--- TEST 9.1: Venta de entradas exitosa (2 visitantes) ---';
-- Resultado esperado: OK - devuelve idTicket y totalTicket = 20000 (5000 + 15000)
 
DECLARE @detalleEntradas dbo.TipoEntradaDetalle;
INSERT INTO @detalleEntradas VALUES (1, 1, '2026-12-15'); -- residente
INSERT INTO @detalleEntradas VALUES (2, 1, '2026-12-15'); -- extranjero
 
EXEC sp_VentaEntradas
    @idPuntoVenta    = 1,
    @nroTicket       = 1001,
    @idFormaPago     = 1,
    @fechaEmision    = '2026-06-12',
    @entradas        = @detalleEntradas;
GO
 
-- Verificar que el ticket fue creado correctamente
SELECT t.idTicket, t.nroTicket, t.total, t.estado,
       COUNT(it.idItem) AS cantItems
FROM ventas.Ticket t
JOIN ventas.ItemTicket it ON it.idTicket = t.idTicket
WHERE t.nroTicket = 1001
GROUP BY t.idTicket, t.nroTicket, t.total, t.estado;
-- Resultado esperado: 1 ticket con total = 20000, estado = Emitido, cantItems = 2
GO
 
PRINT '--- TEST 9.2: Venta con numero de ticket duplicado ---';
-- Resultado esperado: ERROR - ya existe un ticket con ese numero en este punto de venta
 
DECLARE @detalleEntradas2 dbo.TipoEntradaDetalle;
INSERT INTO @detalleEntradas2 VALUES (1, 1, '2026-12-16');
 
EXEC sp_VentaEntradas
    @idPuntoVenta = 1,
    @nroTicket    = 1001,   -- numero ya usado
    @idFormaPago  = 1,
    @entradas     = @detalleEntradas2;
GO
 
PRINT '--- TEST 9.3: Venta sin entradas en el detalle ---';
-- Resultado esperado: ERROR - debe incluir al menos una entrada
 
DECLARE @detalleVacio dbo.TipoEntradaDetalle;
 
EXEC sp_VentaEntradas
    @idPuntoVenta = 1,
    @nroTicket    = 1002,
    @idFormaPago  = 1,
    @entradas     = @detalleVacio;
GO
 
PRINT '--- TEST 9.4: Venta con visitante inexistente ---';
-- Resultado esperado: ERROR - visitante ID 9999 no existe
 
DECLARE @detalleInvalido dbo.TipoEntradaDetalle;
INSERT INTO @detalleInvalido VALUES (9999, 1, '2026-12-15');
 
EXEC sp_VentaEntradas
    @idPuntoVenta = 1,
    @nroTicket    = 1003,
    @idFormaPago  = 1,
    @entradas     = @detalleInvalido;
GO
 
PRINT '--- TEST 9.5: Venta con fecha de acceso anterior a emision ---';
-- Resultado esperado: ERROR - la fecha de acceso no puede ser anterior a la de emision
 
DECLARE @detalleFechaInvalida dbo.TipoEntradaDetalle;
INSERT INTO @detalleFechaInvalida VALUES (1, 1, '2026-01-01');
 
EXEC sp_VentaEntradas
    @idPuntoVenta = 1,
    @nroTicket    = 1004,
    @idFormaPago  = 1,
    @fechaEmision = '2026-06-12',
    @entradas     = @detalleFechaInvalida;
GO
 
 
-- ============================================================
-- BLOQUE 10: TESTS DE LOGICA DE NEGOCIO - sp_ContratarActividad
-- ============================================================
 
PRINT '--- TEST 10.1: Contratar actividad exitosamente (ticket nuevo) ---';
-- Resultado esperado: OK - devuelve idTicket y montoTotal = 3000 (1 persona x 3000)
EXEC sp_ContratarActividad
    @idPuntoVenta     = 1,
    @nroTicket        = 2001,
    @idFormaPago      = 1,
    @idTour           = 1,
    @idVisitante      = 1,
    @cantidadPersonas = 1;
GO
 
-- Verificar cupo decrementado
SELECT idTour, cupoDisponible FROM atracciones.Tour WHERE idTour = 1;
-- Resultado esperado: cupoDisponible = 9 (era 10, se resto 1)
GO
 
PRINT '--- TEST 10.2: Contratar actividad sumandola a un ticket existente ---';
-- Resultado esperado: OK - se agrega al ticket 1001 creado en el test 9.1
EXEC sp_ContratarActividad
    @idTicket         = 1,  -- ticket creado en test 9.1
    @idTour           = 1,
    @idVisitante      = 2,
    @cantidadPersonas = 2;
GO
 
-- Verificar que el total del ticket se actualizo
SELECT idTicket, total FROM ventas.Ticket WHERE idTicket = 1;
-- Resultado esperado: total = 20000 + 6000 = 26000
GO
 
PRINT '--- TEST 10.3: Contratar actividad con cupo insuficiente ---';
-- Resultado esperado: ERROR - no hay cupo suficiente
-- (el tour tiene cupo = 8 luego de los tests anteriores, pedimos 20)
EXEC sp_ContratarActividad
    @idPuntoVenta     = 1,
    @nroTicket        = 2002,
    @idFormaPago      = 1,
    @idTour           = 1,
    @idVisitante      = 1,
    @cantidadPersonas = 20;
GO
 
PRINT '--- TEST 10.4: Contratar tour inexistente ---';
-- Resultado esperado: ERROR - el tour no existe o no esta en estado Programado
EXEC sp_ContratarActividad
    @idPuntoVenta     = 1,
    @nroTicket        = 2003,
    @idFormaPago      = 1,
    @idTour           = 9999,
    @idVisitante      = 1,
    @cantidadPersonas = 1;
GO
 
 
-- ============================================================
-- BLOQUE 11: TESTS DE LOGICA DE NEGOCIO - sp_AsignarGuiaATour
-- ============================================================
 
PRINT '--- TEST 11.1: Asignar guia a tour exitosamente ---';
-- Resultado esperado: OK - devuelve idTourGuia
-- (ya se asigno en el bloque 7 para el test de eliminacion,
--  creamos un segundo guia para este test)
EXEC sp_GuiaAutorizado_Insertar
    @nombre      = 'Ana',
    @apellido    = 'Fernandez',
    @dni         = '32555666',
    @especialidad = 'Flora nativa';
 
EXEC sp_HabilitacionGuia_Insertar
    @idGuia        = 2,
    @descripcion   = 'Guia botanica',
    @fechaVigencia = '2027-06-30';
 
EXEC sp_AsignarGuiaATour @idTour = 1, @idGuia = 2, @rol = 'Asistente';
-- Resultado esperado: OK - devuelve idTourGuia
GO
 
PRINT '--- TEST 11.2: Asignar guia ya asignado al mismo tour ---';
-- Resultado esperado: ERROR - el guia ya esta asignado a este tour
EXEC sp_AsignarGuiaATour @idTour = 1, @idGuia = 2, @rol = 'Principal';
GO
 
PRINT '--- TEST 11.3: Asignar guia sin habilitacion vigente ---';
-- Resultado esperado: ERROR - el guia no posee habilitacion vigente
EXEC sp_GuiaAutorizado_Insertar
    @nombre   = 'Roberto',
    @apellido = 'Sin Habilitacion',
    @dni      = '40777888';
-- idGuia = 3, sin habilitacion
 
EXEC sp_AsignarGuiaATour @idTour = 1, @idGuia = 3, @rol = 'Asistente';
GO
 
PRINT '--- TEST 11.4: Asignar guia a tour no Programado ---';
-- Primero cambiamos el estado del tour, luego intentamos asignar
EXEC sp_Tour_ActualizarEstado @idTour = 1, @estado = 'Cancelado';
EXEC sp_AsignarGuiaATour @idTour = 1, @idGuia = 2, @rol = 'Principal';
-- Resultado esperado: ERROR - el tour no esta en estado Programado
-- Restauramos el estado
EXEC sp_Tour_ActualizarEstado @idTour = 1, @estado = 'Programado';
GO
 
 
-- ============================================================
-- BLOQUE 12: TESTS DE LOGICA DE NEGOCIO - sp_RegistrarPagoCanonYActualizarEstado
-- ============================================================
 
PRINT '--- TEST 12.1: Registrar pago de canon exitosamente ---';
-- Resultado esperado: OK - devuelve idPago
-- (el pago de 2026-02 ya fue creado en el test 8.4)
EXEC sp_RegistrarPagoCanonYActualizarEstado
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-03-10',
    @monto       = 150000,
    @comprobante = 'REC-0001',
    @periodo     = '2026-03';
GO
 
-- Verificar estado de la concesion (debe seguir Vigente)
SELECT idConcesion, estado FROM concesiones.Concesion WHERE idConcesion = 1;
-- Resultado esperado: estado = 'Vigente'
GO
 
PRINT '--- TEST 12.2: Registrar pago en concesion rescindida ---';
-- Primero rescindimos la concesion
EXEC sp_Concesion_Actualizar
    @idConcesion        = 1,
    @tipoActividad      = 'Restaurante',
    @fechaFin           = '2027-12-31',
    @diaVencimientoPago = 10,
    @canonMensual       = 150000,
    @moneda             = 'ARS',
    @estado             = 'Rescindida';
 
EXEC sp_RegistrarPagoCanonYActualizarEstado
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-04-10',
    @monto       = 150000,
    @periodo     = '2026-04';
-- Resultado esperado: ERROR - no se puede registrar un pago en una concesion rescindida
 
-- Restaurar estado para tests siguientes
EXEC sp_Concesion_Actualizar
    @idConcesion        = 1,
    @tipoActividad      = 'Restaurante',
    @fechaFin           = '2027-12-31',
    @diaVencimientoPago = 10,
    @canonMensual       = 150000,
    @moneda             = 'ARS',
    @estado             = 'Vigente';
GO
 
PRINT '--- TEST 12.3: Registrar pago con periodo ya existente ---';
-- Resultado esperado: ERROR - ya existe un pago para ese periodo
EXEC sp_RegistrarPagoCanonYActualizarEstado
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2026-03-12',
    @monto       = 150000,
    @periodo     = '2026-03';
GO
 
PRINT '--- TEST 12.4: Registrar pago con fecha futura ---';
-- Resultado esperado: ERROR - la fecha de pago no puede ser futura
EXEC sp_RegistrarPagoCanonYActualizarEstado
    @idConcesion = 1,
    @idFormaPago = 1,
    @fechaPago   = '2030-01-01',
    @monto       = 150000,
    @periodo     = '2026-04';
GO
 
 
-- ============================================================
-- BLOQUE 13: TESTS DE LOGICA DE NEGOCIO - sp_AnularTicket
-- ============================================================
 
PRINT '--- TEST 13.1: Anular ticket exitosamente ---';
-- Resultado esperado: OK - ticket anulado, entradas anuladas, cupo restaurado
 
-- Primero verificamos el cupo antes de anular
SELECT idTour, cupoDisponible FROM atracciones.Tour WHERE idTour = 1;
-- Se espera cupoDisponible = 7 (10 - 1 del test 10.1 - 2 del test 10.2)
 
EXEC sp_AnularTicket @idTicket = 2;  -- ticket creado en test 10.1
GO
 
-- Verificar estado del ticket
SELECT idTicket, estado FROM ventas.Ticket WHERE idTicket = 2;
-- Resultado esperado: estado = 'Anulado'
 
-- Verificar que las entradas fueron anuladas
SELECT e.idEntrada, e.estado
FROM ventas.Entrada e
JOIN ventas.ItemTicket it ON it.idItem = e.idItem
WHERE it.idTicket = 2;
-- Resultado esperado: estado = 'Anulada' para todas las filas
 
-- Verificar cupo restaurado (el ticket 2 tenia 1 persona en tour 1)
SELECT idTour, cupoDisponible FROM atracciones.Tour WHERE idTour = 1;
-- Resultado esperado: cupoDisponible = 8 (se restauro 1)
GO
 
PRINT '--- TEST 13.2: Anular ticket ya anulado ---';
-- Resultado esperado: ERROR - el ticket ya se encuentra anulado
EXEC sp_AnularTicket @idTicket = 2;
GO
 
PRINT '--- TEST 13.3: Anular ticket inexistente ---';
-- Resultado esperado: ERROR - no existe un ticket con el ID indicado
EXEC sp_AnularTicket @idTicket = 9999;
GO
 
 
-- ============================================================
-- BLOQUE 14: TESTS DE LOGICA DE NEGOCIO - sp_ImportarDatosExternos
-- ============================================================
 
PRINT '--- TEST 14.1: Registrar importacion exitosa ---';
-- Resultado esperado: OK - devuelve idImportacion con estado Completado
EXEC sp_ImportarDatosExternos
    @idParque            = 1,
    @fuente              = 'datos.gob.ar/dataset/parques-nacionales.csv',
    @formato             = 'CSV',
    @registrosProcesados = 50,
    @registrosOk         = 48,
    @registrosError      = 2,
    @estadoFinal         = 'CompletadoConErrores';
GO
 
-- Verificar log
SELECT idImportacion, fuente, formato, registrosProcesados, registrosOk, registrosError, estado
FROM importacion.ImportacionLog
ORDER BY idImportacion DESC;
-- Resultado esperado: 1 fila con los datos insertados y estado CompletadoConErrores
GO
 
PRINT '--- TEST 14.2: Importacion con estado invalido ---';
-- Resultado esperado: ERROR - estado final invalido
EXEC sp_ImportarDatosExternos
    @fuente              = 'archivo.xml',
    @formato             = 'XML',
    @registrosProcesados = 10,
    @registrosOk         = 10,
    @registrosError      = 0,
    @estadoFinal         = 'OK';
GO
 
PRINT '--- TEST 14.3: Importacion con fuente vacia ---';
-- Resultado esperado: ERROR - la fuente es obligatoria
EXEC sp_ImportarDatosExternos
    @fuente              = '',
    @formato             = 'CSV',
    @registrosProcesados = 5,
    @registrosOk         = 5,
    @registrosError      = 0,
    @estadoFinal         = 'Completado';
GO
 
PRINT '--- TEST 14.4: Importacion con registros negativos ---';
-- Resultado esperado: ERROR - los registros procesados no pueden ser negativos
EXEC sp_ImportarDatosExternos
    @fuente              = 'archivo.csv',
    @formato             = 'CSV',
    @registrosProcesados = -1,
    @registrosOk         = 0,
    @registrosError      = 0,
    @estadoFinal         = 'Completado';
GO
 
 
-- ============================================================
-- BLOQUE 15: VERIFICACION FINAL DEL ESTADO DE LA BASE
-- ============================================================
 
PRINT '--- VERIFICACION FINAL: Estado general de los datos ---';
 
SELECT 'Tickets'           AS entidad, COUNT(*) AS total FROM ventas.Ticket
UNION ALL
SELECT 'Entradas',                      COUNT(*)          FROM ventas.Entrada
UNION ALL
SELECT 'Items de ticket',               COUNT(*)          FROM ventas.ItemTicket
UNION ALL
SELECT 'Contrataciones actividad',      COUNT(*)          FROM atracciones.ContratacionActividad
UNION ALL
SELECT 'Tours',                         COUNT(*)          FROM atracciones.Tour
UNION ALL
SELECT 'Guias asignados a tours',       COUNT(*)          FROM atracciones.TourGuia
UNION ALL
SELECT 'Pagos de canon',                COUNT(*)          FROM concesiones.PagoCanon
UNION ALL
SELECT 'Logs de importacion',           COUNT(*)          FROM importacion.ImportacionLog;
GO



/*
--SI QUIEREN VOLVER A HACER EL TESTEO PORQUE PIENSAN QUE ALGO FALLA USAN ESTO PARA BORRAR LOS DATOS DE LAS TABLAS SIN BORRAR LA BD, LO UNICO QUE SE MANTIENE ES EL ESTADO DE LOS PARQUES QUE ES =1 ACTIVO O =0 INACTIVO, DESPUES PONGO ALGO PARA QUE SE RESETEE TODO

USE ParquesNacionalesDB;
GO

-- Primero las tablas con dependencias
DELETE FROM atracciones.ContratacionActividad;
DELETE FROM atracciones.TourGuia;
DELETE FROM atracciones.Tour;
DELETE FROM atracciones.HabilitacionGuia;
DELETE FROM atracciones.PrecioAtraccion;
DELETE FROM atracciones.Atraccion;
DELETE FROM ventas.Entrada;
DELETE FROM ventas.ItemTicket;
DELETE FROM ventas.Ticket;
DELETE FROM ventas.PrecioEntrada;
DELETE FROM ventas.Visitante;
DELETE FROM concesiones.PagoCanon;
DELETE FROM concesiones.Concesion;
DELETE FROM concesiones.Concesionario;
DELETE FROM importacion.CondicionClimatica;
DELETE FROM importacion.ImportacionLog;
DELETE FROM parques.AsignacionParque;
DELETE FROM parques.PuntoVenta;
DELETE FROM parques.Guardaparque;
DELETE FROM parques.Parque;
DELETE FROM maestros.FormaPago;
DELETE FROM maestros.TipoVisitante;
DELETE FROM maestros.TipoParque;

-- Resetear los contadores de IDENTITY
DBCC CHECKIDENT ('maestros.TipoParque', RESEED, 0);
DBCC CHECKIDENT ('maestros.TipoVisitante', RESEED, 0);
DBCC CHECKIDENT ('maestros.FormaPago', RESEED, 0);
DBCC CHECKIDENT ('parques.Parque', RESEED, 0);
DBCC CHECKIDENT ('parques.Guardaparque', RESEED, 0);
DBCC CHECKIDENT ('parques.AsignacionParque', RESEED, 0);
DBCC CHECKIDENT ('parques.PuntoVenta', RESEED, 0);
DBCC CHECKIDENT ('ventas.Visitante', RESEED, 0);
DBCC CHECKIDENT ('ventas.PrecioEntrada', RESEED, 0);
DBCC CHECKIDENT ('ventas.Ticket', RESEED, 0);
DBCC CHECKIDENT ('ventas.ItemTicket', RESEED, 0);
DBCC CHECKIDENT ('ventas.Entrada', RESEED, 0);
DBCC CHECKIDENT ('atracciones.Atraccion', RESEED, 0);
DBCC CHECKIDENT ('atracciones.PrecioAtraccion', RESEED, 0);
DBCC CHECKIDENT ('atracciones.GuiaAutorizado', RESEED, 0);
DBCC CHECKIDENT ('atracciones.HabilitacionGuia', RESEED, 0);
DBCC CHECKIDENT ('atracciones.Tour', RESEED, 0);
DBCC CHECKIDENT ('atracciones.TourGuia', RESEED, 0);
DBCC CHECKIDENT ('atracciones.ContratacionActividad', RESEED, 0);
DBCC CHECKIDENT ('concesiones.Concesionario', RESEED, 0);
DBCC CHECKIDENT ('concesiones.Concesion', RESEED, 0);
DBCC CHECKIDENT ('concesiones.PagoCanon', RESEED, 0);
DBCC CHECKIDENT ('importacion.ImportacionLog', RESEED, 0);
DBCC CHECKIDENT ('importacion.CondicionClimatica', RESEED, 0);

*/

