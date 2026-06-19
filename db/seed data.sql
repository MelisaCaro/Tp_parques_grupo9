/*
============================================================
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: CARO,melisa Ailen; Santino Rolleri Villalba; Llanos Franco
  Descripcion: Script de datos iniciales (seed data).
               - Al menos 10 parques //además de los importados 
               - Al menos 30 actividades/tours
               - Al menos 20 guias
               - Al menos 20 guardaparques
               - Al menos 10 concesiones
               - Historial de ventas de entradas
               Casos obligatorios cubiertos:
               - Parque con multiples actividades simultaneas
               - Tour con cupo completo
               - Concesion vigente y vencida
               - Guardaparque reasignado
============================================================
*/

USE ParquesNacionalesDB;
GO


-- DATOS MAESTROS
select *
from maestros.TipoParque
exec sp_TipoParque_Actualizar 2,'Parque Nacional Test (2)', 'Prueba Testing' 
exec sp_TipoParque_Actualizar 1,'Parque Nacional Test', 'Prueba Test' 
EXEC sp_TipoParque_Insertar 'Parque Nacional',       'Area protegida de gran extension con ecosistemas naturales';
EXEC sp_TipoParque_Insertar 'Reserva Natural',        'Area con restricciones para proteger flora y fauna';
EXEC sp_TipoParque_Insertar 'Monumento Natural',      'Sitio de valor geologico, paisajistico o cultural';
EXEC sp_TipoParque_Insertar 'Reserva de Biosfera',    'Zona reconocida por UNESCO por su biodiversidad';
EXEC sp_TipoParque_Insertar 'Area Natural Protegida', 'Denominacion provincial de proteccion ambiental';
GO

select*
from maestros.TipoVisitante

EXEC sp_TipoVisitante_Insertar 'Residente',    0;
EXEC sp_TipoVisitante_Insertar 'Extranjero',   0;
EXEC sp_TipoVisitante_Insertar 'Estudiante',   50;
EXEC sp_TipoVisitante_Insertar 'Jubilado',     50;
EXEC sp_TipoVisitante_Insertar 'Discapacidad', 100;
GO

select*
from maestros.FormaPago

EXEC sp_FormaPago_Insertar 'Efectivo';
EXEC sp_FormaPago_Insertar 'Tarjeta de Debito';
EXEC sp_FormaPago_Insertar 'Tarjeta de Credito';
EXEC sp_FormaPago_Insertar 'Transferencia Bancaria';
EXEC sp_FormaPago_Insertar 'Mercado Pago';
GO


-- 10 PARQUES

select *
from parques.Parque

EXEC sp_Parque_Insertar 1, 'Nahuel Huapi',           'Bariloche, Rio Negro',          712000, 'Primer parque nacional de Argentina, fundado en 1934';
EXEC sp_Parque_Insertar 1, 'Iguazu',                 'Puerto Iguazu, Misiones',         67620, 'Patrimonio natural de la UNESCO, hogar de las Cataratas';
EXEC sp_Parque_Insertar 1, 'Los Glaciares',          'El Calafate, Santa Cruz',        726927, 'Patrimonio UNESCO, contiene el Glaciar Perito Moreno';
EXEC sp_Parque_Insertar 1, 'Talampaya',              'La Rioja',                        215000, 'Patrimonio UNESCO, formaciones geologicas rojizas';
EXEC sp_Parque_Insertar 2, 'El Palmar',              'Entre Rios',                        8500, 'Reserva de palmeras yatay, unica en el mundo';
EXEC sp_Parque_Insertar 1, 'Lanin',                  'Junin de los Andes, Neuquen',    412000, 'Contiene el volcan Lanin y lagos patagonicos';
EXEC sp_Parque_Insertar 3, 'Cerro Colorado',         'Cordoba',                           3000, 'Monumento natural con petroglifos indigenas';
EXEC sp_Parque_Insertar 1, 'Quebrada del Condorito', 'Cordoba',                          37000, 'Habitat del condor andino en las sierras de Cordoba';
EXEC sp_Parque_Insertar 4, 'Laguna de los Pozuelos', 'Jujuy',                            16000, 'Reserva de biosfera con flamencos y fauna altoandina';
EXEC sp_Parque_Insertar 1, 'Los Alerces',            'Esquel, Chubut',                  263000, 'Bosques de alerces milenarios, Patrimonio UNESCO';
GO


-- PUNTOS DE VENTA

select*
from parques.PuntoVenta

EXEC sp_PuntoVenta_Insertar 1,  'Acceso Principal Nahuel Huapi', 'Ruta 40, Km 2040';
EXEC sp_PuntoVenta_Insertar 2,  'Acceso Principal Iguazu',       'Ruta 101, Puerto Iguazu';
EXEC sp_PuntoVenta_Insertar 3,  'Acceso El Calafate',            'Ruta 11, El Calafate';
EXEC sp_PuntoVenta_Insertar 4,  'Acceso Talampaya',              'Ruta Provincial 26';
EXEC sp_PuntoVenta_Insertar 5,  'Acceso El Palmar',              'Ruta Nacional 14';
EXEC sp_PuntoVenta_Insertar 6,  'Acceso Lanin',                  'Ruta 234, Junin de los Andes';
EXEC sp_PuntoVenta_Insertar 7,  'Acceso Cerro Colorado',         'Ruta Provincial E-55';
EXEC sp_PuntoVenta_Insertar 8,  'Acceso Quebrada Condorito',     'Ruta 34, Cordoba';
EXEC sp_PuntoVenta_Insertar 9,  'Acceso Pozuelos',               'Ruta Nacional 9, Jujuy';
EXEC sp_PuntoVenta_Insertar 10, 'Acceso Los Alerces',            'Ruta Provincial 71, Esquel';
GO


