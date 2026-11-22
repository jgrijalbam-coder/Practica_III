import 'package:flutter/material.dart';

import 'audio/audio_falso.dart';
import 'datos/modelos_datos.dart';
import 'nucleo/orquestador.dart';
import 'presentacion/pantalla_acceso.dart';
import 'presentacion/pantalla_modo_caminata.dart';
import 'servicios/inicializar_cuenta.dart';
import 'servicios/servicios_cuenta.dart';
import 'vision/detector_yolo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cuenta = await inicializarServiciosCuenta();
  final orquestador = Orquestador(
    detector: DetectorYolo(),
    audio: AudioFalso(),
  );
  // En web se conserva la vista previa actual, que no requiere inicio de
  // sesión ni SQLite móvil. En Android se inicia tras validar la cuenta.
  if (cuenta == null) await orquestador.iniciar();
  runApp(VistaApp(orquestador: orquestador, cuenta: cuenta));
}

class VistaApp extends StatefulWidget {
  const VistaApp({required this.orquestador, required this.cuenta, super.key});

  final Orquestador orquestador;
  final ServiciosCuenta? cuenta;

  @override
  State<VistaApp> createState() => _VistaAppState();
}

class _VistaAppState extends State<VistaApp> {
  Usuario? _usuario;

  Future<void> _iniciarSesion(Usuario usuario) async {
    await widget.orquestador.iniciar();
    if (mounted) setState(() => _usuario = usuario);
  }

  Future<void> _cerrarSesion() async {
    await widget.orquestador.detenerTodo();
    if (mounted) setState(() => _usuario = null);
  }

  @override
  Widget build(BuildContext context) {
    const colorSemilla = Color(0xFF00695C);
    final cuenta = widget.cuenta;

    return MaterialApp(
      title: 'VISTA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: colorSemilla),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSemilla,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: cuenta == null
          ? PantallaModoCaminata(orq: widget.orquestador)
          : _usuario == null
          ? PantallaAcceso(
              autenticacion: cuenta.autenticacion,
              onSesionIniciada: _iniciarSesion,
            )
          : PantallaModoCaminata(
              orq: widget.orquestador,
              usuario: _usuario,
              servicioConfiguracion: cuenta.configuracion,
              onCerrarSesion: _cerrarSesion,
            ),
    );
  }
}
