import 'dart:async';
import '../modelos/deteccion.dart';

abstract class DetectorObstaculos {
  Stream<Deteccion> get detecciones;
  set umbralConfianza(double valor);
  Future<void> iniciar();
  Future<void> detener();
}
