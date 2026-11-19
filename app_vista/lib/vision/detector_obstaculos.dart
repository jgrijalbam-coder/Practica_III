import '../modelos/deteccion.dart';

/// Contrato común para los detectores de obstáculos.
abstract class DetectorObstaculos {
  Stream<Deteccion> get detecciones;

  set umbralConfianza(double valor);

  Future<void> iniciar();

  Future<void> detener();
}
