import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../datos/modelos_datos.dart';
import '../modelos/solicitud_alerta.dart';
import '../nucleo/orquestador.dart';
import '../servicios/configuracion_service.dart';
import '../servicios/destinos_service.dart';
import '../vision/detector_yolo.dart';
import 'pantalla_camara.dart';
import 'pantalla_configuracion.dart';
import 'pantalla_destinos_frecuentes.dart';

class PantallaModoCaminata extends StatefulWidget {
  const PantallaModoCaminata({
    required this.orq,
    this.usuario,
    this.servicioConfiguracion,
    this.servicioDestinos,
    this.onCerrarSesion,
    super.key,
  });

  final Orquestador orq;
  final Usuario? usuario;
  final ConfiguracionService? servicioConfiguracion;
  final DestinosService? servicioDestinos;
  final VoidCallback? onCerrarSesion;

  @override
  State<PantallaModoCaminata> createState() => _PantallaModoCaminataState();
}

class _PantallaModoCaminataState extends State<PantallaModoCaminata> {
  bool _asistenciaActiva = true;
  SolicitudAlerta? _ultimaAlerta;
  StreamSubscription<SolicitudAlerta>? _suscripcion;
  Configuracion? _configuracion;

  @override
  void initState() {
    super.initState();
    _suscripcion = widget.orq.alertas.listen((alerta) {
      if (!mounted) return;
      setState(() {
        _ultimaAlerta = alerta;
      });
    });
    if (widget.usuario != null && widget.servicioConfiguracion != null) {
      unawaited(_cargarConfiguracion());
    }
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final configuracion = await widget.servicioConfiguracion!.obtener(
        widget.usuario!.idUsuario,
      );
      if (!mounted) return;
      setState(() => _configuracion = configuracion);
      _aplicarSensibilidad(configuracion.sensibilidad);
    } catch (_) {
      // Una cuenta nueva ya crea preferencias por defecto; esto solo protege
      // sesiones antiguas creadas antes de esa inicialización.
    }
  }

  void _aplicarSensibilidad(double valor) {
    final detector = widget.orq.detector;
    if (detector is DetectorYolo) detector.umbralConfianza = valor;
  }

  Future<void> _abrirConfiguracion() async {
    final usuario = widget.usuario;
    final servicio = widget.servicioConfiguracion;
    if (usuario == null || servicio == null) return;
    final guardada = await Navigator.of(context).push<Configuracion>(
      MaterialPageRoute(
        builder: (_) =>
            PantallaConfiguracion(usuario: usuario, servicio: servicio),
      ),
    );
    if (guardada != null && mounted) {
      setState(() => _configuracion = guardada);
      _aplicarSensibilidad(guardada.sensibilidad);
    }
  }

  Future<void> _abrirDestinos() async {
    final usuario = widget.usuario;
    final servicio = widget.servicioDestinos;
    if (usuario == null || servicio == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PantallaDestinosFrecuentes(usuario: usuario, servicio: servicio),
      ),
    );
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
        actions: [
          if (widget.servicioConfiguracion != null)
            IconButton(
              tooltip: 'Configuración',
              onPressed: _abrirConfiguracion,
              icon: const Icon(Icons.tune),
            ),
          if (widget.servicioDestinos != null)
            IconButton(
              tooltip: 'Destinos frecuentes',
              onPressed: _abrirDestinos,
              icon: const Icon(Icons.place_outlined),
            ),
          if (widget.onCerrarSesion != null)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: widget.onCerrarSesion,
              icon: const Icon(Icons.logout),
            ),
        ],
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
                    widget.usuario == null
                        ? 'Bienvenido a VISTA'
                        : 'Hola, ${widget.usuario!.nombre}',
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
                                  ? kIsWeb
                                        ? 'La web muestra la cámara; YOLO en vivo requiere la app Android.'
                                        : 'Abre la cámara para iniciar la detección en vivo.'
                                  : 'Pulsa el botón para activar la asistencia.',
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaCamara(
                            detector: widget.orq.detector is DetectorYolo
                                ? widget.orq.detector as DetectorYolo
                                : null,
                            umbralConfianza:
                                _configuracion?.sensibilidad ?? 0.5,
                            velocidadVoz: _configuracion?.velocidadVoz ?? 1.2,
                            volumenVoz: _configuracion?.volumenMaestro ?? 60,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Probar vista previa de cámara'),
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
                    'En Android, el modelo YOLO identifica objetos y su '
                    'posición aproximada en la imagen. La versión web solo '
                    'muestra la cámara. Android anuncia por voz el objeto '
                    'principal y su posición aproximada. No se calcula '
                    'distancia real.',
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
