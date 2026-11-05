-- Datos de prueba con estado inicial conocido (no contienen credenciales reales).
-- Usuario 1: tiene configuracion y dos destinos. Usuario 2: no tiene configuracion ni destinos.

INSERT INTO usuario (id_usuario, nombre, correo, contrasena_hash, fecha_registro) VALUES
  (1, 'Usuario Prueba Uno', 'usuario1@vista.test', 'hash-de-prueba-1', '2026-11-01T08:00:00'),
  (2, 'Usuario Prueba Dos', 'usuario2@vista.test', 'hash-de-prueba-2', '2026-11-01T08:05:00');

INSERT INTO configuracion (id_config, id_usuario, sensibilidad, velocidad_voz, modo_tonos, volumen_maestro, fecha_actualizacion) VALUES
  (1, 1, 0.5, 1.2, 'frecuencia_simple', 60, '2026-11-01T08:00:00');

INSERT INTO destino_frecuente (id_destino, id_usuario, etiqueta, direccion, latitud, longitud, fecha_creacion) VALUES
  (1, 1, 'Casa', 'Direccion de prueba 1, Bogota', 4.6097, -74.0817, '2026-11-01T08:10:00'),
  (2, 1, 'Universidad', 'Direccion de prueba 2, Bogota', 4.6020, -74.0660, '2026-11-01T08:12:00');
