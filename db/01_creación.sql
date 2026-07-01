
/*
============================================================
  Universidad: Universidad nacional de la matanza
  Materia:     3641 - Bases de Datos Aplicada
  Grupo:       9
  Integrantes: Caro, Melisa; Rolleri villalba Santino; Llanos Franco; Vazquez Nahuel Dominicano
  Fecha:       12/06/2026
  Descripcion: Creacion de la base de datos ParquesNacionales
               y configuracion inicial.
============================================================
*/
 
USE master;
GO
 
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END
GO

 
CREATE DATABASE ParquesNacionalesDB;
GO
 
/*
============================================================
  Fecha:      12/6/2026
  Descripcion: Creación de esquemas, tablas, PKs, FKs y
            restricciones del sistema de Parques Nacionales.
    - maestros:     Tablas de referencia y configuracion
    - parques:      Gestion de parques y personal
    - ventas:       Tickets, entradas y pagos
    - atracciones:  Atracciones, tours y guias
    - concesiones:  Concesionarios, concesiones y canon
    - importacion:  Log de importaciones y clima
============================================================
*/

USE ParquesNacionalesDB;
GO

-- ESQUEMAS
CREATE SCHEMA maestros;
GO
CREATE SCHEMA parques;
GO
CREATE SCHEMA ventas;
GO
CREATE SCHEMA atracciones;
GO
CREATE SCHEMA concesiones;
GO
CREATE SCHEMA importacion;
GO


/*ESQUEMA: maestros
TipoParque, TipoVisitante, FormaPago*/


CREATE TABLE maestros.TipoParque (
    idTipoParque  INT           IDENTITY(1,1) NOT NULL,
    nombre        VARCHAR(100)  NOT NULL,
    descripcion   VARCHAR(500)  NULL,
    CONSTRAINT PK_TipoParque        PRIMARY KEY (idTipoParque),
    CONSTRAINT UQ_TipoParque_nombre UNIQUE (nombre)
);


CREATE TABLE maestros.TipoVisitante (
    idTipoVisitante  INT           IDENTITY(1,1) NOT NULL,
    nombre           VARCHAR(100)  NOT NULL,
    descuentoPct     DECIMAL(5,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_TipoVisitante        PRIMARY KEY (idTipoVisitante),
    CONSTRAINT UQ_TipoVisitante_nombre UNIQUE (nombre),
    CONSTRAINT CHK_TipoVisitante_descuento CHECK (descuentoPct BETWEEN 0 AND 100)
);


CREATE TABLE maestros.FormaPago (
    idFormaPago  INT          IDENTITY(1,1) NOT NULL,
    descripcion  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_FormaPago             PRIMARY KEY (idFormaPago),
    CONSTRAINT UQ_FormaPago_descripcion UNIQUE (descripcion)
);

/*
-- ESQUEMA: parques
-- Parque, Guardaparque, AsignacionParque, PuntoVenta*/

CREATE or alter TABLE parques.Parque (
    idParque      INT            IDENTITY(1,1) NOT NULL,
    idTipoParque  INT            NOT NULL,
    nombre        VARCHAR(200)   NOT NULL,
    ubicacion     VARCHAR(300)   NOT NULL,
    superficieHa  DECIMAL(12,2)  NULL,
    descripcion   VARCHAR(1000)  NULL,
    activo        BIT            NOT NULL DEFAULT 1,
	latitud DECIMAL(9,6) NULL,
	longitud DECIMAL(9,6) NULL


    CONSTRAINT PK_Parque PRIMARY KEY (idParque),
    CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (idTipoParque)
        REFERENCES maestros.TipoParque (idTipoParque),
    CONSTRAINT CHK_Parque_superficie CHECK (superficieHa IS NULL OR superficieHa > 0)
);

CREATE TABLE parques.Guardaparque (
    idGuardaparque  INT          IDENTITY(1,1) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    dni             VARCHAR(20)  NOT NULL,
    legajo          VARCHAR(50)  NOT NULL,
    email           VARCHAR(150) NULL,
    telefono        VARCHAR(50)  NULL,
    CONSTRAINT PK_Guardaparque        PRIMARY KEY (idGuardaparque),
    CONSTRAINT UQ_Guardaparque_dni    UNIQUE (dni),
    CONSTRAINT UQ_Guardaparque_legajo UNIQUE (legajo)
);


CREATE TABLE parques.AsignacionParque (
    idAsignacion    INT          IDENTITY(1,1) NOT NULL,
    idGuardaparque  INT          NOT NULL,
    idParque        INT          NOT NULL,
    fechaIngreso    DATE         NOT NULL,
    fechaEgreso     DATE         NULL,
    motivoEgreso    VARCHAR(500) NULL,
    CONSTRAINT PK_AsignacionParque PRIMARY KEY (idAsignacion),
    CONSTRAINT FK_AsignacionParque_Guardaparque FOREIGN KEY (idGuardaparque)
        REFERENCES parques.Guardaparque (idGuardaparque),
    CONSTRAINT FK_AsignacionParque_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_AsignacionParque_fechas
        CHECK (fechaEgreso IS NULL OR fechaEgreso >= fechaIngreso)
);


CREATE TABLE parques.PuntoVenta (
    idPuntoVenta     INT          IDENTITY(1,1) NOT NULL,
    idParque         INT          NOT NULL,
    nombre           VARCHAR(150) NOT NULL,
    ubicacionFisica  VARCHAR(300) NULL,
    activo           BIT          NOT NULL DEFAULT 1,
    CONSTRAINT PK_PuntoVenta PRIMARY KEY (idPuntoVenta),
    CONSTRAINT FK_PuntoVenta_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque)
);



