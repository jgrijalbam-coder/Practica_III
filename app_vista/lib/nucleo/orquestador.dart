import 'dart:async';
import '../audio/servicio_audio.dart';
import '../modelos/deteccion.dart';
import '../modelos/enums.dart';
import '../modelos/solicitud_alerta.dart';
import '../vision/detector_obstaculos.dart';

/// Núcleo (Jeffrey): conecta visión -> reglas -> audio.
class Orquestador {
  final DetectorObstaculos detector;
  final ServicioAudio audio;
  StreamSubscription<Deteccion>? _sub;

  Orquestador({required this.detector, required this.audio});

  final _alertas = StreamController<SolicitudAlerta>.broadcast();
  Stream<SolicitudAlerta> get alertas => _alertas.stream;

  Future<void> iniciar() async {
    _sub = detector.detecciones.listen(_alProcesarDeteccion);
    await detector.iniciar();
  }

  Future<void> detenerTodo() async {
    await _sub?.cancel();
    await detector.detener();
    await audio.detener();
  }

  void _alProcesarDeteccion(Deteccion d) {
    final alerta = SolicitudAlerta(
      nivel: d.nivel,
      sector: d.sector,
      mensaje: _mensaje(d),
    );
    _alertas.add(alerta);
    audio.reproducir(alerta);
  }

  String _mensaje(Deteccion d) {
    final lado = switch (d.sector) {
      Sector.izquierda => 'a la izquierda',
      Sector.derecha => 'a la derecha',
      Sector.frente => 'al frente',
      Sector.atras => 'atrás',
    };
    final metros = d.distanciaMetros.toStringAsFixed(1);
    return switch (d.nivel) {
      NivelRiesgo.inminente => '¡Cuidado! ${d.clase} $lado, a $metros metros',
      NivelRiesgo.preventivo => '${d.clase} $lado, a $metros metros',
      NivelRiesgo.informativo => '${d.clase} $lado',
    };
  }
}
