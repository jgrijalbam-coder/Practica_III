import 'package:flutter/material.dart';

import '../datos/modelos_datos.dart';
import '../servicios/autenticacion_service.dart';

class PantallaAcceso extends StatefulWidget {
  const PantallaAcceso({
    required this.autenticacion,
    required this.onSesionIniciada,
    super.key,
  });

  final ServicioAutenticacion autenticacion;
  final Future<void> Function(Usuario usuario) onSesionIniciada;

  @override
  State<PantallaAcceso> createState() => _PantallaAccesoState();
}

class _PantallaAccesoState extends State<PantallaAcceso> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmarContrasena = TextEditingController();
  bool _crearCuenta = false;
  bool _ocultarContrasena = true;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmarContrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final usuario = _crearCuenta
          ? await widget.autenticacion.registrar(
              nombre: _nombre.text,
              correo: _correo.text,
              contrasena: _contrasena.text,
            )
          : await widget.autenticacion.iniciarSesion(
              correo: _correo.text,
              contrasena: _contrasena.text,
            );
      if (mounted) await widget.onSesionIniciada(usuario);
    } on ErrorAutenticacion catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Ocurrió un error. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      size: 72,
                      color: colores.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _crearCuenta ? 'Crear cuenta de VISTA' : 'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tu cuenta y preferencias se guardan en el servidor VISTA.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_crearCuenta) ...[
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Escribe tu nombre.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) =>
                          valor == null || !valor.contains('@')
                          ? 'Escribe un correo válido.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contrasena,
                      obscureText: _ocultarContrasena,
                      autofillHints: [
                        _crearCuenta
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _ocultarContrasena
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena,
                          ),
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (valor) =>
                          _crearCuenta && (valor == null || valor.length < 8)
                          ? 'Usa al menos 8 caracteres.'
                          : valor == null || valor.isEmpty
                          ? 'Escribe tu contraseña.'
                          : null,
                    ),
                    if (_crearCuenta) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmarContrasena,
                        obscureText: _ocultarContrasena,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) => valor != _contrasena.text
                            ? 'Las contraseñas no coinciden.'
                            : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: colores.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _ocupado ? null : _enviar,
                      child: _ocupado
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_crearCuenta ? 'Crear cuenta' : 'Entrar'),
                    ),
                    TextButton(
                      onPressed: _ocupado
                          ? null
                          : () => setState(() {
                              _crearCuenta = !_crearCuenta;
                              _error = null;
                            }),
                      child: Text(
                        _crearCuenta
                            ? 'Ya tengo una cuenta'
                            : 'Crear una cuenta nueva',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La cuenta y las preferencias se guardan en este teléfono.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