/*ESQUEMA: ventas
Visitante, PrecioEntrada, Ticket, ItemTicket, Entrada*/

CREATE TABLE ventas.Visitante (
    idVisitante       INT          IDENTITY(1,1) NOT NULL,
    idTipoVisitante   INT          NOT NULL,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    dniPasaporte      VARCHAR(30)  NOT NULL,
    email             VARCHAR(150) NULL,
    nacionalidad      VARCHAR(100) NULL,
    esAgenciaTurismo  BIT          NOT NULL DEFAULT 0,
    CONSTRAINT PK_Visitante     PRIMARY KEY (idVisitante),
    CONSTRAINT UQ_Visitante_dni UNIQUE (dniPasaporte),
    CONSTRAINT FK_Visitante_TipoVisitante FOREIGN KEY (idTipoVisitante)
        REFERENCES maestros.TipoVisitante (idTipoVisitante)
);


CREATE TABLE ventas.PrecioEntrada (
    idPrecioEntrada  INT            IDENTITY(1,1) NOT NULL,
    idParque         INT            NOT NULL,
    idTipoVisitante  INT            NOT NULL,
    monto            DECIMAL(12,2)  NOT NULL,
    vigenciaDesde    DATE           NOT NULL,
    vigenciaHasta    DATE           NULL,
    moneda           VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    CONSTRAINT PK_PrecioEntrada PRIMARY KEY (idPrecioEntrada),
    CONSTRAINT FK_PrecioEntrada_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT FK_PrecioEntrada_TipoVisitante FOREIGN KEY (idTipoVisitante)
        REFERENCES maestros.TipoVisitante (idTipoVisitante),
    CONSTRAINT CHK_PrecioEntrada_monto  CHECK (monto >= 0),
    CONSTRAINT CHK_PrecioEntrada_fechas
        CHECK (vigenciaHasta IS NULL OR vigenciaHasta >= vigenciaDesde)
);

