import 'package:flutter/material.dart';

import '../datos/modelos_datos.dart';
import '../dominio/excepciones_dominio.dart';
import '../servicios/destinos_service.dart';

class PantallaDestinosFrecuentes extends StatefulWidget {
  const PantallaDestinosFrecuentes({
    required this.usuario,
    required this.servicio,
    super.key,
  });

  final Usuario usuario;
  final DestinosService servicio;

  @override
  State<PantallaDestinosFrecuentes> createState() =>
      _PantallaDestinosFrecuentesState();
}

class _PantallaDestinosFrecuentesState
    extends State<PantallaDestinosFrecuentes> {
  final _formulario = GlobalKey<FormState>();
  final _etiqueta = TextEditingController();
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();

  List<DestinoFrecuente> _destinos = const [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _etiqueta.dispose();
    _latitud.dispose();
    _longitud.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final destinos = await widget.servicio.listarPorUsuario(
        widget.usuario.idUsuario,
      );
      if (mounted) setState(() => _destinos = destinos);
    } on ErrorDominio catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudieron cargar los destinos. Revisa tu conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final latitud = _parsearCoordenada(_latitud.text);
    final longitud = _parsearCoordenada(_longitud.text);
    if (latitud == null || longitud == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final destino = await widget.servicio.guardar(
        widget.usuario.idUsuario,
        _etiqueta.text,
        latitud,
        longitud,
      );
      if (!mounted) return;
      _etiqueta.clear();
      _latitud.clear();
      _longitud.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Destino guardado. ID ${destino.idDestino}.')),
      );
      await _cargar();
    } on ErrorDominio catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo guardar el destino. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  double? _parsearCoordenada(String valor) =>
      double.tryParse(valor.trim().replaceAll(',', '.'));

  String? _validarCoordenada(String? valor, {required bool esLatitud}) {
    final coordenada = _parsearCoordenada(valor ?? '');
    if (coordenada == null || !coordenada.isFinite) {
      return 'Ingresa una coordenada numérica.';
    }
    final minimo = esLatitud ? -90.0 : -180.0;
    final maximo = esLatitud ? 90.0 : 180.0;
    if (coordenada < minimo || coordenada > maximo) {
      return esLatitud
          ? 'La latitud debe estar entre -90 y 90.'
          : 'La longitud debe estar entre -180 y 180.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Destinos frecuentes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Guarda un lugar con su nombre y coordenadas para asociarlo a tu cuenta.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _etiqueta,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del destino',
                      hintText: 'Casa, universidad, trabajo…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Escribe un nombre para el destino.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _latitud,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitud',
                      hintText: 'Ejemplo: 4.6097',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        _validarCoordenada(valor, esLatitud: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _longitud,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitud',
                      hintText: 'Ejemplo: -74.0817',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        _validarCoordenada(valor, esLatitud: false),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_location_alt_outlined),
                    label: Text(_guardando ? 'Guardando…' : 'Guardar destino'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Guardados para ${widget.usuario.nombre}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar lista',
                  onPressed: _cargando ? null : _cargar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Semantics(
                liveRegion: true,
                child: Card(
                  color: colores.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                ),
              )
            else if (_destinos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Todavía no tienes destinos guardados.'),
              )
            else
              ..._destinos.map(
                (destino) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(destino.etiqueta),
                    subtitle: Text(
                      'ID ${destino.idDestino} · '
                      '${destino.latitud}, ${destino.longitud}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