-- PRECIOS DE ENTRADA

select*
from ventas.PrecioEntrada
-- Parque 1 - Nahuel Huapi
EXEC sp_PrecioEntrada_Insertar 1, 1, 3500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 1, 2, 8000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 1, 3, 1750.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 1, 4, 1750.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 1, 5,    0.00, '2026-01-01', NULL, 'ARS';

-- Parque 2 - Iguazu
EXEC sp_PrecioEntrada_Insertar 2, 1,  5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 2, 2, 12000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 2, 3,  2500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 2, 4,  2500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 2, 5,     0.00, '2026-01-01', NULL, 'ARS';

-- Parque 3 - Los Glaciares
EXEC sp_PrecioEntrada_Insertar 3, 1,  6000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 3, 2, 15000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 3, 3,  3000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 3, 4,  3000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 3, 5,     0.00, '2026-01-01', NULL, 'ARS';

-- Parques 4-10
EXEC sp_PrecioEntrada_Insertar 4,  1, 2000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 4,  2, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 5,  1, 1500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 5,  2, 4000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 6,  1, 4000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 6,  2, 9000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 7,  1, 1000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 7,  2, 2500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 8,  1, 2500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 8,  2, 6000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 9,  1,  800.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 9,  2, 2000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 10, 1, 3000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioEntrada_Insertar 10, 2, 7000.00, '2026-01-01', NULL, 'ARS';
GO

-- Precio historico parque 1 para historial
EXEC sp_PrecioEntrada_Insertar 1, 1, 2000.00, '2025-01-01', '2025-12-31', 'ARS';
GO

-- 20 GUARDAPARQUES

select*
from parques.Guardaparque

EXEC sp_Guardaparque_Insertar 'Carlos',    'Mendez',    '20111111', 'GP001', 'cmendez@parques.gob.ar',    '2944-100001';
EXEC sp_Guardaparque_Insertar 'Ana',       'Perez',     '20222222', 'GP002', 'aperez@parques.gob.ar',     '2944-100002';
EXEC sp_Guardaparque_Insertar 'Luis',      'Gonzalez',  '20333333', 'GP003', 'lgonzalez@parques.gob.ar',  '3757-200001';
EXEC sp_Guardaparque_Insertar 'Maria',     'Lopez',     '20444444', 'GP004', 'mlopez@parques.gob.ar',     '3757-200002';
EXEC sp_Guardaparque_Insertar 'Jorge',     'Ramirez',   '20555555', 'GP005', 'jramirez@parques.gob.ar',   '2902-300001';
EXEC sp_Guardaparque_Insertar 'Laura',     'Fernandez', '20666666', 'GP006', 'lfernandez@parques.gob.ar', '2902-300002';
EXEC sp_Guardaparque_Insertar 'Diego',     'Torres',    '20777777', 'GP007', 'dtorres@parques.gob.ar',    '3825-400001';
EXEC sp_Guardaparque_Insertar 'Claudia',   'Ruiz',      '20888888', 'GP008', 'cruiz@parques.gob.ar',      '3825-400002';
EXEC sp_Guardaparque_Insertar 'Pablo',     'Morales',   '20999999', 'GP009', 'pmorales@parques.gob.ar',   '3454-500001';
EXEC sp_Guardaparque_Insertar 'Sandra',    'Gimenez',   '21111111', 'GP010', 'sgimenez@parques.gob.ar',   '3454-500002';
EXEC sp_Guardaparque_Insertar 'Roberto',   'Herrera',   '21222222', 'GP011', 'rherrera@parques.gob.ar',   '2972-600001';
EXEC sp_Guardaparque_Insertar 'Natalia',   'Acosta',    '21333333', 'GP012', 'nacosta@parques.gob.ar',    '2972-600002';
EXEC sp_Guardaparque_Insertar 'Fernando',  'Medina',    '21444444', 'GP013', 'fmedina@parques.gob.ar',    '3541-700001';
EXEC sp_Guardaparque_Insertar 'Patricia',  'Vega',      '21555555', 'GP014', 'pvega@parques.gob.ar',      '3541-700002';
EXEC sp_Guardaparque_Insertar 'Marcelo',   'Suarez',    '21666666', 'GP015', 'msuarez@parques.gob.ar',    '3548-800001';
EXEC sp_Guardaparque_Insertar 'Gabriela',  'Blanco',    '21777777', 'GP016', 'gblanco@parques.gob.ar',    '3548-800002';
EXEC sp_Guardaparque_Insertar 'Alejandro', 'Vargas',    '21888888', 'GP017', 'avargas@parques.gob.ar',    '3888-900001';
EXEC sp_Guardaparque_Insertar 'Monica',    'Castro',    '21999999', 'GP018', 'mcastro@parques.gob.ar',    '3888-900002';
EXEC sp_Guardaparque_Insertar 'Sebastian', 'Romero',    '22111111', 'GP019', 'sromero@parques.gob.ar',    '2945-100100';
EXEC sp_Guardaparque_Insertar 'Valeria',   'Rios',      '22222222', 'GP020', 'vrios@parques.gob.ar',      '2945-100200';
EXEC sp_Guardaparque_Insertar 'Melisa',   'Caro',		'43653414', 'GP021', 'mCaro@parques.gob.ar',      '1153340238';
EXEC sp_Guardaparque_Insertar 'santino', 'Rolleri',		'44000000', 'GP022', 'SRolleri@parques.gob.ar',	  '1153678912';
EXEC sp_Guardaparque_Insertar 'Franco', 'llanos',		'45001400', 'GP023', 'FLlanos@parques.gob.ar',	  '1153578816';
GO