use ParquesNacionalesDB
CREATE TABLE ventas.Ticket (
    idTicket               INT            IDENTITY(1,1) NOT NULL,
    idPuntoVenta           INT            NOT NULL,
    nroTicket              INT            NOT NULL,
    tipoComprobante        VARCHAR(50)    NOT NULL DEFAULT 'Ticket',
    compradorNombreRazon   VARCHAR(200)   NULL,
    compradorCultDni       VARCHAR(30)    NULL,
    idFormaPago            INT            NOT NULL,
    fechaEmision           DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    total                  DECIMAL(12,2)  NOT NULL DEFAULT 0,
    moneda                 VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    tipoCambio             DECIMAL(10,4)  NOT NULL DEFAULT 1,
    estado                 VARCHAR(50)    NOT NULL DEFAULT 'Emitido',
	fuenteTipoCambio VARCHAR(100) NULL,
	totalUSD DECIMAL(12,2) NULL,
    CONSTRAINT PK_Ticket       PRIMARY KEY (idTicket),
    CONSTRAINT UQ_Ticket_pvNro UNIQUE (idPuntoVenta, nroTicket),
    CONSTRAINT FK_Ticket_PuntoVenta FOREIGN KEY (idPuntoVenta)
        REFERENCES parques.PuntoVenta (idPuntoVenta),
    CONSTRAINT FK_Ticket_FormaPago FOREIGN KEY (idFormaPago)
        REFERENCES maestros.FormaPago (idFormaPago),
    CONSTRAINT CHK_Ticket_total  CHECK (total >= 0),
    CONSTRAINT CHK_Ticket_cambio CHECK (tipoCambio > 0),
    CONSTRAINT CHK_Ticket_estado CHECK (estado IN ('Emitido','Anulado'))
);


CREATE TABLE ventas.ItemTicket (
    idItem          INT            IDENTITY(1,1) NOT NULL,
    idTicket        INT            NOT NULL,
    cantidad        INT            NOT NULL DEFAULT 1,
    precioUnitario  DECIMAL(12,2)  NOT NULL,
    subtotal        DECIMAL(12,2)  NOT NULL,
    CONSTRAINT PK_ItemTicket PRIMARY KEY (idItem),
    CONSTRAINT FK_ItemTicket_Ticket FOREIGN KEY (idTicket)
        REFERENCES ventas.Ticket (idTicket),
    CONSTRAINT CHK_ItemTicket_cantidad CHECK (cantidad > 0),
    CONSTRAINT CHK_ItemTicket_precio   CHECK (precioUnitario >= 0),
    CONSTRAINT CHK_ItemTicket_subtotal CHECK (subtotal >= 0)
);

CREATE TABLE ventas.Entrada (
    idEntrada    INT            IDENTITY(1,1) NOT NULL,
    idItem       INT            NOT NULL,
    idVisitante  INT            NOT NULL,
    idParque     INT            NOT NULL,
    idPrecio     INT            NOT NULL,
    fechaAcceso  DATE           NOT NULL,
    montoPagado  DECIMAL(12,2)  NOT NULL,
    estado       VARCHAR(50)    NOT NULL DEFAULT 'Activa',
    CONSTRAINT PK_Entrada PRIMARY KEY (idEntrada),
    CONSTRAINT FK_Entrada_ItemTicket FOREIGN KEY (idItem)
        REFERENCES ventas.ItemTicket (idItem),
    CONSTRAINT FK_Entrada_Visitante FOREIGN KEY (idVisitante)
        REFERENCES ventas.Visitante (idVisitante),
    CONSTRAINT FK_Entrada_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT FK_Entrada_PrecioEntrada FOREIGN KEY (idPrecio)
        REFERENCES ventas.PrecioEntrada (idPrecioEntrada),
    CONSTRAINT CHK_Entrada_monto  CHECK (montoPagado >= 0),
    CONSTRAINT CHK_Entrada_estado CHECK (estado IN ('Activa','Anulada'))
);

