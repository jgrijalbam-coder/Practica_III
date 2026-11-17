import '../datos/modelos_datos.dart';
import '../dominio/excepciones_dominio.dart';
import '../dominio/reglas_configuracion.dart';
import 'lectura_json.dart';

/// Serializacion de RF-10 entre el servicio y el JSON de la API.
/// JSON en snake_case y con los nombres reales de columna del esquema.

Map<String, Object?> configuracionAJson(Configuracion configuracion) {
  return {
    'sensibilidad': configuracion.sensibilidad,
    'velocidad_voz': configuracion.velocidadVoz,
    'modo_tonos': configuracion.modoTonos.valorBd,
    'volumen_maestro': configuracion.volumenMaestro,
    'fecha_actualizacion': configuracion.fechaActualizacion?.toIso8601String(),
  };
}

/// Lee el cuerpo de `PUT /api/usuarios/{id}/configuracion`.
///
/// Todos los campos son opcionales: lo que falta toma el valor por defecto del
/// enunciado. Un campo presente con tipo o valor invalido es ERR-15 (y el
/// servicio lo vuelve a validar por rango).
DatosConfiguracion datosConfiguracionDesdeJson(Map<String, Object?> json) {
  final modoTonosTexto = leerTextoOpcional(json, 'modo_tonos');
  return DatosConfiguracion(
    sensibilidad: leerDoubleOpcional(json, 'sensibilidad') ??
        sensibilidadDefecto,
    velocidadVoz:
        leerDoubleOpcional(json, 'velocidad_voz') ?? velocidadVozDefecto,
    modoTonos: modoTonosTexto == null
        ? modoTonosDefecto
        : modoTonosDesdeTexto(modoTonosTexto),
    volumenMaestro:
        leerEnteroOpcional(json, 'volumen_maestro') ?? volumenMaestroDefecto,
  );
}

/// Traduce el texto de `modo_tonos` al enum; cualquier otro valor es ERR-15.
ModoTonos modoTonosDesdeTexto(String texto) {
  for (final modo in ModoTonos.values) {
    if (modo.valorBd == texto) return modo;
  }
  throw const ValidacionError(
      'El modo de tonos debe ser "frecuencia_simple" o "espacializada".');
}
