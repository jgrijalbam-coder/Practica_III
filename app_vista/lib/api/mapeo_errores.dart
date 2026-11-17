import '../dominio/excepciones_dominio.dart';

/// Traduccion de excepciones de negocio a codigos HTTP. Es el UNICO lugar de la
/// API que decide el codigo de estado de un error.

class RespuestaError {
  const RespuestaError(this.estado, this.detalle);

  final int estado;
  final String detalle;

  bool get esFalloInterno => estado >= 500;
}

/// Un error interno (500) siempre responde con un mensaje generico: los
/// detalles tecnicos se registran en el servidor y no se devuelven al cliente.
const String mensajeErrorInterno = 'Error interno del servidor.';

RespuestaError mapearError(Object error) {
  if (error is ValidacionError) {
    return RespuestaError(400, error.mensaje);
  }
  if (error is UsuarioNoEncontrado ||
      error is ConfiguracionNoEncontrada ||
      error is DestinoNoEncontrado) {
    return RespuestaError(404, (error as ErrorDominio).mensaje);
  }
  if (error is EtiquetaDuplicada) {
    return RespuestaError(409, error.mensaje);
  }
  return const RespuestaError(500, mensajeErrorInterno);
}
