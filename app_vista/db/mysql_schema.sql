-- Selecciona la base `vista` antes de ejecutar este esquema.
use vista;

create table if not exists usuarios (
    id_usuario int auto_increment primary key,
    nombre_usuario varchar(50) not null,
    apellido_usuario varchar(50) not null default '',
    correo_usuario varchar(100) not null unique,
    contrasena_hash varchar(255) not null,
    fecha_registro datetime not null default current_timestamp,
    estado varchar(20) not null default 'activo'
) engine=innodb default charset=utf8mb4;

create table if not exists configuracion (
    id_configuracion int auto_increment primary key,
    id_usuario int not null unique,
    sensibilidad_deteccion varchar(30) not null default '0.5',
    velocidad_voz varchar(20) not null default '1.2',
    volumen_maestro float not null default 60,
    modo_tonos varchar(20) not null default 'frecuencia_simple',
    fecha_actualizacion datetime not null default current_timestamp
      on update current_timestamp,
    constraint fk_configuracion_usuario
      foreign key (id_usuario) references usuarios(id_usuario)
      on delete cascade
) engine=innodb default charset=utf8mb4;

create table if not exists destinos_frecuentes (
    id_registro int auto_increment primary key,
    id_usuario int not null,
    tipo_evento varchar(100) not null,
    descripcion varchar(255) not null,
    latitud double not null,
    longitud double not null,
    fecha_hora datetime not null default current_timestamp,
    constraint uq_destino_usuario_tipo unique (id_usuario, tipo_evento),
    constraint fk_destino_usuario
      foreign key (id_usuario) references usuarios(id_usuario)
      on delete cascade
) engine=innodb default charset=utf8mb4;

create table if not exists ubicacion (
    id_ubicacion int auto_increment primary key,
    id_usuario int not null,
    latitud double not null,
    longitud double not null,
    precision_gps float,
    fecha_hora_ubicacion datetime not null default current_timestamp,
    constraint fk_ubicacion_usuario
      foreign key (id_usuario) references usuarios(id_usuario)
      on delete cascade
) engine=innodb default charset=utf8mb4;
