import 'enums.dart';

/// Lo que produce el módulo de visión y consume el núcleo.
class Deteccion {
  final String clase;
  final double confianza; // 0.0 a 1.0
  final double distanciaMetros;
  final Sector sector;
  final DateTime momento;

  Deteccion({
    required this.clase,
    required this.confianza,
    required this.distanciaMetros,
    required this.sector,
    DateTime? momento,
  }) : momento = momento ?? DateTime.now();

  NivelRiesgo get nivel => nivelDesdeDistancia(distanciaMetros);
}
