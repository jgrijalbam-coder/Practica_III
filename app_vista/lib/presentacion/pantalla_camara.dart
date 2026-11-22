import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../vision/detector_yolo.dart';
import '../vision/preprocesador_fotograma.dart';
import '../vision/resultado_yolo.dart';
import '../vision/servicio_voz.dart';
import '../vision/vista_yolo.dart';

class PantallaCamara extends StatefulWidget {
  const PantallaCamara({
    this.detector,
    this.umbralConfianza = 0.5,
    this.velocidadVoz = 1.2,
    this.volumenVoz = 60,
    super.key,
  });

  final DetectorYolo? detector;
  final double umbralConfianza;
  final double velocidadVoz;
  final int volumenVoz;

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  CameraController? _camara;
  String? _error;
  String _tamanoFotograma = 'Esperando fotogramas...';
  String _modelo = 'Preparando cámara...';
  String _resumenDetecciones = 'Esperando resultados del modelo...';
  DateTime _ultimaActualizacion = DateTime.fromMillisecondsSinceEpoch(0);
  bool _procesandoFotograma = false;
  bool _permisoNativoConcedido = false;
  int _sensorOrientation = 0;
  Key _claveVistaYolo = UniqueKey();
  final PreprocesadorFotograma _preprocesador = const PreprocesadorFotograma(
    tamano: 320,
  );
  late final ServicioVoz _voz = ServicioVoz(
    velocidad: widget.velocidadVoz,
    volumen: widget.volumenVoz,
    umbralConfianza: widget.umbralConfianza,
  );

  bool get _esPlataformaNativa =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_abrirCamaraWeb());
    } else if (_esPlataformaNativa) {
      unawaited(_solicitarPermisoNativo());
      unawaited(_voz.inicializar());
    } else {
      _error = 'La cámara está disponible en Android, iOS y web.';
    }
  }

  Future<void> _solicitarPermisoNativo() async {
    try {
      final permiso = await Permission.camera.request();
      if (!mounted) return;
      if (!permiso.isGranted) {
        setState(() {
          _error = 'El permiso de cámara fue denegado. Actívalo en ajustes.';
        });
        return;
      }
      setState(() {
        _error = null;
        _permisoNativoConcedido = true;
        _modelo = 'Cargando modelo YOLO26n...';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo solicitar acceso a la cámara: $error',
      );
    }
  }

  Future<void> _abrirCamaraWeb() async {
    try {
      await _camara?.dispose();
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        throw StateError('No se encontró una cámara disponible.');
      }

      final traseras = camaras.where(
        (camara) => camara.lensDirection == CameraLensDirection.back,
      );
      final seleccionada = traseras.isNotEmpty ? traseras.first : camaras.first;
      final controller = CameraController(
        seleccionada,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _camara = controller;
        _error = null;
        _sensorOrientation = seleccionada.sensorOrientation;
        _modelo = 'En navegador solo está activa la vista previa.';
      });
      await controller.startImageStream(_alRecibirFotograma);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? error.code);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir la cámara: $error');
      }
    }
  }

  void _alRecibirFotograma(CameraImage fotograma) {
    final ahora = DateTime.now();
    if (_procesandoFotograma ||
        ahora.difference(_ultimaActualizacion).inMilliseconds < 300) {
      return;
    }
    _ultimaActualizacion = ahora;
    unawaited(_procesarFotograma(fotograma));
  }

  Future<void> _procesarFotograma(CameraImage fotograma) async {
    _procesandoFotograma = true;
    try {
      final preparado = _preprocesador.preparar(
        fotograma,
        sensorOrientation: _sensorOrientation,
      );
      if (!mounted) return;
      setState(() {
        _tamanoFotograma = '${fotograma.width} × ${fotograma.height}';
        _resumenDetecciones =
            'Fotograma preparado: ${preparado.ancho} × ${preparado.alto} RGB. '
            'YOLO móvil no se ejecuta en el navegador.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo procesar el fotograma: $error');
    } finally {
      _procesandoFotograma = false;
    }
  }

  void _alRecibirResultados(List<ResultadoYolo> resultados) {
    widget.detector?.publicarResultados(resultados);
    unawaited(_voz.anunciar(resultados));
    if (!mounted) return;
    setState(() {
      if (resultados.isEmpty) {
        _resumenDetecciones = 'No se detectan objetos en este momento.';
      } else {
        _resumenDetecciones = resultados
            .take(3)
            .map(
              (resultado) =>
                  '${resultado.etiqueta} '
                  '(${(resultado.confianza * 100).round()}%)',
            )
            .join(' · ');
      }
    });
  }

  void _reintentarModelo() {
    setState(() {
      _error = null;
      _modelo = 'Cargando modelo YOLO26n...';
      _claveVistaYolo = UniqueKey();
    });
  }

  @override
  void dispose() {
    unawaited(_camara?.dispose());
    unawaited(_voz.cerrar());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa de cámara')),
      body: SafeArea(
        child: _error != null
            ? _vistaError()
            : kIsWeb
            ? _vistaWeb()
            : _vistaNativa(),
      ),
    );
  }

  Widget _vistaError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _error!.startsWith('No se pudo cargar YOLO')
                ? _reintentarModelo
                : kIsWeb
                ? _abrirCamaraWeb
                : _esPlataformaNativa
                ? _solicitarPermisoNativo
                : null,
            child: Text(
              _error!.startsWith('No se pudo cargar YOLO')
                  ? 'Reintentar modelo'
                  : 'Intentar de nuevo',
            ),
          ),
          if (!kIsWeb && _error!.contains('denegado')) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Abrir ajustes'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _vistaNativa() {
    if (!_esPlataformaNativa) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('La detección YOLO está disponible en Android e iOS.'),
        ),
      );
    }
    if (!_permisoNativoConcedido) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: VistaYolo(
            key: _claveVistaYolo,
            umbralConfianza: widget.umbralConfianza,
            onResultados: _alRecibirResultados,
            onModeloCargado: (mensaje) {
              if (!mounted) return;
              setState(() => _modelo = mensaje);
            },
            onErrorModelo: (mensaje) {
              if (!mounted) return;
              setState(() => _error = mensaje);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_modelo, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(_resumenDetecciones, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text(
                'Las detecciones indican clase y posición aproximada; '
                'no miden distancia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vistaWeb() {
    final camara = _camara;
    if (camara == null || !camara.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: camara.value.aspectRatio,
              child: CameraPreview(camara),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fotograma recibido: $_tamanoFotograma'),
              const SizedBox(height: 4),
              Text(_resumenDetecciones, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}
