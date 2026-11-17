import 'package:shelf/shelf.dart';

import '../servicios/destinos_service.dart';
import 'json_destino.dart';
import 'registro_errores.dart';
import 'respuestas.dart';

/// Handlers de RF-DF. Solo parsean la peticion, llaman al servicio y devuelven
/// la respuesta: no contienen SQL ni reglas de negocio.
class HandlersDestinos {
  const HandlersDestinos({required this.servicio, required this.registro});

  final DestinosService servicio;
  final RegistroErrores registro;

  /// POST /api/usuarios/{id}/destinos -> 201 con el destino y su id real.
  Future<Response> guardar(Request peticion, String idUsuario) {
    return ejecutarHandler(
      contexto: 'POST /api/usuarios/{id}/destinos',
      registro: registro,
      accion: () async {
        final id = leerIdDeRuta(idUsuario);
        final cuerpo = await leerCuerpoJson(peticion);
        final datos = datosDestinoDesdeJson(cuerpo);
        final guardado = await servicio.guardar(
          id,
          datos.etiqueta,
          datos.latitud,
          datos.longitud,
          direccion: datos.direccion,
        );
        return respuestaJson(destinoAJson(guardado), estado: 201);
      },
    );
  }

  /// GET /api/destinos/{id}
  Future<Response> buscarPorId(Request peticion, String idDestino) {
    return ejecutarHandler(
      contexto: 'GET /api/destinos/{id}',
      registro: registro,
      accion: () async {
        final destino = await servicio.buscarPorId(leerIdDeRuta(idDestino));
        return respuestaJson(destinoAJson(destino));
      },
    );
  }

  /// GET /api/usuarios/{id}/destinos -> 200 con la lista (puede ser vacia).
  Future<Response> listarPorUsuario(Request peticion, String idUsuario) {
    return ejecutarHandler(
      contexto: 'GET /api/usuarios/{id}/destinos',
      registro: registro,
      accion: () async {
        final destinos = await servicio.listarPorUsuario(leerIdDeRuta(idUsuario));
        return respuestaListaJson(destinos.map(destinoAJson).toList());
      },
    );
  }
}
