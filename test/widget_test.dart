import 'package:flutter_test/flutter_test.dart';

import 'package:app_vista/audio/audio_falso.dart';
import 'package:app_vista/main.dart';
import 'package:app_vista/nucleo/orquestador.dart';
import 'package:app_vista/vision/detector_falso.dart';

void main() {
  testWidgets('muestra la pantalla de modo caminata', (
    WidgetTester tester,
  ) async {
    final orq = Orquestador(detector: DetectorFalso(), audio: AudioFalso());

    await orq.iniciar();
    try {
      await tester.pumpWidget(VistaApp(orq: orq));

      expect(find.text('Bienvenido a VISTA'), findsOneWidget);
      expect(find.text('Asistencia ACTIVADA'), findsOneWidget);
      expect(find.text('Esperando la primera detección...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('persona al frente'), findsOneWidget);
      expect(find.text('Nivel: informativo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('persona a la izquierda, a 2.0 metros'), findsOneWidget);
      expect(find.text('Nivel: preventivo'), findsOneWidget);
    } finally {
      await orq.detector.detener();
    }
  });
}
