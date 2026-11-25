import 'base_datos_mysql.dart';
import 'errores_persistencia.dart';
import 'modelos_datos.dart';
import 'repositorio_configuracion.dart';
import 'repositorio_destinos.dart';
import 'repositorio_autenticacion.dart';
import 'repositorio_usuarios.dart';

class RepositorioAutenticacionMySql implements RepositorioAutenticacion {
  RepositorioAutenticacionMySql(this.bd);
  final BaseDatosMySql bd;

  @override
  Future<CredencialesGuardadas?> buscarPorCorreo(String correo) async {
    final filas = await bd.conn.query(
      'select id_usuario, nombre_usuario, apellido_usuario, correo_usuario, contrasena_hash '
      'from usuarios where correo_usuario = ? limit 1',
      [correo],
    );
    if (filas.isEmpty) return null;
    final f = filas.first;
    return CredencialesGuardadas(
      usuario: Usuario(
        idUsuario: _entero(f['id_usuario']),
        nombre: '${f['nombre_usuario']} ${f['apellido_usuario']}'.trim(),
        correo: f['correo_usuario'] as String,
      ),
      hash: f['contrasena_hash'] as String,
    );
  }

  @override
  Future<Usuario> crearCuenta({
    required String nombre,
    required String correo,
    required String hashContrasena,
  }) async {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final nombrePila = partes.first;
    final apellido = partes.length > 1 ? partes.skip(1).join(' ') : '';
    final insertado = await bd.conn.query(
      'insert into usuarios '
      '(nombre_usuario, apellido_usuario, correo_usuario, contrasena_hash, fecha_registro, estado) '
      "values (?, ?, ?, ?, now(), 'activo')",
      [nombrePila, apellido, correo, hashContrasena],
    );
    final id = insertado.insertId!;
    await bd.conn.query(
      'insert into configuracion '
      '(id_usuario, sensibilidad_deteccion, velocidad_voz, volumen_maestro, modo_tonos, fecha_actualizacion) '
      "values (?, '0.5', '1.2', 60, 'frecuencia_simple', now())",
      [id],
    );
    return Usuario(idUsuario: id, nombre: nombre.trim(), correo: correo);
  }
}

class RepositorioUsuariosMySql implements RepositorioUsuarios {
  RepositorioUsuariosMySql(this.bd);
  final BaseDatosMySql bd;

  @override
  Future<Usuario?> buscarPorId(int idUsuario) async {
    final filas = await bd.conn.query(
      'select id_usuario, nombre_usuario, apellido_usuario, correo_usuario '
      'from usuarios where id_usuario = ? limit 1',
      [idUsuario],
    );
    if (filas.isEmpty) return null;
    final f = filas.first;
    return Usuario(
      idUsuario: _entero(f['id_usuario']),
      nombre: '${f['nombre_usuario']} ${f['apellido_usuario']}'.trim(),
      correo: f['correo_usuario'] as String,
    );
  }
}

class RepositorioConfiguracionMySql implements RepositorioConfiguracion {
  RepositorioConfiguracionMySql(this.bd);
  final BaseDatosMySql bd;

  @override
  Future<Configuracion?> obtener(int idUsuario) async {
    final filas = await bd.conn.query(
      'select id_configuracion, id_usuario, sensibilidad_deteccion, '
      'velocidad_voz, modo_tonos, volumen_maestro, fecha_actualizacion '
      'from configuracion where id_usuario = ? limit 1',
      [idUsuario],
    );
    if (filas.isEmpty) return null;
    final f = filas.first;
    return Configuracion(
      idConfig: _entero(f['id_configuracion']),
      idUsuario: _entero(f['id_usuario']),
      sensibilidad: _decimal(f['sensibilidad_deteccion']),
      velocidadVoz: _decimal(f['velocidad_voz']),
      modoTonos: ModoTonos.desdeBd(f['modo_tonos'] as String),
      volumenMaestro: _entero(f['volumen_maestro']),
      fechaActualizacion: _fecha(f['fecha_actualizacion']),
    );
  }

  @override
  Future<Configuracion> guardar(Configuracion c) async {
    await bd.conn.query(
      'insert into configuracion '
      '(id_usuario, sensibilidad_deteccion, velocidad_voz, volumen_maestro, '
      'modo_tonos, fecha_actualizacion) values (?, ?, ?, ?, ?, now()) '
      'on duplicate key update sensibilidad_deteccion = values(sensibilidad_deteccion), '
      'velocidad_voz = values(velocidad_voz), volumen_maestro = values(volumen_maestro), '
      'modo_tonos = values(modo_tonos), fecha_actualizacion = now()',
      [
        c.idUsuario,
        c.sensibilidad.toString(),
        c.velocidadVoz.toString(),
        c.volumenMaestro,
        c.modoTonos.valorBd,
      ],
    );
    return (await obtener(c.idUsuario))!;
  }
}

class RepositorioDestinosMySql implements RepositorioDestinos {
  RepositorioDestinosMySql(this.bd);
  final BaseDatosMySql bd;

  DestinoFrecuente _desdeFila(dynamic f) => DestinoFrecuente(
    idDestino: _entero(f['id_registro']),
    idUsuario: _entero(f['id_usuario']),
    etiqueta: f['tipo_evento'] as String,
    direccion: f['descripcion'] as String,
    latitud: _decimal(f['latitud']),
    longitud: _decimal(f['longitud']),
  );

  @override
  Future<DestinoFrecuente> guardar(DestinoFrecuente d) async {
    try {
      final r = await bd.conn.query(
        'insert into destinos_frecuentes '
        '(id_usuario, tipo_evento, descripcion, latitud, longitud, fecha_hora) '
        'values (?, ?, ?, ?, ?, now())',
        [d.idUsuario, d.etiqueta, d.direccion, d.latitud, d.longitud],
      );
      return DestinoFrecuente(
        idDestino: r.insertId,
        idUsuario: d.idUsuario,
        etiqueta: d.etiqueta,
        direccion: d.direccion,
        latitud: d.latitud,
        longitud: d.longitud,
      );
    } catch (e) {
      final detalle = e.toString().toLowerCase();
      if (detalle.contains('duplicate') || detalle.contains('1062')) {
        throw EtiquetaDuplicadaError(d.etiqueta);
      }
      if (detalle.contains('foreign key') || detalle.contains('1452')) {
        throw const UsuarioInexistenteError();
      }
      if (detalle.contains('check') || detalle.contains('constraint')) {
        throw const RestriccionVioladaError(
          'ERR-15',
          'El destino no cumple las restricciones.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<DestinoFrecuente?> buscarPorId(int idDestino) async {
    final filas = await bd.conn.query(
      'select id_registro, id_usuario, tipo_evento, descripcion, latitud, longitud '
      'from destinos_frecuentes where id_registro = ? limit 1',
      [idDestino],
    );
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    final filas = await bd.conn.query(
      'select id_registro, id_usuario, tipo_evento, descripcion, latitud, longitud '
      'from destinos_frecuentes where id_usuario = ? order by tipo_evento',
      [idUsuario],
    );
    return filas.map(_desdeFila).toList();
  }
}

int _entero(dynamic valor) => (valor as num).toInt();
double _decimal(dynamic valor) =>
    valor is num ? valor.toDouble() : double.parse(valor.toString());

DateTime? _fecha(dynamic valor) {
  if (valor is DateTime) return valor;
  return DateTime.tryParse(valor?.toString() ?? '');
}
