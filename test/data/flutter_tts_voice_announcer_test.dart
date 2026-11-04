import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:haidonggumdo/data/platform/flutter_tts_voice_announcer.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';

/// Registra las llamadas y permite configurar las respuestas del motor de voz.
class FakeFlutterTts extends Fake implements FlutterTts {
  FakeFlutterTts({
    this.koreanAvailable = true,
    this.failAvailability = false,
    this.failSpeak = false,
  });

  final bool koreanAvailable;
  final bool failAvailability;
  final bool failSpeak;

  final List<String> availabilityChecks = [];
  final List<String> languages = [];
  final List<String> spoken = [];
  int stops = 0;

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    availabilityChecks.add(language);
    if (failAvailability) throw Exception('sin motor de voz');
    return koreanAvailable;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    languages.add(language);
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    if (failSpeak) throw Exception('fallo al hablar');
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stops++;
    return 1;
  }
}

/// Catálogo de prueba con solo los términos de voz.
Catalog _catalog() => Catalog(
  version: 1,
  glossary: const [
    GlossaryTerm(
      id: 'si_jak',
      romanization: 'Si-jak',
      hangul: '시작',
      meaning: 'Voz de inicio',
    ),
    GlossaryTerm(
      id: 'guman',
      romanization: 'Guman',
      hangul: '그만',
      meaning: 'Voz de fin',
    ),
  ],
  voiceCommands: const {
    VoiceCommand.start: 'si_jak',
    VoiceCommand.end: 'guman',
  },
  levels: const [],
  patterns: const [],
);

void main() {
  late Catalog catalog;

  setUp(() => catalog = _catalog());

  String text(VoiceCommand command, {required bool korean}) {
    final term = catalog.voiceTerm(command);
    return korean ? term.hangul! : term.romanization;
  }

  test('(a) con voz coreana fija ko-KR y pronuncia el hangul', () async {
    final tts = FakeFlutterTts();
    final announcer = FlutterTtsVoiceAnnouncer(tts: tts);
    await announcer.prepare(catalog);
    announcer
      ..announce(VoiceCommand.start)
      ..announce(VoiceCommand.end);
    await pumpEventQueue();

    expect(tts.availabilityChecks, ['ko-KR']);
    expect(tts.languages, ['ko-KR']);
    expect(tts.spoken, [
      text(VoiceCommand.start, korean: true),
      text(VoiceCommand.end, korean: true),
    ]);
    expect(tts.spoken, ['시작', '그만']);
  });

  test(
    '(b) sin voz coreana no cambia el idioma y pronuncia la romanización',
    () async {
      final tts = FakeFlutterTts(koreanAvailable: false);
      final announcer = FlutterTtsVoiceAnnouncer(tts: tts);
      await announcer.prepare(catalog);
      announcer
        ..announce(VoiceCommand.start)
        ..announce(VoiceCommand.end);
      await pumpEventQueue();

      expect(tts.languages, isEmpty);
      expect(tts.spoken, [
        text(VoiceCommand.start, korean: false),
        text(VoiceCommand.end, korean: false),
      ]);
      expect(tts.spoken, ['Si-jak', 'Guman']);
    },
  );

  test(
    '(c) sin ningún motor de voz, prepare y announce no lanzan ni hablan',
    () async {
      final tts = FakeFlutterTts(failAvailability: true);
      final announcer = FlutterTtsVoiceAnnouncer(tts: tts);
      await expectLater(announcer.prepare(catalog), completes);
      expect(() => announcer.announce(VoiceCommand.start), returnsNormally);
      await pumpEventQueue();

      expect(tts.spoken, isEmpty);
    },
  );

  test('(d) si speak falla, announce no relanza', () async {
    final tts = FakeFlutterTts(failSpeak: true);
    final announcer = FlutterTtsVoiceAnnouncer(tts: tts);
    await announcer.prepare(catalog);
    expect(() => announcer.announce(VoiceCommand.start), returnsNormally);
    // El error asíncrono de speak tampoco escapa.
    await pumpEventQueue();

    expect(tts.spoken, ['시작']);
  });

  test('(e) prepare dos veces configura una sola vez', () async {
    final tts = FakeFlutterTts();
    final announcer = FlutterTtsVoiceAnnouncer(tts: tts);
    await announcer.prepare(catalog);
    await announcer.prepare(catalog);

    expect(tts.availabilityChecks, hasLength(1));
    expect(tts.languages, hasLength(1));
  });

  test('stop llama a tts.stop', () async {
    final tts = FakeFlutterTts();
    await FlutterTtsVoiceAnnouncer(tts: tts).stop();

    expect(tts.stops, 1);
  });
}
