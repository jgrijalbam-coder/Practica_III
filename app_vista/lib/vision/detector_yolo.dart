import 'dart:async';
import '../modelos/deteccion.dart';
import 'detector_obstaculos.dart';

class DetectorYolo implements DetectorObstaculos {
  final StreamController<Deteccion> _controller = StreamController<Deteccion>.broadcast();

  double _confianza = 0.5;

  @override
  Stream<Deteccion> get detecciones => _controller.stream;

  @override
  set umbralConfianza(double valor) {
    _confianza = valor;
  }

  @override
  Future<void> iniciar() async {
    // Implementar aquí la ejecución real del modelo sobre los bytes RGB 320×320.
  }

  @override
  Future<void> detener() async {
    // Sin ejecución activa mientras no haya modelo conectado.
  }
}