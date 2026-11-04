import '../modelos/solicitud_alerta.dart';
import 'servicio_audio.dart';

/// Versión de mentira: solo imprime lo que se diría.
class AudioFalso implements ServicioAudio {
  @override
  Future<void> reproducir(SolicitudAlerta alerta) async {
    // ignore: avoid_print
    print('[AUDIO ${alerta.nivel.name}] ${alerta.mensaje}');
  }

  @override
  Future<void> detener() async {}

  @override
  set velocidadVoz(double valor) {}

  @override
  set volumen(int valor) {}
}
