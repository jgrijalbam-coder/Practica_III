import '../modelos/solicitud_alerta.dart';

/// CONTRATO del módulo de audio (Luisa).
abstract class ServicioAudio {
  /// Reproduce la alerta. Si llega una de mayor prioridad, interrumpe la actual.
  Future<void> reproducir(SolicitudAlerta alerta);
  Future<void> detener();

  /// Velocidad de voz: 0.8 a 2.0 (por defecto 1.2).
  set velocidadVoz(double valor);

  /// Volumen maestro: 0 a 100.
  set volumen(int valor);
}
