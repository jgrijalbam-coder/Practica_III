import 'package:flutter/material.dart';

import '../datos/modelos_datos.dart';
import '../dominio/reglas_configuracion.dart';
import '../servicios/configuracion_service.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({
    required this.usuario,
    required this.servicio,
    super.key,
  });

  final Usuario usuario;
  final ConfiguracionService servicio;

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  late double _sensibilidad = sensibilidadDefecto;
  late double _velocidad = velocidadVozDefecto;
  late double _volumen = volumenMaestroDefecto.toDouble();
  ModoTonos _modoTonos = modoTonosDefecto;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final config = await widget.servicio.obtener(widget.usuario.idUsuario);
      if (!mounted) return;
      setState(() {
        _sensibilidad = config.sensibilidad;
        _velocidad = config.velocidadVoz;
        _volumen = config.volumenMaestro.toDouble();
        _modoTonos = config.modoTonos;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los ajustes.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final guardada = await widget.servicio.guardar(
        widget.usuario.idUsuario,
        DatosConfiguracion(
          sensibilidad: _sensibilidad,
          velocidadVoz: _velocidad,
          modoTonos: _modoTonos,
          volumenMaestro: _volumen.round(),
        ),
      );
      if (mounted) Navigator.of(context).pop(guardada);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron guardar los ajustes.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Sensibilidad', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Define cuánta confianza necesita el detector para anunciar un objeto.'),
                const SizedBox(height: 8),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 0.4, label: Text('Alta')),
                    ButtonSegment(value: 0.5, label: Text('Media')),
                    ButtonSegment(value: 0.7, label: Text('Baja')),
                  ],
                  selected: {_sensibilidad},
                  onSelectionChanged: (valor) => setState(() => _sensibilidad = valor.first),
                ),
                const SizedBox(height: 24),
                Text('Velocidad de voz: ${_velocidad.toStringAsFixed(1)}×'),
                Slider(
                  value: _velocidad,
                  min: velocidadVozMinima,
                  max: velocidadVozMaxima,
                  divisions: 12,
                  label: '${_velocidad.toStringAsFixed(1)}×',
                  onChanged: (valor) => setState(() => _velocidad = valor),
                ),
                const SizedBox(height: 12),
                Text('Volumen de voz: ${_volumen.round()} %'),
                Slider(
                  value: _volumen,
                  min: volumenMaestroMinimo.toDouble(),
                  max: volumenMaestroMaximo.toDouble(),
                  divisions: 9,
                  label: '${_volumen.round()} %',
                  onChanged: (valor) => setState(() => _volumen = valor),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ModoTonos>(
                  value: _modoTonos,
                  decoration: const InputDecoration(
                    labelText: 'Modo de tonos',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ModoTonos.frecuenciaSimple,
                      child: Text('Frecuencia simple'),
                    ),
                    DropdownMenuItem(
                      value: ModoTonos.espacializada,
                      child: Text('Espacializada'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor != null) setState(() => _modoTonos = valor);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'El modo de tonos se guarda; la salida espacializada aún no está conectada.',
                  style: TextStyle(color: colores.onSurfaceVariant, fontSize: 12),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: colores.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const CircularProgressIndicator()
                      : const Text('Guardar configuración'),
                ),
              ],
            ),
    );
  }
}
