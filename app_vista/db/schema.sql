-- VISTA - Esquema minimo (semana 13) para RF-10 (preferencias) y RF-DF (destinos frecuentes).
-- Motor: SQLite. Fechas en texto ISO-8601. Requiere PRAGMA foreign_keys = ON en cada conexion.

CREATE TABLE usuario (
  id_usuario      INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
  correo          TEXT NOT NULL UNIQUE,
  contrasena_hash TEXT NOT NULL,
  fecha_registro  TEXT NOT NULL
);

CREATE TABLE configuracion (
  id_config           INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario          INTEGER NOT NULL UNIQUE
                       REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  sensibilidad        REAL NOT NULL DEFAULT 0.5
                        CHECK (sensibilidad IN (0.4, 0.5, 0.7)),
  velocidad_voz       REAL NOT NULL DEFAULT 1.2
                        CHECK (velocidad_voz BETWEEN 0.8 AND 2.0),
  modo_tonos          TEXT NOT NULL DEFAULT 'frecuencia_simple'
                        CHECK (modo_tonos IN ('frecuencia_simple', 'espacializada')),
  volumen_maestro     INTEGER NOT NULL DEFAULT 60
                        CHECK (volumen_maestro BETWEEN 50 AND 95),
  fecha_actualizacion TEXT NOT NULL
);

CREATE TABLE destino_frecuente (
  id_destino     INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario     INTEGER NOT NULL
                   REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  etiqueta       TEXT NOT NULL COLLATE NOCASE CHECK (length(trim(etiqueta)) > 0),
  direccion      TEXT NOT NULL CHECK (length(trim(direccion)) > 0),
  latitud        REAL NOT NULL CHECK (latitud BETWEEN -90 AND 90),
  longitud       REAL NOT NULL CHECK (longitud BETWEEN -180 AND 180),
  fecha_creacion TEXT NOT NULL,
  UNIQUE (id_usuario, etiqueta)
);

CREATE INDEX idx_destino_usuario ON destino_frecuente (id_usuario);
