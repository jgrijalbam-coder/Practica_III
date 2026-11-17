import 'excepciones_dominio.dart';

/// Reglas de RF-DF (destinos frecuentes). Sin HTTP ni SQL.

const double latitudMinima = -90;
const double latitudMaxima = 90;
const double longitudMinima = -180;
const double longitudMaxima = 180;

/// Etiqueta ya recortada. Rechaza vacia (el esquema tiene el mismo CHECK).
String validarEtiqueta(String etiqueta) {
  final limpia = etiqueta.trim();
  if (limpia.isEmpty) {
    throw const ValidacionError('La etiqueta del destino no puede estar vacia.');
  }
  return limpia;
}

/// Latitud obligatoria dentro de -90..90 y longitud dentro de -180..180.
void validarCoordenadas(double latitud, double longitud) {
  if (latitud.isNaN || latitud < latitudMinima || latitud > latitudMaxima) {
    throw const ValidacionError('La latitud debe estar entre -90 y 90.');
  }
  if (longitud.isNaN || longitud < longitudMinima || longitud > longitudMaxima) {
    throw const ValidacionError('La longitud debe estar entre -180 y 180.');
  }
}

/// La columna `direccion` es NOT NULL en el esquema y RF-DF no la pide en la
/// API (solo etiqueta y coordenadas). Cuando el cliente no la envia se deriva
/// un texto legible con las coordenadas, para no romper el esquema.
String derivarDireccion(String? direccionRecibida, double latitud, double longitud) {
  final limpia = (direccionRecibida ?? '').trim();
  if (limpia.isNotEmpty) return limpia;
  return 'Lat $latitud, Lon $longitud';
}
