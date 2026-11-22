import 'dart:async';

import '../modelos/deteccion.dart';
import '../modelos/enums.dart';
import 'detector_obstaculos.dart';
import 'resultado_yolo.dart';

class DetectorYolo implements DetectorObstaculos {
  final StreamController<Deteccion> _controller =
      StreamController<Deteccion>.broadcast();

  double _confianza = 0.5;
  bool _activo = false;
  final Map<String, DateTime> _ultimaEmision = {};

  static const _intervaloAlerta = Duration(seconds: 2);

  @override
  Stream<Deteccion> get detecciones => _controller.stream;

  @override
  set umbralConfianza(double valor) {
    _confianza = valor;
  }

  @override
  Future<void> iniciar() async {
    _activo = true;
  }

  @override
  Future<void> detener() async {
    _activo = false;
    _ultimaEmision.clear();
  }

  /// Recibe resultados reales de YOLOView, que ejecuta inferencia en Android/iOS.
  void publicarResultados(Iterable<ResultadoYolo> resultados) {
    if (!_activo) return;

    final ahora = DateTime.now();
    for (final resultado in resultados) {
      if (resultado.confianza < _confianza) continue;

      final centroX = resultado.centroX;
      final sector = centroX < 0.35
          ? Sector.izquierda
          : centroX > 0.65
          ? Sector.derecha
          : Sector.frente;
      final clave = '${resultado.etiqueta}:$sector';
      final ultima = _ultimaEmision[clave];
      if (ultima != null && ahora.difference(ultima) < _intervaloAlerta) {
        continue;
      }

      _ultimaEmision[clave] = ahora;
      _controller.add(
        Deteccion(
          clase: resultado.etiqueta,
          confianza: resultado.confianza,
          sector: sector,
        ),
      );
    }

    _ultimaEmision.removeWhere(
      (_, momento) => ahora.difference(momento) > const Duration(seconds: 10),
    );
  }
}
