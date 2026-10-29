
import 'package:flutter/material.dart';

void main() {
  runApp(const VistaApp());
}

class VistaApp extends StatelessWidget {
  const VistaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VISTA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: const VistaHomePage(),
    );
  }
}

class VistaHomePage extends StatefulWidget {
  const VistaHomePage({super.key});

  @override
  State<VistaHomePage> createState() => _VistaHomePageState();
}

class _VistaHomePageState extends State<VistaHomePage> {
  // Estado inicial de la asistencia.
  bool _asistenciaActiva = false;

  // Cambia entre activada y detenida.
  void _alternarAsistencia() {
    setState(() {
      _asistenciaActiva = !_asistenciaActiva;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color colorEstado = _asistenciaActiva
        ? const Color(0xFF237A3B)
        : const Color(0xFF52616B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.hearing, size: 30),
            SizedBox(width: 10),
            Text(
              'VISTA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  const Icon(
                    Icons.accessibility_new,
                    size: 78,
                    color: Color(0xFF00695C),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Bienvenido a VISTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00695C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Asistencia auditiva para tu movilidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tarjeta que muestra el estado actual.
                  Semantics(
                    liveRegion: true,
                    child: Card(
                      color: _asistenciaActiva
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFECEFF1),
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
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón que cambia el estado de la interfaz.
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

                  const Text(
                    'Acerca de esta versión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Esta versión permite probar la interfaz y el '
                    'cambio de estado de la asistencia. La cámara, '
                    'la detección de obstáculos, el GPS y el audio '
                    'real todavía no están implementados.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'VISTA es un prototipo experimental y no sustituye '
                    'el bastón, el perro guía ni otras ayudas de movilidad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
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
