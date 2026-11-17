/// Excepciones de negocio de VISTA (semana 14).
///
/// La capa de servicios las lanza; la capa de API las traduce a codigos HTTP.
/// No conocen HTTP ni SQL: solo describen que regla fallo.
///
/// Codigos del catalogo: ERR-15 (valor no permitido) y ERR-16 (no se pudo
/// guardar o el dato no existe). Se reutilizan los ya usados en persistencia.
abstract class ErrorDominio implements Exception {
  const ErrorDominio(this.codigo, this.mensaje);

  /// Codigo del catalogo de errores de VISTA.
  final String codigo;

  /// Mensaje apto para el usuario final (sin detalles tecnicos).
  final String mensaje;

  @override
  String toString() => '$codigo: $mensaje';
}

/// Entrada invalida: id no positivo, texto vacio o valor fuera de rango.
/// Corresponde a ERR-15 y a las restricciones CHECK del esquema.
class ValidacionError extends ErrorDominio {
  const ValidacionError(String mensaje) : super('ERR-15', mensaje);
}

/// El usuario indicado no existe en la base de datos.
class UsuarioNoEncontrado extends ErrorDominio {
  const UsuarioNoEncontrado(int idUsuario)
      : super('ERR-16', 'No existe el usuario $idUsuario.');
}

/// El usuario existe pero todavia no guardo sus preferencias.
class ConfiguracionNoEncontrada extends ErrorDominio {
  const ConfiguracionNoEncontrada(int idUsuario)
      : super('ERR-16', 'El usuario $idUsuario no tiene configuracion guardada.');
}

/// El destino frecuente solicitado no existe.
class DestinoNoEncontrado extends ErrorDominio {
  const DestinoNoEncontrado(int idDestino)
      : super('ERR-16', 'No existe el destino $idDestino.');
}

/// Ya hay un destino con esa etiqueta para el usuario (UNIQUE sin distinguir
/// mayusculas). Es un conflicto de negocio, no un fallo tecnico.
class EtiquetaDuplicada extends ErrorDominio {
  const EtiquetaDuplicada(String etiqueta)
      : super('ERR-16', 'El usuario ya tiene un destino con la etiqueta "$etiqueta".');
}
