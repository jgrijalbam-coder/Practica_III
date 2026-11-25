import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../servicios/composicion.dart';
import 'handlers_configuracion.dart';
import 'handlers_destinos.dart';
import 'handlers_autenticacion.dart';
import 'handlers_usuarios.dart';
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
    final autenticacion = HandlersAutenticacion(
      servicio: servicios.autenticacion,
      registro: registro,
    );
    final usuarios = HandlersUsuarios(servicios: servicios, registro: registro);
    final router = Router()
      ..post('/api/auth/register', autenticacion.registrar)
      ..post('/api/auth/login', autenticacion.iniciarSesion)
      ..get('/api/usuarios/<id>', usuarios.obtener)
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
