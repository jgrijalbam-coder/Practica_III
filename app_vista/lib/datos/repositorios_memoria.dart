import 'errores_persistencia.dart';
import 'modelos_datos.dart';
import 'repositorio_configuracion.dart';
import 'repositorio_destinos.dart';

/// Dobles de prueba para probar los servicios sin base real (RFN-06).
class RepositorioConfiguracionMemoria implements RepositorioConfiguracion {
  RepositorioConfiguracionMemoria({Iterable<int> usuariosExistentes = const []})
      : _usuarios = usuariosExistentes.toSet();

  final Set<int> _usuarios;
  final Map<int, Configuracion> _datos = {};
  int _siguienteId = 1;

  @override
  Future<Configuracion?> obtener(int idUsuario) async => _datos[idUsuario];

  @override
  Future<Configuracion> guardar(Configuracion c) async {
    if (!_usuarios.contains(c.idUsuario)) throw const UsuarioInexistenteError();
    final guardada = Configuracion(
      idConfig: _datos[c.idUsuario]?.idConfig ?? _siguienteId++,
      idUsuario: c.idUsuario,
      sensibilidad: c.sensibilidad,
      velocidadVoz: c.velocidadVoz,
      modoTonos: c.modoTonos,
      volumenMaestro: c.volumenMaestro,
    );
    _datos[c.idUsuario] = guardada;
    return guardada;
  }
}

class RepositorioDestinosMemoria implements RepositorioDestinos {
  RepositorioDestinosMemoria({Iterable<int> usuariosExistentes = const []})
      : _usuarios = usuariosExistentes.toSet();

  final Set<int> _usuarios;
  final Map<int, DestinoFrecuente> _porId = {};
  int _siguienteId = 1;

  @override
  Future<DestinoFrecuente> guardar(DestinoFrecuente d) async {
    if (!_usuarios.contains(d.idUsuario)) throw const UsuarioInexistenteError();
    final repetida = _porId.values.any((x) =>
        x.idUsuario == d.idUsuario &&
        x.etiqueta.toLowerCase() == d.etiqueta.toLowerCase());
    if (repetida) {
      throw const RestriccionVioladaError('ERR-16', 'Ya existe un registro con ese valor.');
    }
    final id = _siguienteId++;
    final nuevo = DestinoFrecuente(
      idDestino: id,
      idUsuario: d.idUsuario,
      etiqueta: d.etiqueta,
      direccion: d.direccion,
      latitud: d.latitud,
      longitud: d.longitud,
    );
    _porId[id] = nuevo;
    return nuevo;
  }

  @override
  Future<DestinoFrecuente?> buscarPorId(int idDestino) async => _porId[idDestino];

  @override
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    final lista = _porId.values.where((d) => d.idUsuario == idUsuario).toList();
    lista.sort((a, b) => a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase()));
    return lista;
  }
}