-- ESQUEMA: atracciones
-- Atraccion, PrecioAtraccion, GuiaAutorizado, HabilitacionGuia,
-- Tour, TourGuia, ContratacionActividad
CREATE TABLE atracciones.Atraccion (
    idAtraccion  INT           IDENTITY(1,1) NOT NULL,
    idParque     INT           NOT NULL,
    nombre       VARCHAR(200)  NOT NULL,
    tipo         VARCHAR(100)  NOT NULL,
    duracionMin  INT           NULL,
    cupoMaximo   INT           NULL,
    activa       BIT           NOT NULL DEFAULT 1,
    CONSTRAINT PK_Atraccion PRIMARY KEY (idAtraccion),
    CONSTRAINT FK_Atraccion_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_Atraccion_duracion CHECK (duracionMin IS NULL OR duracionMin > 0),
    CONSTRAINT CHK_Atraccion_cupo    CHECK (cupoMaximo  IS NULL OR cupoMaximo  > 0)
);


CREATE TABLE atracciones.PrecioAtraccion (
    idPrecioAtraccion  INT            IDENTITY(1,1) NOT NULL,
    idAtraccion        INT            NOT NULL,
    monto              DECIMAL(12,2)  NOT NULL,
    vigenciaDesde      DATE           NOT NULL,
    vigenciaHasta      DATE           NULL,
    moneda             VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    CONSTRAINT PK_PrecioAtraccion PRIMARY KEY (idPrecioAtraccion),
    CONSTRAINT FK_PrecioAtraccion_Atraccion FOREIGN KEY (idAtraccion)
        REFERENCES atracciones.Atraccion (idAtraccion),
    CONSTRAINT CHK_PrecioAtraccion_monto  CHECK (monto >= 0),
    CONSTRAINT CHK_PrecioAtraccion_fechas
        CHECK (vigenciaHasta IS NULL OR vigenciaHasta >= vigenciaDesde)
);

CREATE TABLE atracciones.GuiaAutorizado (
    idGuia        INT          IDENTITY(1,1) NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    apellido      VARCHAR(100) NOT NULL,
    dni           VARCHAR(20)  NOT NULL,
    especialidad  VARCHAR(150) NULL,
    titulo        VARCHAR(150) NULL,
    activo        BIT          NOT NULL DEFAULT 1,
    CONSTRAINT PK_GuiaAutorizado     PRIMARY KEY (idGuia),
    CONSTRAINT UQ_GuiaAutorizado_dni UNIQUE (dni)
);

CREATE TABLE atracciones.HabilitacionGuia (
    idHabilitacion  INT          IDENTITY(1,1) NOT NULL,
    idGuia          INT          NOT NULL,
    descripcion     VARCHAR(300) NOT NULL,
    fechaVigencia   DATE         NOT NULL,
    CONSTRAINT PK_HabilitacionGuia PRIMARY KEY (idHabilitacion),
    CONSTRAINT FK_HabilitacionGuia_Guia FOREIGN KEY (idGuia)
        REFERENCES atracciones.GuiaAutorizado (idGuia)
);

CREATE TABLE atracciones.Tour (
    idTour           INT          IDENTITY(1,1) NOT NULL,
    idAtraccion      INT          NOT NULL,
    fechaHoraInicio  DATETIME     NOT NULL,
    cupoDisponible   INT          NOT NULL,
    estado           VARCHAR(50)  NOT NULL DEFAULT 'Programado',
    CONSTRAINT PK_Tour PRIMARY KEY (idTour),
    CONSTRAINT FK_Tour_Atraccion FOREIGN KEY (idAtraccion)
        REFERENCES atracciones.Atraccion (idAtraccion),
    CONSTRAINT CHK_Tour_cupo   CHECK (cupoDisponible >= 0),
    CONSTRAINT CHK_Tour_estado CHECK (estado IN ('Programado','EnCurso','Finalizado','Cancelado'))
);