-- Asignaciones activas

select*
from parques.AsignacionParque 
EXEC sp_AsignacionParque_Insertar 21,  1, '2024-02-01';
EXEC sp_AsignacionParque_Insertar 2,  1, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 3,  2, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 4,  2, '2024-01-15';
EXEC sp_AsignacionParque_Insertar 5,  3, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 6,  3, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 7,  4, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 8,  5, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 9,  6, '2025-02-24';
EXEC sp_AsignacionParque_Insertar 10, 7, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 11, 8, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 12, 9, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 13, 10,'2024-01-01';
EXEC sp_AsignacionParque_Insertar 14, 1, '2020-06-05';
EXEC sp_AsignacionParque_Insertar 15, 2, '2024-08-21';
EXEC sp_AsignacionParque_Insertar 16, 3, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 17, 4, '2024-01-01';
EXEC sp_AsignacionParque_Insertar 18, 5, '2023-10-11';
EXEC sp_AsignacionParque_Insertar 19, 6, '2026-01-01';
EXEC sp_AsignacionParque_Insertar 20, 7, '2025-01-01';
GO

-- Caso obligatorio: guardaparque reasignado
-- GP002 estaba en parque 1, lo cerramos y lo mandamos al parque 2

select*
from parques.AsignacionParque

SELECT * FROM parques.AsignacionParque 
WHERE idGuardaparque = 1
ORDER BY fechaIngreso;
EXEC sp_AsignacionParque_Cerrar 2, '2026-02-01', 'Reasignacion por necesidades operativas';
EXEC sp_AsignacionParque_Insertar 1, 3, '2026-06-04';
GO

-- 20 GUIAS AUTORIZADOS

select*
from atracciones.GuiaAutorizado

EXEC sp_GuiaAutorizado_Insertar 'Ricardo',  'Molina',   '30111111', 'Trekking y alta montana',          'Guia de Montana Certificado';
EXEC sp_GuiaAutorizado_Insertar 'Silvina',  'Ponce',    '30222222', 'Avistaje de aves',                 'Biologo';
EXEC sp_GuiaAutorizado_Insertar 'Matias',   'Campos',   '30333333', 'Rafting y kayak',                  'Tecnico en Turismo de Aventura';
EXEC sp_GuiaAutorizado_Insertar 'Carolina', 'Vera',     '30444444', 'Fotografia de naturaleza',          NULL;
EXEC sp_GuiaAutorizado_Insertar 'Gustavo',  'Paredes',  '30555555', 'Glaciares',                        'Guia de Montana Certificado';
EXEC sp_GuiaAutorizado_Insertar 'Daniela',  'Soto',     '30666666', 'Selva y fauna',                    'Lic. en Ciencias Naturales';
EXEC sp_GuiaAutorizado_Insertar 'Andres',   'Navarro',  '30777777', 'Arqueologia',                      'Lic. en Arqueologia';
EXEC sp_GuiaAutorizado_Insertar 'Florencia','Delgado',  '30888888', 'Ecosistemas acuaticos',             'Biologo Marino';
EXEC sp_GuiaAutorizado_Insertar 'Hector',   'Ibarra',   '30999999', 'Vulcanismo y geologia',            'Geologo';
EXEC sp_GuiaAutorizado_Insertar 'Cecilia',  'Fuentes',  '31111111', 'Flora nativa',                     'Botanico';
EXEC sp_GuiaAutorizado_Insertar 'Rodrigo',  'Arias',    '31222222', 'Trekking familiar',                 NULL;
EXEC sp_GuiaAutorizado_Insertar 'Marta',    'Cabrera',  '31333333', 'Historia y cultura',               'Prof. de Historia';
EXEC sp_GuiaAutorizado_Insertar 'Nicolas',  'Espinoza', '31444444', 'Escalada',                         'Instructor Certificado';
EXEC sp_GuiaAutorizado_Insertar 'Lorena',   'Valdes',   '31555555', 'Observacion astronomica',           NULL;
EXEC sp_GuiaAutorizado_Insertar 'Emanuel',  'Palacios', '31666666', 'Pesca deportiva',                  'Guia de Pesca Habilitado';
EXEC sp_GuiaAutorizado_Insertar 'Jimena',   'Reyes',    '31777777', 'Senderismo nocturno',               NULL;
EXEC sp_GuiaAutorizado_Insertar 'Bruno',    'Aguirre',  '31888888', 'Ciclismo de montana',              'Tecnico en Deportes';
EXEC sp_GuiaAutorizado_Insertar 'Eugenia',  'Mendoza',  '31999999', 'Yoga en naturaleza',                NULL;
EXEC sp_GuiaAutorizado_Insertar 'Tomas',    'Benitez',  '32111111', 'Fotografia submarina',             'Tecnico en Buceo';
EXEC sp_GuiaAutorizado_Insertar 'Agustina', 'Quiroga',  '32222222', 'Avistaje de condores',             'Ornitologo';
GO

-- Habilitaciones vigentes al 2027

select*
FROM atracciones.HabilitacionGuia

