import 'modelos_datos.dart';

/// CONTRATO de RF-10. Los servicios de la semana 2 dependen de esta interfaz.
abstract class RepositorioConfiguracion {
  /// Configuracion del usuario, o null si no tiene.
  Future<Configuracion?> obtener(int idUsuario);

  /// Inserta o actualiza (una por usuario) y devuelve lo guardado.
  /// Lanza RestriccionVioladaError (valor fuera de rango) o UsuarioInexistenteError.
  Future<Configuracion> guardar(Configuracion configuracion);
}
