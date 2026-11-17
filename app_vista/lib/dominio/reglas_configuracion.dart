import '../datos/modelos_datos.dart';
import 'excepciones_dominio.dart';

/// Reglas de RF-10 (configurar preferencias). Viven en el dominio, sin HTTP ni
/// SQL, para que las use el servicio y las pantallas de la semana 3.
///
/// TODO (RN-06 / RN-14): el README del proyecto no documenta el texto de RN-06
/// ni de RN-14, asi que no se inventan reglas. Este archivo solo aplica los
/// rangos del enunciado de RF-10, que coinciden con los CHECK de
/// `db/schema.sql`. Cuando el equipo formalice RN-06 y RN-14 se agregan aqui.

/// Sensibilidades que acepta el motor de deteccion (RF-10).
/// No puede ser `const`: los `double` no tienen igualdad primitiva.
const List<double> sensibilidadesPermitidas = [0.4, 0.5, 0.7];

/// Valores por defecto del enunciado, usados si el cliente no envia el campo.
const double sensibilidadDefecto = 0.5;
const double velocidadVozDefecto = 1.2;
const ModoTonos modoTonosDefecto = ModoTonos.frecuenciaSimple;
const int volumenMaestroDefecto = 60;

const double velocidadVozMinima = 0.8;
const double velocidadVozMaxima = 2.0;
const int volumenMaestroMinimo = 50;
const int volumenMaestroMaximo = 95;

/// Entrada del servicio `guardar`: lo que la persona eligio en la pantalla.
/// No lleva `idUsuario` porque el servicio lo recibe como parametro de ruta.
class DatosConfiguracion {
  const DatosConfiguracion({
    this.sensibilidad = sensibilidadDefecto,
    this.velocidadVoz = velocidadVozDefecto,
    this.modoTonos = modoTonosDefecto,
    this.volumenMaestro = volumenMaestroDefecto,
  });

  final double sensibilidad;
  final double velocidadVoz;
  final ModoTonos modoTonos;
  final int volumenMaestro;
}

/// Valida el id antes de tocar la base: entero positivo.
void validarIdPositivo(int id, {String campo = 'id'}) {
  if (id <= 0) {
    throw ValidacionError('El $campo debe ser un entero positivo.');
  }
}

/// Aplica los rangos de RF-10 y lanza ValidacionError (ERR-15) si algo falla.
void validarConfiguracion(DatosConfiguracion datos) {
  if (!sensibilidadesPermitidas.contains(datos.sensibilidad)) {
    throw const ValidacionError('La sensibilidad debe ser 0.4, 0.5 o 0.7.');
  }
  if (datos.velocidadVoz < velocidadVozMinima ||
      datos.velocidadVoz > velocidadVozMaxima) {
    throw const ValidacionError(
        'La velocidad de voz debe estar entre 0.8 y 2.0.');
  }
  if (datos.volumenMaestro < volumenMaestroMinimo ||
      datos.volumenMaestro > volumenMaestroMaximo) {
    throw const ValidacionError(
        'El volumen maestro debe estar entre 50 y 95.');
  }
}
