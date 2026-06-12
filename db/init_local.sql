
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
 
USE ParquesNacionalesDB;
GO