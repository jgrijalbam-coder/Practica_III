import '../datos/modelos_datos.dart';
import '../dominio/excepciones_dominio.dart';
import 'lectura_json.dart';

Map<String, Object?> destinoAJson(DestinoFrecuente destino) => {
  'id_destino': destino.idDestino,
  'id_usuario': destino.idUsuario,
  'etiqueta': destino.etiqueta,
  'latitud': destino.latitud,
  'longitud': destino.longitud,
};

class DatosDestino {
  const DatosDestino({
    required this.etiqueta,
    required this.latitud,
    required this.longitud,
    this.direccion,
  });

  final String etiqueta;
  final double latitud;
  final double longitud;
  final String? direccion;
}

DatosDestino datosDestinoDesdeJson(Map<String, Object?> json) {
  final etiqueta = leerTextoOpcional(json, 'etiqueta');
  final latitud = leerDoubleOpcional(json, 'latitud');
  final longitud = leerDoubleOpcional(json, 'longitud');
  if (etiqueta == null || latitud == null || longitud == null) {
    throw const ValidacionError('Se requieren etiqueta, latitud y longitud.');
  }
  return DatosDestino(
    etiqueta: etiqueta,
    latitud: latitud,
    longitud: longitud,
    direccion: leerTextoOpcional(json, 'direccion'),
  );
}
