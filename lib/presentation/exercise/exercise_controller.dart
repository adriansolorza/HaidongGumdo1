import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog/enums.dart';
import '../../domain/exercise/exercise_engine.dart';
import '../../domain/exercise/exercise_event.dart';
import '../../domain/exercise/exercise_snapshot.dart';
import '../../domain/exercise/exercise_status.dart';
import '../../domain/exercise/opponent_motion.dart';
import '../../domain/exercise/session.dart';
import '../providers.dart';

final exerciseControllerProvider =
    NotifierProvider<ExerciseController, ExerciseSnapshot>(
      ExerciseController.new,
    );

/// Une el motor con el reloj y aplica los efectos de cada evento
/// (contracts/ui-screens.md, "Efectos secundarios").
final class ExerciseController extends Notifier<ExerciseSnapshot> {
  ExerciseEngine? _engine;
  Session? _session;

  @override
  ExerciseSnapshot build() {
    final parameters = ref.read(exerciseParametersProvider);
    return ExerciseSnapshot(
      status: ExerciseStatus.ready,
      saberColor: SaberColor.white,
      motion: OpponentMotion.atGuard,
      elapsed: Duration.zero,
      remaining: ExerciseEngine.countdownLength + parameters.duration,
    );
  }

  /// Empieza un ejercicio nuevo con los parámetros vigentes.
  void start(Session session) {
    final engine = ExerciseEngine(
      session: session,
      parameters: ref.read(exerciseParametersProvider),
      random: ref.read(randomSourceProvider),
    );
    _engine = engine;
    _session = session;
    ref.read(elapsedClockProvider).start();
    engine.start();
    unawaited(ref.read(screenWakeLockProvider).enable());
    state = engine.advanceTo(Duration.zero).snapshot;
  }

  /// Avanza el motor hasta el tiempo del reloj. Se llama en cada cuadro.
  void onFrame() {
    final engine = _engine;
    if (engine == null || engine.status.isTerminal) return;
    final tick = engine.advanceTo(ref.read(elapsedClockProvider).elapsed);
    final voice = ref.read(voiceAnnouncerProvider);
    for (final event in tick.events) {
      switch (event) {
        case StartVoice():
          voice.announce(VoiceCommand.start);
        case EndVoice():
          voice.announce(VoiceCommand.end);
        case SignalShown() || CutStarted() || CutEnded() || Cancelled():
          break;
      }
    }
    state = tick.snapshot;
    if (tick.snapshot.status == ExerciseStatus.finished) {
      unawaited(ref.read(screenWakeLockProvider).disable());
    }
  }

  /// Cancela el ejercicio activo (FR-021–FR-023). Devuelve `true` solo si esta
  /// llamada lo canceló; `false` si no había ejercicio activo (idempotente).
  Future<bool> cancel() async {
    final engine = _engine;
    if (engine == null || engine.status.isTerminal) return false;
    // Los puertos se leen antes de esperar: tras un `await` el provider puede
    // estar ya liberado (p. ej. al cerrar la app desde la pantalla del ejercicio).
    final voice = ref.read(voiceAnnouncerProvider);
    final wakeLock = ref.read(screenWakeLockProvider);
    state = engine.cancel().snapshot;
    await voice.stop();
    await wakeLock.disable();
    return true;
  }

  /// Otro ejercicio con la misma sesión (FR-014).
  void repeat() {
    final session = _session;
    if (session != null) start(session);
  }
}
