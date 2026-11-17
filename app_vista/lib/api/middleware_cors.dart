import 'package:shelf/shelf.dart';

/// Origenes locales permitidos para la interfaz de la semana 3.
/// CORS existe porque el frontend corre en otro origen (por ejemplo
/// http://localhost:3000) y el navegador exige la cabecera en cada respuesta.
const List<String> origenesLocalesPermitidos = [
  'http://localhost',
  'http://127.0.0.1',
];

bool origenPermitido(String? origen) {
  if (origen == null) return false;
  for (final base in origenesLocalesPermitidos) {
    if (origen == base || origen.startsWith('$base:')) return true;
  }
  return false;
}

Map<String, String> cabecerasCors(String? origen) {
  final cabeceras = <String, String>{
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
  if (origenPermitido(origen)) {
    cabeceras['Access-Control-Allow-Origin'] = origen!;
  }
  return cabeceras;
}

/// Agrega las cabeceras CORS y responde el preflight (OPTIONS) sin llegar al
/// enrutador: ninguna regla de negocio se ejecuta en un preflight.
Middleware middlewareCors() {
  return (Handler siguiente) {
    return (Request peticion) async {
      final origen = peticion.headers['origin'];
      if (peticion.method == 'OPTIONS') {
        return Response.ok('', headers: cabecerasCors(origen));
      }
      final respuesta = await siguiente(peticion);
      return respuesta.change(headers: cabecerasCors(origen));
    };
  };
}
