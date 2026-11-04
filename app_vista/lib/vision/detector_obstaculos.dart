import '../modelos/deteccion.dart';

/// CONTRATO del módulo de visión (Jessica).
abstract class DetectorObstaculos {
  Stream<Deteccion> get detecciones;
  Future<void> iniciar();
  Future<void> detener();

  /// Umbral de confianza: 0.4, 0.5 (por defecto) o 0.7.
  set umbralConfianza(double valor);
}
