import 'package:flutter/material.dart';

import 'resultado_yolo.dart';

class VistaYolo extends StatelessWidget {
  const VistaYolo({
    required this.onResultados,
    required this.onModeloCargado,
    required this.onErrorModelo,
    this.umbralConfianza = 0.5,
    super.key,
  });

  final ValueChanged<List<ResultadoYolo>> onResultados;
  final ValueChanged<String> onModeloCargado;
  final ValueChanged<String> onErrorModelo;
  final double umbralConfianza;

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.black,
    child: Center(
      child: Text(
        'La inferencia YOLO nativa no está disponible en esta plataforma.',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
