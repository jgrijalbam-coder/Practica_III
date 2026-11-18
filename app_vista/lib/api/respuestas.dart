import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../dominio/excepciones_dominio.dart';
import 'mapeo_errores.dart';
import 'registro_errores.dart';

Response respuestaJson(Object? datos, {int estado = 200}) => Response(
  estado,
  body: jsonEncode(datos),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Response respuestaListaJson(List<Object?> datos) => respuestaJson(datos);

/// Convierte errores de negocio y de entrada en HTTP. Los errores inesperados
/// se registran en el servidor y su detalle tecnico nunca se envia al cliente.
Future<Response> ejecutarHandler({
  required String contexto,
  required RegistroErrores registro,
  required Future<Response> Function() accion,
}) async {
  try {
    return await accion();
  } catch (error, pila) {
    if (error is! ErrorDominio) registro(contexto, error, pila);
    final mapeo = mapearError(error);
    return respuestaJson({'detail': mapeo.detalle}, estado: mapeo.estado);
  }
}
