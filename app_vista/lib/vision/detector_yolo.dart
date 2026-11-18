import 'dart:async';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../modelos/deteccion.dart';

class DetectorYolo implements DetectorObstaculos {
  final UltralyticsYolo _yoloController = UltralyticsYolo();
  final StreamController<Deteccion> _controller = StreamController<Deteccion>.broadcast();
  
  double _confianza = 0.5;
  bool _isInitialized = false;
  bool _isEjecutando = false;

  @override
  Stream<Deteccion> get detecciones => _controller.stream;

  @override
  set umbralConfianza(double valor) {
    _confianza = valor;
  }

  @override
  Future<void> iniciar() async {
    if (!_isInitialized) {
      // Inicializa el modelo indicando la ruta del asset
      await _yoloController.initialize(
        modelPath: 'assets/models/yolo26s.tflite', // Asegúrate de que este sea tu archivo .tflite
        confidenceThreshold: _confianza,
      );
      _isInitialized = true;
    }

    _isEjecutando = true;
    _bucleInferencia();
  }

  @override
  Future<void> detener() async {
    _isEjecutando = false;
    await _yoloController.dispose();
  }

  void _bucleInferencia() async {
    while (_isEjecutando) {
      try {
        // Ejecuta la inferencia directamente sobre el flujo de la cámara del plugin
        final resultados = await _yoloController.runInferenceOnCameraFrame();

        if (resultados != null) {
          for (var item in resultados) {
            if (item.confidence >= _confianza) {
              // Creamos la Detección adaptada a los campos que tu contrato requiere
              final deteccion = Deteccion(
                clase: item.label ?? 'desconocido',
                confianza: item.confidence,
                caja: item.boundingBox,
                sector: _calcularSectorHorizontal(item.boundingBox),
                distanciaMetros: _estimarDistancia(item.boundingBox),
              );
              _controller.add(deteccion);
            }
          }
        }
      } catch (e) {
        // En caso de que ocurra un error en la captura de fotogramas
      }

      // Pausa breve para regular la tasa de refresco y no saturar el procesador
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // Método auxiliar para calcular el sector según la posición horizontal de la caja
  String _calcularSectorHorizontal(List<double> box) {
    // Supone coordenadas normalizadas o en píxeles donde box[0] es xmin, box[2] es xmax
    // Aquí puedes ajustar la lógica según cómo maneje las cajas tu modelo
    double xCenter = (box[0] + box[2]) / 2;
    if (xCenter < 0.33) return 'izquierda';
    if (xCenter > 0.66) return 'derecha';
    return 'centro';
  }

  // Estimación preliminar de distancia basada en el tamaño de la caja en pantalla
  double _estimarDistancia(List<double> box) {
    double altoCaja = box[3] - box[1]; // ymax - ymin
    // Fórmula empírica inversa aproximada (a mayor tamaño de caja, menor distancia)
    if (altoCaja <= 0) return 5.0;
    return double.parse((1.0 / altoCaja * 2.5).toStringAsFixed(1));
  }
}