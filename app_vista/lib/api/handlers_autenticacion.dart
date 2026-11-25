import 'package:shelf/shelf.dart';

import '../servicios/autenticacion_service.dart';
import '../dominio/excepciones_dominio.dart';
import 'lectura_json.dart';
import 'registro_errores.dart';
import 'respuestas.dart';

class HandlersAutenticacion {
  const HandlersAutenticacion({required this.servicio, required this.registro});

  final AutenticacionService servicio;
  final RegistroErrores registro;

  Future<Response> registrar(Request request) => _ejecutar(
    request,
    'POST /api/auth/register',
    (datos) => servicio.registrar(
      nombre: _requerido(datos, 'nombre'),
      correo: _requerido(datos, 'correo'),
      contrasena: _requerido(datos, 'contrasena'),
    ),
    estado: 201,
  );

  Future<Response> iniciarSesion(Request request) => _ejecutar(
    request,
    'POST /api/auth/login',
    (datos) => servicio.iniciarSesion(
      correo: _requerido(datos, 'correo'),
      contrasena: _requerido(datos, 'contrasena'),
    ),
    estado: 200,
  );

  Future<Response> _ejecutar(
    Request request,
    String contexto,
    Future<dynamic> Function(Map<String, Object?>) accion, {
    required int estado,
  }) async {
    try {
      final datos = await leerCuerpoJson(request);
      final usuario = await accion(datos);
      return respuestaJson({
        'id_usuario': usuario.idUsuario,
        'nombre': usuario.nombre,
        'correo': usuario.correo,
      }, estado: estado);
    } on ErrorAutenticacion catch (e) {
      return respuestaJson({'detail': e.mensaje}, estado: 401);
    } on ValidacionError catch (e) {
      return respuestaJson({'detail': e.mensaje}, estado: 400);
    } catch (error, stack) {
      registro(contexto, error, stack);
      return respuestaJson({
        'detail': 'Error interno del servidor.',
      }, estado: 500);
    }
  }

  String _requerido(Map<String, Object?> json, String campo) {
    final valor = leerTextoOpcional(json, campo);
    if (valor == null) throw ValidacionError('Falta el campo "$campo".');
    return valor;
  }
}