EXEC sp_HabilitacionGuia_Insertar 4,  'Guia de Montana Nacional Cat A',  '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 5,  'Guia Naturalista SENATUR',        '2027-06-30';
EXEC sp_HabilitacionGuia_Insertar 6,  'Guia de Aventura Nivel 2',        '2027-03-31';
EXEC sp_HabilitacionGuia_Insertar 7,  'Guia Turistico Nacional',         '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 8,  'Guia de Glaciares APN',           '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 9,  'Guia de Selva APN',               '2027-09-30';
EXEC sp_HabilitacionGuia_Insertar 10,  'Guia Arqueologico Habilitado',    '2028-01-31';
EXEC sp_HabilitacionGuia_Insertar 11,  'Guia Ecologico Acuatico',         '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 12,  'Guia Geologico Cert Nacional',    '2027-06-30';
EXEC sp_HabilitacionGuia_Insertar 13, 'Guia Botanico CONICET',           '2028-12-31';
EXEC sp_HabilitacionGuia_Insertar 14, 'Guia Turistico Provincial',       '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 15, 'Guia Cultural e Historico',       '2027-04-30';
EXEC sp_HabilitacionGuia_Insertar 16, 'Instructor de Escalada UIAA',     '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 17, 'Guia de Ecoturismo Nocturno',     '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 18, 'Guia de Pesca Fluvial APN',       '2027-03-31';
EXEC sp_HabilitacionGuia_Insertar 19, 'Guia Senderismo Nivel 1',         '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 20, 'Instructor MTB Federacion',       '2027-06-30';
EXEC sp_HabilitacionGuia_Insertar 21, 'Guia de Bienestar en Naturaleza', '2027-12-31';
EXEC sp_HabilitacionGuia_Insertar 22, 'Instructor de Buceo CMAS',        '2028-06-30';
EXEC sp_HabilitacionGuia_Insertar 23, 'Ornitologo Habilitado APN',       '2028-12-31';
GO


-- ATRACCIONES (mas de 30)
-- Parque 1 - Nahuel Huapi (caso obligatorio: multiples atracciones)

select* from parques.Parque
select * from atracciones.Atraccion

EXEC sp_Atraccion_Insertar 5, 'Trekking Cerro Lopez',        'Tour guiado',       480, 15;
EXEC sp_Atraccion_Insertar 5, 'Kayak Lago Nahuel Huapi',     'Tour guiado',       180, 10;
EXEC sp_Atraccion_Insertar 5, 'Circuito Arrayanes',          'Atraccion gratuita',120, NULL;
EXEC sp_Atraccion_Insertar 5, 'Mirador Campanario',          'Atraccion gratuita', 60, NULL;
EXEC sp_Atraccion_Insertar 5, 'Avistaje Nocturno Estrellas', 'Tour guiado',       120, 20;

-- Parque 2 - Iguazu
EXEC sp_Atraccion_Insertar 6, 'Circuito Superior Cataratas', 'Atraccion gratuita', 90, NULL;
EXEC sp_Atraccion_Insertar 6, 'Circuito Inferior Cataratas', 'Atraccion gratuita', 90, NULL;
EXEC sp_Atraccion_Insertar 6, 'Paseo en Lancha Garganta',    'Tour guiado',        60, 12;
EXEC sp_Atraccion_Insertar 6, 'Safari en la Selva',          'Tour guiado',       240,  8;
EXEC sp_Atraccion_Insertar 6, 'Avistaje de Aves Selva',      'Tour guiado',       180, 10;

-- Parque 3 - Los Glaciares
EXEC sp_Atraccion_Insertar 7, 'Trekking sobre Glaciar Perito Moreno', 'Tour guiado',       240, 12;
EXEC sp_Atraccion_Insertar 7, 'Mirador Glaciar Perito Moreno',        'Atraccion gratuita', 60, NULL;
EXEC sp_Atraccion_Insertar 7, 'Navegacion Lago Argentino',            'Tour guiado',       180, 20;
EXEC sp_Atraccion_Insertar 7, 'Trekking Fitz Roy',                    'Tour guiado',       480, 10;

-- Parque 4 - Talampaya
EXEC sp_Atraccion_Insertar 8, 'Tour Canon Talampaya en 4x4',         'Tour guiado', 180, 12;
EXEC sp_Atraccion_Insertar 8, 'Circuito Arqueologico Los Pizarrones', 'Tour guiado', 120, 15;
EXEC sp_Atraccion_Insertar 8, 'Avistaje Condores Talampaya',          'Tour guiado',  90, 10;

-- Parque 5 - El Palmar
EXEC sp_Atraccion_Insertar 9, 'Caminata entre palmeras yatay',      'Atraccion gratuita', 90, NULL;
EXEC sp_Atraccion_Insertar 9, 'Avistaje fauna costera rio Uruguay',  'Tour guiado',       120, 8;

-- Parque 6 - Lanin
EXEC sp_Atraccion_Insertar 10, 'Ascenso Volcan Lanin',              'Tour guiado', 720,  8;
EXEC sp_Atraccion_Insertar 10, 'Trekking Lagos Huechulafquen',       'Tour guiado', 300, 12;
EXEC sp_Atraccion_Insertar 10, 'Pesca deportiva Rio Chimehuin',      'Tour guiado', 240,  6;

-- Parque 7 - Cerro Colorado
EXEC sp_Atraccion_Insertar 11, 'Visita guiada petroglifos', 'Tour guiado',       120, 15;
EXEC sp_Atraccion_Insertar 11, 'Trekking sendero rojo',     'Atraccion gratuita', 90, NULL;

