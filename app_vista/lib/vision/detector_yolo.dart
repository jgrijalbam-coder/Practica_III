import 'dart:async';
import 'dart:typed_data';

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../modelos/deteccion.dart';
import '../modelos/enums.dart';
import 'detector_obstaculos.dart';

/// Ejecuta YOLO sobre fotogramas JPEG/PNG entregados por una fuente de cámara.
/// La interfaz de cámara debe proporcionar los bytes de cada fotograma.
class DetectorYolo implements DetectorObstaculos {
  DetectorYolo({
    required this.fotogramas,
    String? modelo,
  }) : _yolo = YOLO(
          modelPath: modelo ?? YOLO.defaultOfficialModel() ?? 'yolo26n',
          task: YOLOTask.detect,
        );

  final Stream<Uint8List> fotogramas;
  final YOLO _yolo;
  final StreamController<Deteccion> _control =
      StreamController<Deteccion>.broadcast();

  StreamSubscription<Uint8List>? _suscripcionFotogramas;
  double _umbralConfianza = 0.5;
  bool _procesandoFotograma = false;
  bool _detenido = false;

  @override
  Stream<Deteccion> get detecciones => _control.stream;

  @override
  set umbralConfianza(double valor) {
    _umbralConfianza = valor.clamp(0.0, 1.0).toDouble();
  }

  @override
  Future<void> iniciar() async {
    if (_detenido) {
      throw StateError('No se puede reiniciar un DetectorYolo detenido.');
    }
    if (_suscripcionFotogramas != null) return;

    final cargado = await _yolo.loadModel();
    if (!cargado) {
      throw StateError('No se pudo cargar el modelo YOLO.');
    }

    _suscripcionFotogramas = fotogramas.listen(
      (fotograma) => unawaited(_procesarFotograma(fotograma)),
      onError: _control.addError,
    );
  }

  Future<void> _procesarFotograma(Uint8List fotograma) async {
    if (_procesandoFotograma || _detenido) return;
    _procesandoFotograma = true;
    try {
      final respuesta = await _yolo.predict(
        fotograma,
        confidenceThreshold: _umbralConfianza,
      );
      final resultados = respuesta['detections'];
      if (resultados is! List) return;

      for (final resultado in resultados) {
        if (resultado is! Map) continue;
        final deteccionYolo = YOLOResult.fromMap(resultado);
        if (deteccionYolo.confidence < _umbralConfianza) continue;

        final caja = deteccionYolo.normalizedBox;
        _control.add(Deteccion(
          clase: deteccionYolo.className,
          confianza: deteccionYolo.confidence,
          sector: _calcularSector(caja.center.dx),
          distanciaMetros: _estimarDistancia(caja.height),
        ));
      }
    } catch (error, stackTrace) {
      _control.addError(error, stackTrace);
    } finally {
      _procesandoFotograma = false;
    }
  }

  Sector _calcularSector(double centroX) {
    if (centroX < 0.33) return Sector.izquierda;
    if (centroX > 0.66) return Sector.derecha;
    return Sector.frente;
  }

  // Estimación preliminar: requiere calibración con el modelo y la cámara reales.
  double _estimarDistancia(double altoNormalizado) {
    if (altoNormalizado <= 0) return 5.0;
    return double.parse((2.5 / altoNormalizado).toStringAsFixed(1));
  }

  @override
  Future<void> detener() async {
    if (_detenido) return;
    _detenido = true;
    await _suscripcionFotogramas?.cancel();
    await _yolo.dispose();
    await _control.close();
  }
}
