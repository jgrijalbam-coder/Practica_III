import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../vision/preprocesador_fotograma.dart';

class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  CameraController? _camara;
  String? _error;
  String _tamanoFotograma = 'Esperando fotogramas...';
  String _modelo = 'Modelo: esperando fotograma';
  DateTime _ultimaActualizacion = DateTime.fromMillisecondsSinceEpoch(0);
  bool _procesandoFotograma = false;
  int _sensorOrientation = 0;
  final PreprocesadorFotograma _preprocesador =
      const PreprocesadorFotograma(tamano: 320);

  @override
  void initState() {
    super.initState();
    unawaited(_abrirCamara());
  }

  Future<void> _abrirCamara() async {
    try {
      final permiso = await Permission.camera.request();
      if (!permiso.isGranted) {
        setState(() {
          _error =
              'El permiso de cámara fue denegado. Actívalo en ajustes.';
        });
        return;
      }

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
      });
      await controller.startImageStream(_alRecibirFotograma);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.description ?? error.code;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo abrir la cámara: $error';
        });
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
        _tamanoFotograma =
            '${fotograma.width} × ${fotograma.height}';
        _modelo =
            'Modelo: ${preparado.ancho} × ${preparado.alto} RGB, '
            '${preparado.cantidadValores} valores';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo procesar el fotograma: $error';
      });
    } finally {
      _procesandoFotograma = false;
    }
  }

  @override
  void dispose() {
    unawaited(_camara?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camara = _camara;

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa de cámara')),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _abrirCamara,
                        child: const Text('Intentar de nuevo'),
                      ),
                      if (_error!.contains('denegado')) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: openAppSettings,
                          child: const Text('Abrir ajustes'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : camara == null || !camara.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Column(
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
                            Text(_modelo),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
