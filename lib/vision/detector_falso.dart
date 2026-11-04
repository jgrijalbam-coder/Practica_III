import 'dart:async';
import '../modelos/deteccion.dart';
import '../modelos/enums.dart';
import 'detector_obstaculos.dart';

/// Versión de mentira para avanzar sin cámara ni modelo.
class DetectorFalso implements DetectorObstaculos {
  final _control = StreamController<Deteccion>.broadcast();
  Timer? _timer;
  double _umbral = 0.5;
  int _i = 0;

  @override
  Stream<Deteccion> get detecciones => _control.stream;

  @override
  set umbralConfianza(double valor) => _umbral = valor;

  @override
  Future<void> iniciar() async {
    final ejemplos = [
      (3.5, Sector.frente),
      (2.0, Sector.izquierda),
      (1.0, Sector.frente),
      (2.2, Sector.derecha),
    ];
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final e = ejemplos[_i++ % ejemplos.length];
      const confianza = 0.9;
      if (confianza < _umbral) return;
      _control.add(Deteccion(
        clase: 'persona',
        confianza: confianza,
        distanciaMetros: e.$1,
        sector: e.$2,
      ));
    });
  }

  @override
  Future<void> detener() async {
    _timer?.cancel();
    _timer = null;
  }
}
