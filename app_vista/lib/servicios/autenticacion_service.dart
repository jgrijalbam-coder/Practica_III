import '../datos/modelos_datos.dart';
import '../datos/repositorio_autenticacion.dart';
import '../seguridad/hasheador_contrasenas.dart';

class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);
  final String mensaje;
}

class AutenticacionService {
  AutenticacionService({
    required this.repositorio,
    HasheadorContrasenas? hasheador,
  }) : _hasheador = hasheador ?? HasheadorContrasenas();

  final RepositorioAutenticacion repositorio;
  final HasheadorContrasenas _hasheador;

  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final nombreLimpio = nombre.trim();
    final correoLimpio = correo.trim().toLowerCase();
    if (nombreLimpio.isEmpty) {
      throw const ErrorAutenticacion('Escribe tu nombre.');
    }
    if (!_correoValido(correoLimpio)) {
      throw const ErrorAutenticacion('Escribe un correo válido.');
    }
    if (contrasena.length < 8) {
      throw const ErrorAutenticacion(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }
    if (await repositorio.buscarPorCorreo(correoLimpio) != null) {
      throw const ErrorAutenticacion('Ya existe una cuenta con ese correo.');
    }
    final hash = await _hasheador.crearHash(contrasena);
    try {
      return await repositorio.crearCuenta(
        nombre: nombreLimpio,
        correo: correoLimpio,
        hashContrasena: hash,
      );
    } catch (_) {
      throw const ErrorAutenticacion('No se pudo crear la cuenta. Inténtalo otra vez.');
    }
  }

  Future<Usuario> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final correoLimpio = correo.trim().toLowerCase();
    final credenciales = await repositorio.buscarPorCorreo(correoLimpio);
    if (credenciales == null ||
        !await _hasheador.verificar(contrasena, credenciales.hash)) {
      throw const ErrorAutenticacion('Correo o contraseña incorrectos.');
    }
    return credenciales.usuario;
  }

  bool _correoValido(String correo) {
    final partes = correo.split('@');
    return partes.length == 2 &&
        partes.first.isNotEmpty &&
        partes.last.contains('.') &&
        !partes.last.startsWith('.') &&
        !partes.last.endsWith('.');
  }
}