-- Parque 8 - Quebrada del Condorito
EXEC sp_Atraccion_Insertar 12, 'Trekking avistaje condor andino',    'Tour guiado',       300, 10;
EXEC sp_Atraccion_Insertar 12, 'Sendero autoguiado La Pampilla',     'Atraccion gratuita',120, NULL;

-- Parque 9 - Laguna Pozuelos
EXEC sp_Atraccion_Insertar 13, 'Avistaje flamencos altoandinos', 'Tour guiado',       180, 12;
EXEC sp_Atraccion_Insertar 13, 'Caminata borde laguna',          'Atraccion gratuita', 60, NULL;

-- Parque 10 - Los Alerces
EXEC sp_Atraccion_Insertar 14, 'Navegacion Lago Futalaufquen', 'Tour guiado',       240, 15;
EXEC sp_Atraccion_Insertar 14, 'Trekking Alerce Milenario',    'Tour guiado',       300, 10;
EXEC sp_Atraccion_Insertar 14, 'Pesca en rio Arrayanes',       'Tour guiado',       240,  6;
GO

-- Precios de atracciones pagas

select* from atracciones.PrecioAtraccion
EXEC sp_PrecioAtraccion_Insertar 1,  4500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 2,  3500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 5,  2500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 8,  6000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 9,  8000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 10, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 11, 9000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 13, 7000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 14, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 15, 4000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 16, 3500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 19, 4500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 20, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 21, 8000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 22, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 23, 3000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 25, 4000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 27, 3500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 29, 5000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 3, 6000.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 26, 5500.00, '2026-01-01', NULL, 'ARS';
EXEC sp_PrecioAtraccion_Insertar 4, 4500.00, '2026-01-01', NULL, 'ARS';
GO

-- TOURS (mas de 30)
-- Caso obligatorio: parque 1 con multiples tours simultaneos
select* from parques.Parque
select * from atracciones.Atraccion

-- Parque 1 - Nahuel Huapi (multiples simultaneos mismo dia)

EXEC sp_Tour_Insertar 3, '2026-07-15 08:00', 15;
EXEC sp_Tour_Insertar 4, '2026-07-15 09:00', 10;
EXEC sp_Tour_Insertar 7, '2026-07-15 21:00', 20;
EXEC sp_Tour_Insertar 3, '2026-07-20 08:00', 15;
EXEC sp_Tour_Insertar 4, '2026-07-20 09:00', 10;

-- Parque 2 - Iguazu
EXEC sp_Tour_Insertar 10,  '2026-07-16 07:30', 12;
EXEC sp_Tour_Insertar 11,  '2026-07-16 13:00',  8;
EXEC sp_Tour_Insertar 12, '2026-07-16 06:00', 10;
EXEC sp_Tour_Insertar 10,  '2026-07-22 07:30', 12;

-- Parque 3 - Los Glaciares
EXEC sp_Tour_Insertar 30, '2026-08-01 07:00', 12;
EXEC sp_Tour_Insertar 32, '2026-08-01 10:00', 20;
EXEC sp_Tour_Insertar 33, '2026-08-02 06:30', 10;
EXEC sp_Tour_Insertar 30, '2026-08-10 07:00', 12;

-- Parque 4 - Talampaya
EXEC sp_Tour_Insertar 13, '2026-07-18 09:00', 12;
EXEC sp_Tour_Insertar 14, '2026-07-18 14:00', 15;
EXEC sp_Tour_Insertar 15, '2026-07-19 07:00', 10;

-- Parque 5 - El Palmar
EXEC sp_Tour_Insertar 17, '2026-07-20 08:00', 8;

-- Parque 6 - Lanin
EXEC sp_Tour_Insertar 18, '2026-08-15 05:00',  8;
EXEC sp_Tour_Insertar 19, '2026-08-15 08:00', 12;
EXEC sp_Tour_Insertar 20, '2026-08-16 07:00',  6;

-- Parque 7 - Cerro Colorado
EXEC sp_Tour_Insertar 21, '2026-07-25 10:00', 15;
EXEC sp_Tour_Insertar 21, '2026-07-25 15:00', 15;

-- Parque 8 - Quebrada Condorito
EXEC sp_Tour_Insertar 23, '2026-07-22 07:00', 10;

-- Parque 9 - Pozuelos
EXEC sp_Tour_Insertar 25, '2026-08-05 06:00', 12;

-- Parque 10 - Los Alerces
EXEC sp_Tour_Insertar 27, '2026-08-08 09:00', 15;
EXEC sp_Tour_Insertar 28, '2026-08-08 07:00', 10;
EXEC sp_Tour_Insertar 28, '2026-08-09 07:00', 10;
EXEC sp_Tour_Insertar 29, '2026-08-09 08:00',  6;
GO

-- Asignacion de guias a tours

