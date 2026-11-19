import '../datos/errores_persistencia.dart';
import '../datos/modelos_datos.dart';
import '../datos/repositorio_destinos.dart';
import '../datos/repositorio_usuarios.dart';
import '../dominio/excepciones_dominio.dart';
import '../dominio/reglas_configuracion.dart' show validarIdPositivo;
import '../dominio/reglas_destinos.dart';

/// Logica de negocio de RF-14 (destinos frecuentes, HU-8).
///
/// No conoce HTTP ni SQL: depende de las interfaces abstractas de repositorio,
/// inyectadas por constructor.
///
/// Transacciones y conexiones: aqui no se abre ninguna conexion ni se manejan
/// transacciones. El repositorio ejecuta una sentencia atomica por operacion y
/// la conexion la cierra quien la abrio (`BaseDatos.cerrar()`).
class DestinosService {
  DestinosService({
    required this.usuarios,
    required this.destinos,
  });

  final RepositorioUsuarios usuarios;
  final RepositorioDestinos destinos;

  /// Guarda un destino del usuario y lo devuelve con su id real.
  ///
  /// Reglas: etiqueta no vacia tras recortar (unica por usuario sin distinguir
  /// mayusculas), latitud -90..90 y longitud -180..180 obligatorias. La
  /// `direccion` es opcional en la API: si falta se deriva de las coordenadas
  /// porque la columna es NOT NULL en el esquema.
  Future<DestinoFrecuente> guardar(
    int idUsuario,
    String etiqueta,
    double latitud,
    double longitud, {
    String? direccion,
  }) async {
    validarIdPositivo(idUsuario, campo: 'id_usuario');
    final etiquetaLimpia = validarEtiqueta(etiqueta);
    validarCoordenadas(latitud, longitud);
    await _exigirUsuario(idUsuario);

    final destino = DestinoFrecuente(
      idUsuario: idUsuario,
      etiqueta: etiquetaLimpia,
      direccion: derivarDireccion(direccion, latitud, longitud),
      latitud: latitud,
      longitud: longitud,
    );

    final guardado = await _guardarEnRepositorio(destino);

    // Confirmacion de escritura: se relee por id antes de responder.
    final idReal = guardado.idDestino;
    if (idReal == null) {
      throw const ErrorPersistencia(
          'ERR-16', 'No se obtuvo el identificador del destino guardado.');
    }
    final confirmado = await destinos.buscarPorId(idReal);
    if (confirmado == null) {
      throw const ErrorPersistencia(
          'ERR-16', 'No se pudo confirmar el destino guardado.');
    }
    return confirmado;
  }

  /// Destino por id. Ausente -> DestinoNoEncontrado (404 en la API).
  Future<DestinoFrecuente> buscarPorId(int idDestino) async {
    validarIdPositivo(idDestino, campo: 'id_destino');
    final destino = await destinos.buscarPorId(idDestino);
    if (destino == null) {
      throw DestinoNoEncontrado(idDestino);
    }
    return destino;
  }

  /// Destinos del usuario ordenados por etiqueta. Puede ser vacia (200).
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    validarIdPositivo(idUsuario, campo: 'id_usuario');
    await _exigirUsuario(idUsuario);
    return destinos.listarPorUsuario(idUsuario);
  }

  Future<DestinoFrecuente> _guardarEnRepositorio(DestinoFrecuente destino) async {
    try {
      return await destinos.guardar(destino);
    } on UsuarioInexistenteError {
      // La clave foranea confirma que el usuario desaparecio entre la
      // verificacion y la escritura.
      throw UsuarioNoEncontrado(destino.idUsuario);
    } on EtiquetaDuplicadaError {
      throw EtiquetaDuplicada(destino.etiqueta);
    } on RestriccionVioladaError catch (e) {
      // Cualquier otro CHECK (rango de coordenadas, texto vacio) es ERR-15.
      throw ValidacionError(e.mensaje);
    }
  }

  Future<void> _exigirUsuario(int idUsuario) async {
    final usuario = await usuarios.buscarPorId(idUsuario);
    if (usuario == null) {
      throw UsuarioNoEncontrado(idUsuario);
    }
  }
}
