import 'modelos_datos.dart';

class CredencialesGuardadas {
  const CredencialesGuardadas({required this.usuario, required this.hash});

  final Usuario usuario;
  final String hash;
}

abstract class RepositorioAutenticacion {
  Future<CredencialesGuardadas?> buscarPorCorreo(String correo);

  /// Crea la cuenta y sus preferencias iniciales en una transacción.
  Future<Usuario> crearCuenta({
    required String nombre,
    required String correo,
    required String hashContrasena,
  });
}
