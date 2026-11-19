import 'modelos_datos.dart';

/// CONTRATO de RF-14.
abstract class RepositorioDestinos {
  /// Guarda y devuelve el destino con su id real.
  /// Lanza RestriccionVioladaError (etiqueta repetida o valor invalido) o UsuarioInexistenteError.
  Future<DestinoFrecuente> guardar(DestinoFrecuente destino);

  /// Destino por id, o null si no existe.
  Future<DestinoFrecuente?> buscarPorId(int idDestino);

  /// Destinos del usuario ordenados por etiqueta.
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario);
}
