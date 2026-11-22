import 'package:flutter_tts/flutter_tts.dart';

import 'resultado_yolo.dart';

/// Anuncia de forma breve una detección destacada de la cámara.
/// La ubicación es aproximada y se refiere a la posición en la imagen.
class ServicioVoz {
  ServicioVoz({
    this.velocidad = 1.2,
    this.volumen = 60,
    this.umbralConfianza = 0.5,
  })
    : _tts = FlutterTts();

  final FlutterTts _tts;
  final double velocidad;
  final int volumen;
  final double umbralConfianza;
  Future<void>? _inicializacion;
  DateTime _ultimoAnuncio = DateTime.fromMillisecondsSinceEpoch(0);
  bool _ocupado = false;
  bool _cerrado = false;

  static const _intervalo = Duration(seconds: 3);

  Future<void> inicializar() => _inicializacion ??= _configurar();

  Future<void> _configurar() async {
    await _tts.awaitSpeakCompletion(true);
    try {
      await _tts.setLanguage('es-CO');
    } catch (_) {
      await _tts.setLanguage('es-ES');
    }
    await _tts.setSpeechRate((0.45 * velocidad).clamp(0.36, 0.9).toDouble());
    await _tts.setVolume((volumen / 100).clamp(0.5, 0.95).toDouble());
  }

  Future<void> anunciar(List<ResultadoYolo> resultados) async {
    if (_cerrado || resultados.isEmpty || _ocupado) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoAnuncio) < _intervalo) return;

    final resultado = resultados.reduce(
      (a, b) => a.confianza >= b.confianza ? a : b,
    );
    if (resultado.confianza < umbralConfianza) return;

    final nombre = _nombres[resultado.etiqueta.toLowerCase()] ??
        resultado.etiqueta.toLowerCase();
    final ubicacion = resultado.centroX < 0.35
        ? 'a la izquierda'
        : resultado.centroX > 0.65
        ? 'a la derecha'
        : 'al frente';

    _ocupado = true;
    _ultimoAnuncio = ahora;
    try {
      await inicializar();
      if (!_cerrado) await _tts.speak('Veo $nombre $ubicacion');
    } catch (_) {
      // Un fallo del motor de voz no debe interrumpir la cámara.
    } finally {
      _ocupado = false;
    }
  }

  Future<void> cerrar() async {
    _cerrado = true;
    try {
      await _tts.stop();
    } catch (_) {
      // El cierre de la vista no depende del motor de voz.
    }
  }

  static const _nombres = <String, String>{
    'person': 'una persona',
    'bicycle': 'una bicicleta',
    'car': 'un carro',
    'motorcycle': 'una motocicleta',
    'airplane': 'un avión',
    'bus': 'un bus',
    'train': 'un tren',
    'truck': 'un camión',
    'boat': 'un barco',
    'traffic light': 'un semáforo',
    'fire hydrant': 'un hidrante',
    'stop sign': 'una señal de pare',
    'bench': 'una banca',
    'bird': 'un pájaro',
    'cat': 'un gato',
    'dog': 'un perro',
    'horse': 'un caballo',
    'sheep': 'una oveja',
    'cow': 'una vaca',
    'elephant': 'un elefante',
    'bear': 'un oso',
    'zebra': 'una cebra',
    'giraffe': 'una jirafa',
    'backpack': 'una mochila',
    'umbrella': 'un paraguas',
    'handbag': 'un bolso',
    'tie': 'una corbata',
    'suitcase': 'una maleta',
    'bottle': 'una botella',
    'cup': 'una taza',
    'chair': 'una silla',
    'couch': 'un sofá',
    'potted plant': 'una planta',
    'bed': 'una cama',
    'dining table': 'una mesa',
    'toilet': 'un sanitario',
    'tv': 'un televisor',
    'laptop': 'un computador portátil',
    'mouse': 'un ratón',
    'remote': 'un control remoto',
    'keyboard': 'un teclado',
    'cell phone': 'un celular',
    'microwave': 'un microondas',
    'oven': 'un horno',
    'sink': 'un lavamanos',
    'refrigerator': 'una nevera',
    'book': 'un libro',
    'clock': 'un reloj',
    'scissors': 'unas tijeras',
    'teddy bear': 'un oso de peluche',
    'toothbrush': 'un cepillo de dientes',
  };
}
