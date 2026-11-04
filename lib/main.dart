import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app completa en horizontal (FR-024, R11).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Voz preparada al arrancar para que Si-jak coincida con el fin de la
  // cuenta (R8). Si algo falla, la app arranca igual sin voz.
  final container = ProviderContainer();
  try {
    final catalog = await container.read(catalogProvider.future);
    await container.read(voiceAnnouncerProvider).prepare(catalog);
  } catch (_) {}
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HaidongGumdoApp(),
    ),
  );
}
