import 'package:app_vista/datos/errores_persistencia.dart';
import 'package:app_vista/datos/modelos_datos.dart';
import 'package:app_vista/datos/repositorio_configuracion.dart';
import 'package:app_vista/datos/repositorio_destinos.dart';
import 'package:app_vista/datos/repositorio_usuarios.dart';

/// Dobles de prueba con contador de llamadas (RFN-06).
///
/// No abren conexion real: permiten comprobar que el servicio NO escribe cuando
/// rechaza y que solo lee cuando consulta.

class EspiaUsuarios implements RepositorioUsuarios {
  EspiaUsuarios({Iterable<int> existentes = const []})
      : existentes = existentes.toSet();

  final Set<int> existentes;
  int llamadasBuscarPorId = 0;

  @override
  Future<Usuario?> buscarPorId(int idUsuario) async {
    llamadasBuscarPorId++;
    if (!existentes.contains(idUsuario)) return null;
    return Usuario(
      idUsuario: idUsuario,
      nombre: 'Usuario $idUsuario',
      correo: 'usuario$idUsuario@vista.test',
    );
  }
}

class EspiaConfiguracion implements RepositorioConfiguracion {
  EspiaConfiguracion({Configuracion? inicial}) : _actual = inicial;

  Configuracion? _actual;
  int llamadasObtener = 0;
  int llamadasGuardar = 0;
  int _siguienteId = 1;

  Configuracion? get actual => _actual;

  @override
  Future<Configuracion?> obtener(int idUsuario) async {
    llamadasObtener++;
    return _actual?.idUsuario == idUsuario ? _actual : null;
  }

  @override
  Future<Configuracion> guardar(Configuracion configuracion) async {
    llamadasGuardar++;
    _actual = Configuracion(
      idConfig: _actual?.idConfig ?? _siguienteId++,
      idUsuario: configuracion.idUsuario,
      sensibilidad: configuracion.sensibilidad,
      velocidadVoz: configuracion.velocidadVoz,
      modoTonos: configuracion.modoTonos,
      volumenMaestro: configuracion.volumenMaestro,
      fechaActualizacion: DateTime.utc(2026, 11, 17, 12),
    );
    return _actual!;
  }
}

class EspiaDestinos implements RepositorioDestinos {
  final Map<int, DestinoFrecuente> guardados = {};
  int llamadasGuardar = 0;
  int llamadasBuscarPorId = 0;
  int llamadasListarPorUsuario = 0;
  int _siguienteId = 1;

  /// Si es true, `guardar` simula la UNIQUE (id_usuario, etiqueta) del esquema.
  bool rechazarPorEtiquetaDuplicada = false;

  @override
  Future<DestinoFrecuente> guardar(DestinoFrecuente destino) async {
    llamadasGuardar++;
    if (rechazarPorEtiquetaDuplicada) {
      throw EtiquetaDuplicadaError(destino.etiqueta);
    }
    final id = _siguienteId++;
    final nuevo = DestinoFrecuente(
      idDestino: id,
      idUsuario: destino.idUsuario,
      etiqueta: destino.etiqueta,
      direccion: destino.direccion,
      latitud: destino.latitud,
      longitud: destino.longitud,
    );
    guardados[id] = nuevo;
    return nuevo;
  }

  @override
  Future<DestinoFrecuente?> buscarPorId(int idDestino) async {
    llamadasBuscarPorId++;
    return guardados[idDestino];
  }

  @override
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    llamadasListarPorUsuario++;
    final lista =
        guardados.values.where((d) => d.idUsuario == idUsuario).toList();
    lista.sort((a, b) => a.etiqueta.compareTo(b.etiqueta));
    return lista;
  }
}
