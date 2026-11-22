import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/models/yolo_result.dart';
import 'package:ultralytics_yolo/models/yolo_task.dart';
import 'package:ultralytics_yolo/yolo_view.dart';

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
  Widget build(BuildContext context) => YOLOView(
    modelPath: 'yolo26n',
    task: YOLOTask.detect,
    confidenceThreshold: umbralConfianza,
    lensFacing: LensFacing.back,
    onResult: (resultados) => onResultados(
      resultados.map(_convertirResultado).toList(growable: false),
    ),
    onModelLoad: (path, _) => onModeloCargado('Modelo activo: $path'),
    onModelError: (error, path, _) =>
        onErrorModelo('No se pudo cargar YOLO ($path): $error'),
  );

  ResultadoYolo _convertirResultado(YOLOResult resultado) => ResultadoYolo(
    etiqueta: resultado.className,
    confianza: resultado.confidence,
    centroX: resultado.normalizedBox.center.dx,
  );
}
