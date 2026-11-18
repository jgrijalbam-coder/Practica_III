import 'package:shelf/shelf.dart';

import '../servicios/configuracion_service.dart';
import 'json_configuracion.dart';
import 'lectura_json.dart';
import 'registro_errores.dart';
import 'respuestas.dart';

/// Handlers de RF-10. Solo parsean la peticion, llaman al servicio y devuelven
/// la respuesta: no contienen SQL ni reglas de negocio.
class HandlersConfiguracion {
  const HandlersConfiguracion({required this.servicio, required this.registro});

  final ConfiguracionService servicio;
  final RegistroErrores registro;

  /// GET /api/usuarios/{id}/configuracion
  Future<Response> obtener(Request peticion, String idUsuario) {
    return ejecutarHandler(
      contexto: 'GET /api/usuarios/{id}/configuracion',
      registro: registro,
      accion: () async {
        final configuracion = await servicio.obtener(leerIdDeRuta(idUsuario));
        return respuestaJson(configuracionAJson(configuracion));
      },
    );
  }

  /// PUT /api/usuarios/{id}/configuracion
  Future<Response> guardar(Request peticion, String idUsuario) {
    return ejecutarHandler(
      contexto: 'PUT /api/usuarios/{id}/configuracion',
      registro: registro,
      accion: () async {
        final id = leerIdDeRuta(idUsuario);
        final cuerpo = await leerCuerpoJson(peticion);
        final guardada = await servicio.guardar(
          id,
          datosConfiguracionDesdeJson(cuerpo),
        );
        return respuestaJson(configuracionAJson(guardada));
      },
    );
  }
}