CREATE TABLE atracciones.TourGuia (
    idTourGuia  INT          IDENTITY(1,1) NOT NULL,
    idTour      INT          NOT NULL,
    idGuia      INT          NOT NULL,
    rol         VARCHAR(100) NOT NULL DEFAULT 'Principal',
    CONSTRAINT PK_TourGuia          PRIMARY KEY (idTourGuia),
    CONSTRAINT UQ_TourGuia_tourGuia UNIQUE (idTour, idGuia),
    CONSTRAINT FK_TourGuia_Tour FOREIGN KEY (idTour)
        REFERENCES atracciones.Tour (idTour),
    CONSTRAINT FK_TourGuia_Guia FOREIGN KEY (idGuia)
        REFERENCES atracciones.GuiaAutorizado (idGuia)
);

CREATE TABLE atracciones.ContratacionActividad (
    idContratacion   INT            IDENTITY(1,1) NOT NULL,
    idItem           INT            NOT NULL,
    idTour           INT            NOT NULL,
    idVisitante      INT            NOT NULL,
    cantidadPersonas INT            NOT NULL DEFAULT 1,
    monto            DECIMAL(12,2)  NOT NULL,
    estado           VARCHAR(50)    NOT NULL DEFAULT 'Confirmada',
    CONSTRAINT PK_ContratacionActividad PRIMARY KEY (idContratacion),
    CONSTRAINT FK_ContratacionActividad_Item FOREIGN KEY (idItem)
        REFERENCES ventas.ItemTicket (idItem),
    CONSTRAINT FK_ContratacionActividad_Tour FOREIGN KEY (idTour)
        REFERENCES atracciones.Tour (idTour),
    CONSTRAINT FK_ContratacionActividad_Visitante FOREIGN KEY (idVisitante)
        REFERENCES ventas.Visitante (idVisitante),
    CONSTRAINT CHK_ContratacionActividad_personas CHECK (cantidadPersonas > 0),
    CONSTRAINT CHK_ContratacionActividad_monto    CHECK (monto >= 0),
    CONSTRAINT CHK_ContratacionActividad_estado
        CHECK (estado IN ('Confirmada','Cancelada'))
);

-- ESQUEMA: concesiones
-- Concesionario, Concesion, PagoCanon
CREATE TABLE concesiones.Concesionario (
    idConcesionario  INT          IDENTITY(1,1) NOT NULL,
    razonSocial      VARCHAR(200) NOT NULL,
    cuit             VARCHAR(13)  NOT NULL,
    email            VARCHAR(150) NULL,
    telefono         VARCHAR(50)  NULL,
    contacto         VARCHAR(150) NULL,
    CONSTRAINT PK_Concesionario      PRIMARY KEY (idConcesionario),
    CONSTRAINT UQ_Concesionario_cuit UNIQUE (cuit)
);

CREATE TABLE concesiones.Concesion (
    idConcesion          INT            IDENTITY(1,1) NOT NULL,
    idConcesionario      INT            NOT NULL,
    idParque             INT            NOT NULL,
    tipoActividad        VARCHAR(200)   NOT NULL,
    fechaInicio          DATE           NOT NULL,
    fechaFin             DATE           NOT NULL,
    diaVencimientoPago   INT            NOT NULL DEFAULT 10,
    canonMensual         DECIMAL(12,2)  NOT NULL,
    moneda               VARCHAR(10)    NOT NULL DEFAULT 'ARS',
    estado               VARCHAR(50)    NOT NULL DEFAULT 'Vigente',
    CONSTRAINT PK_Concesion PRIMARY KEY (idConcesion),
    CONSTRAINT FK_Concesion_Concesionario FOREIGN KEY (idConcesionario)
        REFERENCES concesiones.Concesionario (idConcesionario),
    CONSTRAINT FK_Concesion_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_Concesion_fechas CHECK (fechaFin > fechaInicio),
    CONSTRAINT CHK_Concesion_canon  CHECK (canonMensual > 0),
    CONSTRAINT CHK_Concesion_estado
        CHECK (estado IN ('Vigente','Vencida','Rescindida')),
    CONSTRAINT CHK_Concesion_diaVencimiento
        CHECK (diaVencimientoPago BETWEEN 1 AND 28)
);