select* from atracciones.TourGuia
select* from atracciones.Atraccion
select* from atracciones.GuiaAutorizado
SELECT* FROM atracciones.Tour
EXEC sp_AsignarGuiaATour 5,  4,  'Principal';
EXEC sp_AsignarGuiaATour 6,  6,  'Principal';
EXEC sp_AsignarGuiaATour 7,  17, 'Principal';
EXEC sp_AsignarGuiaATour 8,  4,  'Principal';
EXEC sp_AsignarGuiaATour 9,  7,  'Principal';
EXEC sp_AsignarGuiaATour 10,  11,  'Principal';
EXEC sp_AsignarGuiaATour 11,  12,  'Principal';
EXEC sp_AsignarGuiaATour 12,  9,  'Principal';
EXEC sp_AsignarGuiaATour 14, 8,  'Principal';
EXEC sp_AsignarGuiaATour 15, 8,  'Principal';
EXEC sp_AsignarGuiaATour 15, 4,  'Asistente';
EXEC sp_AsignarGuiaATour 16, 4,  'Principal';
EXEC sp_AsignarGuiaATour 18, 12,  'Principal';
EXEC sp_AsignarGuiaATour 19, 10,  'Principal';
EXEC sp_AsignarGuiaATour 20, 10,  'Principal';
EXEC sp_AsignarGuiaATour 21, 23, 'Principal';
EXEC sp_AsignarGuiaATour 22, 5,  'Principal';
EXEC sp_AsignarGuiaATour 23, 18, 'Principal';
EXEC sp_AsignarGuiaATour 24, 12,  'Principal';
EXEC sp_AsignarGuiaATour 25, 10,  'Principal';
EXEC sp_AsignarGuiaATour 26, 23, 'Principal';
EXEC sp_AsignarGuiaATour 27, 8,  'Principal';
GO


-- VISITANTES

select* from ventas.Visitante

EXEC sp_Visitante_Insertar 1, 'Juan',      'Garcia',   '40111111', 'jgarcia@email.com',   'Argentina';
EXEC sp_Visitante_Insertar 1, 'Sofia',     'Martinez', '40222222', 'smartinez@email.com', 'Argentina';
EXEC sp_Visitante_Insertar 2, 'John',      'Smith',    'USA123456','jsmith@email.com',    'Estados Unidos';
EXEC sp_Visitante_Insertar 3, 'Pedro',     'Alvarez',  '40333333', 'palvarez@email.com',  'Argentina';
EXEC sp_Visitante_Insertar 4, 'Rosa',      'Jimenez',  '10555555', 'rjimenez@email.com',  'Argentina';
EXEC sp_Visitante_Insertar 2, 'Marie',     'Dupont',   'FRA987654','mdupont@email.com',   'Francia';
EXEC sp_Visitante_Insertar 1, 'Lucas',     'Pereyra',  '40444444', 'lpereyra@email.com',  'Argentina';
EXEC sp_Visitante_Insertar 3, 'Valentina', 'Torres',   '40555555', 'vtorres@email.com',   'Argentina';
EXEC sp_Visitante_Insertar 1, 'Martin',    'Diaz',     '40666666', 'mdiaz@email.com',     'Argentina';
EXEC sp_Visitante_Insertar 2, 'Luca',      'Rossi',    'ITA112233','lrossi@email.com',    'Italia';
GO


-- HISTORIAL DE VENTAS DE ENTRADAS

select* from ventas.ItemTicket

-- Ticket 1 - PV1 - visitante 1 en parque 1 (residente)
DECLARE @e1 dbo.TipoEntradaDetalle;
INSERT INTO @e1 VALUES (1, 1, '2026-07-01');
EXEC sp_VentaEntradas 1, 1, 'Ticket', NULL, NULL, 1, '2026-07-01', 'ARS', 1, @e1;
GO
 
-- Ticket 2 - PV1 - visitante 2 en parque 1 (residente)
DECLARE @e2 dbo.TipoEntradaDetalle;
INSERT INTO @e2 VALUES (2, 1, '2026-07-01');
EXEC sp_VentaEntradas 1, 2, 'Ticket', NULL, NULL, 2, '2026-07-01', 'ARS', 1, @e2;
GO
 
-- Ticket 1 - PV2 - visitante 3 en parque 2 (extranjero, paga en USD)
DECLARE @e3 dbo.TipoEntradaDetalle;
INSERT INTO @e3 VALUES (3, 2, '2026-07-02');
EXEC sp_VentaEntradas 2, 1, 'Ticket', 'John Smith', 'USA123456', 1, '2026-07-02', 'USD', 1200, @e3;
GO
 
-- Ticket 2 - PV2 - visitante 4 en parque 2 (estudiante)
DECLARE @e4 dbo.TipoEntradaDetalle;
INSERT INTO @e4 VALUES (4, 2, '2026-07-02');
EXEC sp_VentaEntradas 2, 2, 'Ticket', NULL, NULL, 3, '2026-07-02', 'ARS', 1, @e4;
GO
 
-- Ticket 1 - PV3 - visitante 5 en parque 3 (jubilado)
DECLARE @e5 dbo.TipoEntradaDetalle;
INSERT INTO @e5 VALUES (5, 3, '2026-07-03');
EXEC sp_VentaEntradas 3, 1, 'Ticket', NULL, NULL, 1, '2026-07-03', 'ARS', 1, @e5;
GO
 
-- Ticket 2 - PV3 - visitante 6 en parque 3 (extranjero, paga en EUR)
DECLARE @e6 dbo.TipoEntradaDetalle;
INSERT INTO @e6 VALUES (6, 3, '2026-07-03');
EXEC sp_VentaEntradas 3, 2, 'Ticket', 'Marie Dupont', 'FRA987654', 1, '2026-07-03', 'EUR', 1100, @e6;
GO
 
-- Ticket 1 - PV4 - visitante 7 en parque 4 (residente)
DECLARE @e7 dbo.TipoEntradaDetalle;
INSERT INTO @e7 VALUES (7, 4, '2026-07-04');
EXEC sp_VentaEntradas 4, 1, 'Ticket', NULL, NULL, 1, '2026-07-04', 'ARS', 1, @e7;
GO
 
