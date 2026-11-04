import 'enums.dart';

/// Lo que el núcleo le pide al módulo de audio.
class SolicitudAlerta {
  final NivelRiesgo nivel;
  final Sector sector;
  final String mensaje;
  final DateTime creada;

  SolicitudAlerta({
    required this.nivel,
    required this.sector,
    required this.mensaje,
    DateTime? creada,
  }) : creada = creada ?? DateTime.now();

  /// Mayor número = más prioridad. Lo inminente interrumpe todo.
  int get prioridad => nivel.index;
}
