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

/// Caso concreto de restriccion violada que el negocio necesita distinguir del
/// resto: ya existe un destino con esa etiqueta para el usuario
/// (UNIQUE (id_usuario, etiqueta) del esquema). Hereda de RestriccionVioladaError
/// para no romper el contrato previo (ERR-16).
class EtiquetaDuplicadaError extends RestriccionVioladaError {
  const EtiquetaDuplicadaError([String etiqueta = ''])
      : super('ERR-16', 'Ya existe un destino con la etiqueta "$etiqueta".');
}