-- Ticket 1 - PV5 - visitante 8 en parque 5 (estudiante)
DECLARE @e8 dbo.TipoEntradaDetalle;
INSERT INTO @e8 VALUES (8, 5, '2026-07-05');
EXEC sp_VentaEntradas 5, 1, 'Ticket', NULL, NULL, 1, '2026-07-05', 'ARS', 1, @e8;
GO
 
-- Ticket 1 - PV6 - visitante 9 en parque 6 (residente)
DECLARE @e9 dbo.TipoEntradaDetalle;
INSERT INTO @e9 VALUES (9, 6, '2026-07-06');
EXEC sp_VentaEntradas 6, 1, 'Ticket', NULL, NULL, 1, '2026-07-06', 'ARS', 1, @e9;
GO
 
-- Ticket 1 - PV7 - visitante 10 en parque 7 (extranjero)
DECLARE @e10 dbo.TipoEntradaDetalle;
INSERT INTO @e10 VALUES (10, 7, '2026-07-07');
EXEC sp_VentaEntradas 7, 1, 'Ticket', 'Luca Rossi', 'ITA112233', 1, '2026-07-07', 'ARS', 1, @e10;
GO
 
-- Ticket 3 - PV1 - venta masiva: visitantes 1, 2 y 7 en parque 1 (mismo dia)
DECLARE @e11 dbo.TipoEntradaDetalle;
INSERT INTO @e11 VALUES (1, 1, '2026-07-10');
INSERT INTO @e11 VALUES (2, 1, '2026-07-10');
INSERT INTO @e11 VALUES (7, 1, '2026-07-10');
EXEC sp_VentaEntradas 1, 3, 'Ticket', NULL, NULL, 1, '2026-07-10', 'ARS', 1, @e11;
GO
 
-- Ticket 4 - PV1 - venta masiva: visitantes 3, 4, 5 en parque 1
DECLARE @e12 dbo.TipoEntradaDetalle;
INSERT INTO @e12 VALUES (3, 1, '2026-07-11');
INSERT INTO @e12 VALUES (4, 1, '2026-07-11');
INSERT INTO @e12 VALUES (5, 1, '2026-07-11');
EXEC sp_VentaEntradas 1, 4, 'Ticket', NULL, NULL, 2, '2026-07-11', 'ARS', 1, @e12;
GO
 


-- Contratacion de tours
select* from atracciones.Atraccion
-- Tour 9  (Paseo en Lancha Garganta - Iguazu),     visitante 1, 2 personas - ticket nuevo PV2 nro 3
EXEC sp_ContratarActividad NULL, 2, 3, 1, 9, 1, 2;
GO
 
-- Tour 11  (Safari en la Selva - Iguazu),            visitante 3, 1 persona  - ticket nuevo PV2 nro 4
EXEC sp_ContratarActividad NULL, 2, 4, 3, 11, 3, 1;
GO
 select* from maestros.FormaPago
-- Tour 33 (Trekking Fitz Roy - Los Glaciares),      visitante 5, 1 persona  - ticket nuevo PV3 nro 3
EXEC sp_ContratarActividad NULL, 3, 3, 1, 33, 5, 1;
GO
 
-- Tour 13 (Tour Canon Talampaya),                   visitante 7, 3 personas - ticket nuevo PV4 nro 2
EXEC sp_ContratarActividad NULL, 4, 2, 3, 13, 7, 3;
GO
 
-- Tour 18 (Ascenso Volcan Lanin),                   visitante 9, 2 personas - ticket nuevo PV6 nro 2
EXEC sp_ContratarActividad NULL, 6, 2, 1, 18, 9, 2;
GO
 
-- ============================================================
-- CASO OBLIGATORIO: tour con cupo completo
-- Tour 3 (Avistaje Nocturno Estrellas - Nahuel Huapi, cupo 20)
-- 20 contrataciones de 1 persona cada una, tickets nuevos en PV1
-- ============================================================
 

EXEC sp_ContratarActividad NULL, 1,  5, 1, 7, 1, 1;
EXEC sp_ContratarActividad NULL, 1,  6, 1, 7, 2, 1;
EXEC sp_ContratarActividad NULL, 1,  7, 1, 7, 3, 1;
EXEC sp_ContratarActividad NULL, 1,  8, 1, 7, 4, 1;
EXEC sp_ContratarActividad NULL, 1,  9, 1, 7, 5, 1;
EXEC sp_ContratarActividad NULL, 1, 10, 1, 7, 6, 1;
EXEC sp_ContratarActividad NULL, 1, 11, 1, 7, 7, 1;
EXEC sp_ContratarActividad NULL, 1, 12, 1, 7, 8, 1;
EXEC sp_ContratarActividad NULL, 1, 13, 1, 7, 9, 1;
EXEC sp_ContratarActividad NULL, 1, 14, 1, 7, 1, 1;
EXEC sp_ContratarActividad NULL, 1, 15, 1, 7, 2, 1;
EXEC sp_ContratarActividad NULL, 1, 16, 1, 7, 3, 1;
EXEC sp_ContratarActividad NULL, 1, 17, 1, 7, 4, 1;
EXEC sp_ContratarActividad NULL, 1, 18, 1, 7, 5, 1;
EXEC sp_ContratarActividad NULL, 1, 19, 1, 7, 6, 1;
EXEC sp_ContratarActividad NULL, 1, 20, 1, 7, 7, 1;
EXEC sp_ContratarActividad NULL, 1, 21, 1, 7, 8, 1;
EXEC sp_ContratarActividad NULL, 1, 22, 1, 7, 9, 1;
EXEC sp_ContratarActividad NULL, 1, 23, 1, 7, 1, 1;
EXEC sp_ContratarActividad NULL, 1, 24, 1, 7, 2, 1;


