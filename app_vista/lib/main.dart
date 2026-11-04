import 'package:flutter/material.dart';

import 'audio/audio_falso.dart';
import 'nucleo/orquestador.dart';
import 'presentacion/pantalla_modo_caminata.dart';
import 'vision/detector_falso.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final orq = Orquestador(detector: DetectorFalso(), audio: AudioFalso());
  await orq.iniciar();
  runApp(VistaApp(orq: orq));
}

class VistaApp extends StatelessWidget {
  const VistaApp({required this.orq, super.key});

  final Orquestador orq;

  @override
  Widget build(BuildContext context) {
    const colorSemilla = Color(0xFF00695C);

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
      home: PantallaModoCaminata(orq: orq),
    );
  }
}
