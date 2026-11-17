import '../datos/errores_persistencia.dart';
import '../datos/modelos_datos.dart';
import '../datos/repositorio_configuracion.dart';
import '../datos/repositorio_usuarios.dart';
import '../dominio/excepciones_dominio.dart';
import '../dominio/reglas_configuracion.dart';

/// Logica de negocio de RF-10 (configurar preferencias).
///
/// No conoce HTTP ni SQL: recibe los repositorios por constructor (inyeccion de
/// dependencias) y solo habla con sus interfaces abstractas.
///
/// Transacciones y conexiones: este servicio NO abre conexiones ni administra
/// transacciones. Cada llamada al repositorio es una sentencia atomica que el
/// propio repositorio confirma o revierte sobre la conexion que le prestaron; la
/// conexion la cierra quien la abrio con `BaseDatos.cerrar()`.
class ConfiguracionService {
  ConfiguracionService({
    required this.usuarios,
    required this.configuracion,
  });

  final RepositorioUsuarios usuarios;
  final RepositorioConfiguracion configuracion;

  /// Preferencias vigentes del usuario.
  ///
  /// Rechaza con `ValidacionError` si el id no es positivo, con
  /// `UsuarioNoEncontrado` si el usuario no existe y con
  /// `ConfiguracionNoEncontrada` si existe pero nunca guardo preferencias.
  /// Decision de la semana 2: la ausencia es 404; no se devuelven valores por
  /// defecto porque el README no lo autoriza.
  Future<Configuracion> obtener(int idUsuario) async {
    validarIdPositivo(idUsuario, campo: 'id_usuario');
    await _exigirUsuario(idUsuario);

    final configuracionActual = await configuracion.obtener(idUsuario);
    if (configuracionActual == null) {
      throw ConfiguracionNoEncontrada(idUsuario);
    }
    return configuracionActual;
  }

  /// Guarda las preferencias (inserta o actualiza la unica fila del usuario) y
  /// devuelve la configuracion tal como quedo almacenada.
  Future<Configuracion> guardar(int idUsuario, DatosConfiguracion datos) async {
    validarIdPositivo(idUsuario, campo: 'id_usuario');
    validarConfiguracion(datos);
    await _exigirUsuario(idUsuario);

    await _guardarEnRepositorio(idUsuario, datos);

    // Confirmacion de escritura: se vuelve a leer antes de responder para no
    // devolver un objeto que no llego a la base.
    final confirmada = await configuracion.obtener(idUsuario);
    if (confirmada == null) {
      throw const ErrorPersistencia(
          'ERR-16', 'No se pudo confirmar la configuracion guardada.');
    }
    return confirmada;
  }

  Future<Configuracion> _guardarEnRepositorio(
    int idUsuario,
    DatosConfiguracion datos,
  ) async {
    try {
      return await configuracion.guardar(Configuracion(
        idUsuario: idUsuario,
        sensibilidad: datos.sensibilidad,
        velocidadVoz: datos.velocidadVoz,
        modoTonos: datos.modoTonos,
        volumenMaestro: datos.volumenMaestro,
      ));
    } on UsuarioInexistenteError {
      throw UsuarioNoEncontrado(idUsuario);
    } on RestriccionVioladaError catch (e) {
      // Los CHECK del esquema refuerzan los rangos de RF-10: si llegaran a
      // saltar es porque la entrada era invalida (ERR-15).
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
