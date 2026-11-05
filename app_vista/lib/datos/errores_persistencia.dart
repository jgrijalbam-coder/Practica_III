/// Errores de persistencia con el codigo del catalogo de errores de VISTA.
/// ERR-15: valor no permitido. ERR-16: no se pudo guardar.
class ErrorPersistencia implements Exception {
  final String codigo;
  final String mensaje;
  const ErrorPersistencia(this.codigo, this.mensaje);

  @override
  String toString() => '$codigo: $mensaje';
}

class UsuarioInexistenteError extends ErrorPersistencia {
  const UsuarioInexistenteError() : super('ERR-16', 'No existe el usuario indicado.');
}

class RestriccionVioladaError extends ErrorPersistencia {
  const RestriccionVioladaError(super.codigo, super.mensaje);
}
