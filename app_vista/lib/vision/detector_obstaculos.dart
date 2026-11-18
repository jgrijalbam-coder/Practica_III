import 'dart:async';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../modelos/deteccion.dart';

class DetectorYolo implements DetectorObstaculos {
  final UltralyticsYolo _yoloController = UltralyticsYolo();
  final StreamController<Deteccion> _controller = StreamController<Deteccion>.broadcast();
  
  double _confianza = 0.5; // Valor por defecto especificado en el contrato
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
      // Inicializa el modelo YOLO con el archivo .tflite en assets/models/
      await _yoloController.initialize(
        modelPath: 'assets/models/yolo26s.tflite', // Reemplaza por el nombre exacto de tu archivo
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
    // Aquí puedes agregar lógica adicional para liberar la cámara si el plugin lo requiere
  }

  void _bucleInferencia() async {
    while (_isEjecutando) {
      try {
        // TODO: Aquí capturas el fotograma de la cámara y ejecutas la inferencia de YOLO.
        // Ejemplo conceptual del flujo con el plugin:
        // final resultados = await _yoloController.runInferenceOnCameraFrame();
        
        // Por cada objeto detectado que cumpla el umbral, creas una instancia de Deteccion 
        // y la emites al stream:
        // for (var item in resultados) {
        //   if (item.confidence >= _confianza) {
        //     final deteccion = Deteccion(
        //       clase: item.label,
        //       confianza: item.confidence,
        //       caja: item.boundingBox,
        //       sector: calcularSector(item.boundingBox),
        //       distanciaMetros: calcularDistanciaAproximada(item.boundingBox),
        //     );
        //     _controller.add(deteccion);
        //   }
        // }

      } catch (e) {
        // Manejo de errores de inferencia o cámara
      }

      // Control de frecuencia para no saturar el orquestador (ej. ~3-5 cuadros por segundo)
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}
