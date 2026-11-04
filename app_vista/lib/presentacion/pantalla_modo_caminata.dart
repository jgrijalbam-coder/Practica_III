import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos/solicitud_alerta.dart';
import '../nucleo/orquestador.dart';

class PantallaModoCaminata extends StatefulWidget {
  const PantallaModoCaminata({required this.orq, super.key});

  final Orquestador orq;

  @override
  State<PantallaModoCaminata> createState() => _PantallaModoCaminataState();
}

class _PantallaModoCaminataState extends State<PantallaModoCaminata> {
  bool _asistenciaActiva = true;
  SolicitudAlerta? _ultimaAlerta;
  StreamSubscription<SolicitudAlerta>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = widget.orq.alertas.listen((alerta) {
      if (!mounted) return;
      setState(() {
        _ultimaAlerta = alerta;
      });
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  Future<void> _alternarAsistencia() async {
    if (_asistenciaActiva) {
      await widget.orq.detenerTodo();
    } else {
      await widget.orq.iniciar();
    }

    if (!mounted) return;
    setState(() {
      _asistenciaActiva = !_asistenciaActiva;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final colorEstado = _asistenciaActiva
        ? colors.primary
        : colors.onSurfaceVariant;
    final colorTarjeta = _asistenciaActiva
        ? colors.secondaryContainer
        : colors.surface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Row(
          children: [
            Icon(Icons.hearing, size: 30),
            SizedBox(width: 10),
            Text('VISTA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.accessibility_new,
                    size: 78,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenido a VISTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Asistencia auditiva para tu movilidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    liveRegion: true,
                    child: Card(
                      color: colorTarjeta,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              _asistenciaActiva
                                  ? Icons.check_circle
                                  : Icons.pause_circle_filled,
                              color: colorEstado,
                              size: 52,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _asistenciaActiva
                                  ? 'Asistencia ACTIVADA'
                                  : 'Asistencia DETENIDA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: colorEstado,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _asistenciaActiva
                                  ? 'El modo de demostración está activo.'
                                  : 'Pulsa el botón para iniciar la demostración.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Card(
                      color: colors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Última alerta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _ultimaAlerta?.mensaje ??
                                  'Esperando la primera detección...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                color: colors.onSurface,
                              ),
                            ),
                            if (_ultimaAlerta != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Nivel: ${_ultimaAlerta!.nivel.name}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 60,
                    child: FilledButton.icon(
                      onPressed: _alternarAsistencia,
                      icon: Icon(
                        _asistenciaActiva
                            ? Icons.stop_circle_outlined
                            : Icons.play_arrow,
                        size: 28,
                      ),
                      label: Text(
                        _asistenciaActiva
                            ? 'Detener asistencia'
                            : 'Activar asistencia',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Acerca de esta versión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta versión permite probar la interfaz y el '
                    'cambio de estado de la asistencia. La cámara, '
                    'la detección de obstáculos, el GPS y el audio '
                    'real todavía no están implementados.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VISTA es un prototipo experimental y no sustituye '
                    'el bastón, el perro guía ni otras ayudas de movilidad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
