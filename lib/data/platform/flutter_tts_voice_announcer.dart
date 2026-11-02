import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/enums.dart';
import '../../domain/ports/voice_announcer.dart';

/// Voces de mando con flutter_tts (research R8). Nunca relanza errores del motor.
final class FlutterTtsVoiceAnnouncer implements VoiceAnnouncer {
  FlutterTtsVoiceAnnouncer({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const String _korean = 'ko-KR';

  final FlutterTts _tts;
  Map<VoiceCommand, String>? _texts;

  @override
  Future<void> prepare(Catalog catalog) async {
    if (_texts != null) return;
    try {
      final korean = await _tts.isLanguageAvailable(_korean) == true;
      if (korean) await _tts.setLanguage(_korean);
      _texts = {
        for (final command in VoiceCommand.values)
          command: _textFor(catalog.voiceTerm(command), korean: korean),
      };
    } catch (_) {
      _texts = null;
    }
  }

  // Una voz no coreana no lee hangul: usa la romanización (FR-030).
  String _textFor(GlossaryTerm term, {required bool korean}) =>
      korean ? (term.hangul ?? term.romanization) : term.romanization;

  @override
  void announce(VoiceCommand command) {
    final text = _texts?[command];
    if (text == null) return;
    unawaited(_tts.speak(text).catchError((Object _) => null));
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