CREATE TABLE concesiones.PagoCanon (
    idPago       INT            IDENTITY(1,1) NOT NULL,
    idConcesion  INT            NOT NULL,
    idFormaPago  INT            NOT NULL,
    fechaPago    DATE           NOT NULL,
    monto        DECIMAL(12,2)  NOT NULL,
    comprobante  VARCHAR(200)   NULL,
    periodo      VARCHAR(7)     NOT NULL,
    CONSTRAINT PK_PagoCanon PRIMARY KEY (idPago),
    CONSTRAINT FK_PagoCanon_Concesion FOREIGN KEY (idConcesion)
        REFERENCES concesiones.Concesion (idConcesion),
    CONSTRAINT FK_PagoCanon_FormaPago FOREIGN KEY (idFormaPago)
        REFERENCES maestros.FormaPago (idFormaPago),
    CONSTRAINT CHK_PagoCanon_monto CHECK (monto > 0)
);


-- ESQUEMA: importacion
-- ImportacionLog, CondicionClimatica

CREATE TABLE importacion.ImportacionLog (
    idImportacion        INT          IDENTITY(1,1) NOT NULL,
    idParque             INT          NULL,
    fuente               VARCHAR(300) NOT NULL,
    formato              VARCHAR(50)  NOT NULL,
    fechaEjecucion       DATETIME     NOT NULL DEFAULT GETDATE(),
    registrosProcesados  INT          NOT NULL DEFAULT 0,
    registrosOk          INT          NOT NULL DEFAULT 0,
    registrosError       INT          NOT NULL DEFAULT 0,
    estado               VARCHAR(50)  NOT NULL DEFAULT 'Pendiente',
    CONSTRAINT PK_ImportacionLog PRIMARY KEY (idImportacion),
    CONSTRAINT FK_ImportacionLog_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT CHK_ImportacionLog_estado
        CHECK (estado IN ('Pendiente','EnProceso','Completado','CompletadoConErrores','Fallido'))
);

CREATE TABLE importacion.CondicionClimatica (
    idCondicion      INT            IDENTITY(1,1) NOT NULL,
    idParque         INT            NOT NULL,
    fecha            DATE           NOT NULL,
    tempMax          DECIMAL(5,2)   NULL,
    tempMin          DECIMAL(5,2)   NULL,
    precipitacionMm  DECIMAL(7,2)   NULL,
    diaLluvioso      BIT            NOT NULL DEFAULT 0,
    fuenteApi        VARCHAR(200)   NULL,
    CONSTRAINT PK_CondicionClimatica PRIMARY KEY (idCondicion),
    CONSTRAINT FK_CondicionClimatica_Parque FOREIGN KEY (idParque)
        REFERENCES parques.Parque (idParque),
    CONSTRAINT UQ_CondicionClimatica_parqueFecha UNIQUE (idParque, fecha)
);

-- INDICES

CREATE INDEX IX_Entrada_fechaAcceso       ON ventas.Entrada (fechaAcceso);
CREATE INDEX IX_Entrada_idParque          ON ventas.Entrada (idParque);
CREATE INDEX IX_Ticket_fechaEmision       ON ventas.Ticket (fechaEmision);
CREATE INDEX IX_Concesion_estado          ON concesiones.Concesion (estado);
CREATE INDEX IX_PagoCanon_periodo         ON concesiones.PagoCanon (periodo);
CREATE INDEX IX_Tour_fechaHoraInicio      ON atracciones.Tour (fechaHoraInicio);
CREATE INDEX IX_AsignacionParque_idGuarda ON parques.AsignacionParque (idGuardaparque);
