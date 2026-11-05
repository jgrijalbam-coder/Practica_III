import 'modelos_datos.dart';

/// CONTRATO: negocio usa esto para verificar que el usuario existe.
abstract class RepositorioUsuarios {
  Future<Usuario?> buscarPorId(int idUsuario);
}
