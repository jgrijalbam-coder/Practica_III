/// Error propio de VISTA con código del catálogo (ERR-01, ERR-02, ...).
class ErrorVista implements Exception {
  final String codigo;
  final String mensajeUsuario;
  final Object? causa;
  ErrorVista(this.codigo, this.mensajeUsuario, [this.causa]);

  @override
  String toString() => '$codigo: $mensajeUsuario';
}
