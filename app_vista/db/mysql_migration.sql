-- Ejecutar una sola vez en MySQL Workbench despues de crear las tablas base.
-- La API de destinos necesita guardar las coordenadas y evitar etiquetas
-- repetidas para un mismo usuario.
use vista;

alter table destinos_frecuentes
  add column latitud double not null default 0,
  add column longitud double not null default 0,
  add unique key uq_destino_usuario_tipo (id_usuario, tipo_evento);
