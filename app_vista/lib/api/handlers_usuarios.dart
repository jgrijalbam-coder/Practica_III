import 'package:shelf/shelf.dart';

import '../dominio/excepciones_dominio.dart';
import '../servicios/composicion.dart';
import 'lectura_json.dart';
import 'registro_errores.dart';
import 'respuestas.dart';

class HandlersUsuarios {
  const HandlersUsuarios({required this.servicios, required this.registro});

  final ServiciosVista servicios;
  final RegistroErrores registro;

  Future<Response> obtener(Request request, String idTexto) async {
    try {
      final id = leerIdDeRuta(idTexto);
      final usuario = await servicios.usuarios.buscarPorId(id);
      if (usuario == null) {
        return respuestaJson({
          'detail': 'No existe el usuario $id.',
        }, estado: 404);
      }
      return respuestaJson({
        'id_usuario': usuario.idUsuario,
        'nombre': usuario.nombre,
        'correo': usuario.correo,
      });
    } on ValidacionError catch (e) {
      return respuestaJson({'detail': e.mensaje}, estado: 400);
    } catch (error, stack) {
      registro('GET /api/usuarios/{id}', error, stack);
      return respuestaJson({
        'detail': 'Error interno del servidor.',
      }, estado: 500);
    }
  }
}