-- CONCESIONARIOS Y CONCESIONES (10 concesiones)


EXEC sp_Concesionario_Insertar 'Restaurante La Patagonia SRL', '30-11111111-1', 'lapatagonia@email.com', '294-4555001', 'Miguel Fernandez';
EXEC sp_Concesionario_Insertar 'Turismo Aventura SA',          '30-22222222-2', 'aventura@email.com',    '294-4555002', 'Ana Ruiz';
EXEC sp_Concesionario_Insertar 'Tienda Verde SRL',             '30-33333333-3', 'tiendaverde@email.com', '3757-555001', 'Carlos Lopez';
EXEC sp_Concesionario_Insertar 'Hostel del Bosque',            '30-44444444-4', 'hbosque@email.com',     '2902-555001', 'Laura Perez';
EXEC sp_Concesionario_Insertar 'Cafeteria Natural SA',         '30-55555555-5', 'cafnat@email.com',      '3825-555001', 'Pedro Torres';
EXEC sp_Concesionario_Insertar 'Eco Tours Patagonia SRL',      '30-66666666-6', 'ecotp@email.com',       '2902-555002', 'Maria Gomez';
EXEC sp_Concesionario_Insertar 'Foto Naturaleza SA',           '30-77777777-7', 'fotonatura@email.com',  '3454-555001', 'Juan Blanco';
EXEC sp_Concesionario_Insertar 'Kayak Andino SRL',             '30-88888888-8', 'kayak@email.com',       '2944-555003', 'Sofia Vargas';
GO
select * from concesiones.Concesion
select * from concesiones.Concesionario
select* from parques.Parque

-- 10 concesiones (vigentes y una vencida - caso obligatorio)
EXEC sp_Concesion_Insertar 2, 5, 'Restaurante',       '2025-01-01', '2027-12-31', 10, 150000.00, 'ARS';
EXEC sp_Concesion_Insertar 3, 5, 'Turismo Aventura',  '2025-01-01', '2027-06-30', 10,  80000.00, 'ARS';
EXEC sp_Concesion_Insertar 4, 6, 'Tienda souvenirs',  '2025-03-01', '2027-03-01', 15,  60000.00, 'ARS';
EXEC sp_Concesion_Insertar 5, 6, 'Alojamiento',       '2024-01-01', '2025-12-31', 10, 200000.00, 'ARS';  -- VENCIDA
EXEC sp_Concesion_Insertar 6, 7, 'Cafeteria',         '2025-06-01', '2027-06-01', 10,  90000.00, 'ARS';
EXEC sp_Concesion_Insertar 7, 7, 'Turismo Aventura',  '2025-07-01', '2027-07-01', 10,  70000.00, 'ARS';
EXEC sp_Concesion_Insertar 8, 8, 'Restaurante',       '2026-01-01', '2028-01-01', 10, 120000.00, 'ARS';
EXEC sp_Concesion_Insertar 2, 9, 'Tienda',            '2026-02-01', '2028-02-01', 15,  50000.00, 'ARS';
EXEC sp_Concesion_Insertar 9, 10, 'Kayak y Canoas',    '2025-11-01', '2027-11-01', 10,  85000.00, 'ARS';
EXEC sp_Concesion_Insertar 3, 11, 'Tours Fotograficos','2026-03-01', '2028-03-01', 10,  65000.00, 'ARS';
GO
SELECT idConcesion, estado, fechaFin
FROM concesiones.Concesion
WHERE idConcesion = 4;


-- Marcar la concesion 4 como vencida
-- Marcar concesion 4 como vencida (fechaFin ya paso)
exec  sp_ActualizarEstadoConcesiones

-- Pagos de canon (concesion 2 con pagos atrasados - caso obligatorio)
select* from concesiones.PagoCanon
EXEC sp_RegistrarPagoCanonYActualizarEstado 1, 1, '2026-01-10', 150000.00, 'REC-001', '2026-01';
EXEC sp_RegistrarPagoCanonYActualizarEstado 1, 1, '2026-04-10', 150000.00, 'REC-002', '2026-04';
EXEC sp_RegistrarPagoCanonYActualizarEstado 1, 1, '2026-05-10', 150000.00, 'REC-003', '2026-05';
EXEC sp_RegistrarPagoCanonYActualizarEstado 2, 3, '2026-01-10',  80000.00, 'REC-004', '2026-01';
-- Concesion 2 no pago desde febrero (atrasada)
EXEC sp_RegistrarPagoCanonYActualizarEstado 3, 1, '2026-03-15',  60000.00, 'REC-005', '2026-03';
EXEC sp_RegistrarPagoCanonYActualizarEstado 5, 3, '2026-06-10',  90000.00, 'REC-006', '2026-06';
EXEC sp_RegistrarPagoCanonYActualizarEstado 9, 4, '2026-01-10',  85000.00, 'REC-007', '2026-01';
EXEC sp_RegistrarPagoCanonYActualizarEstado 9, 4, '2026-02-10',  85000.00, 'REC-008', '2026-02';
GO