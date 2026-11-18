import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../servicios/composicion.dart';
import 'handlers_configuracion.dart';
import 'handlers_destinos.dart';
import 'middleware_cors.dart';
import 'registro_errores.dart';
import 'respuestas.dart';

/// Enruta las operaciones HTTP a servicios; no contiene consultas ni reglas.
class ServidorApi {
  ServidorApi({required this.servicios, RegistroErrores? registro})
    : registro = registro ?? registrarEnConsola.call;

  final ServiciosVista servicios;
  final RegistroErrores registro;

  Handler get handler {
    final configuracion = HandlersConfiguracion(
      servicio: servicios.configuracion,
      registro: registro,
    );
    final destinos = HandlersDestinos(
      servicio: servicios.destinos,
      registro: registro,
    );
    final router = Router()
      ..get('/api/usuarios/<id>/configuracion', configuracion.obtener)
      ..put('/api/usuarios/<id>/configuracion', configuracion.guardar)
      ..post('/api/usuarios/<id>/destinos', destinos.guardar)
      ..get('/api/destinos/<id>', destinos.buscarPorId)
      ..get('/api/usuarios/<id>/destinos', destinos.listarPorUsuario)
      ..all(
        '/<ruta|.*>',
        (Request _) =>
            respuestaJson({'detail': 'Ruta no encontrada.'}, estado: 404),
      );

    return Pipeline().addMiddleware(middlewareCors()).addHandler(router.call);
  }
}
