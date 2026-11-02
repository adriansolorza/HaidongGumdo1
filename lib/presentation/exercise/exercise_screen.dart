import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exercise/exercise_status.dart';
import '../../domain/exercise/session.dart';
import '../strings_es.dart';
import '../theme.dart';
import 'exercise_controller.dart';
import 'painters/opponent_painter.dart';
import 'painters/signal_painter.dart';

/// Pantalla del ejercicio (contracts/ui-screens.md). Un Ticker avanza el motor
/// en cada cuadro hasta llegar a un estado terminal.
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.session});

  final Session session;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration _) {
    ref.read(exerciseControllerProvider.notifier).onFrame();
    if (ref.read(exerciseControllerProvider).status.isTerminal) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tras Repetir el estado vuelve de terminal a countdown: reanudar el Ticker.
    ref.listen(exerciseControllerProvider, (previous, next) {
      if ((previous?.status.isTerminal ?? false) &&
          next.status == ExerciseStatus.countdown &&
          !_ticker.isActive) {
        _ticker.start();
      }
    });
    final snapshot = ref.watch(exerciseControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: OpponentPainter(
              saberColor: snapshot.saberColor,
              inStance: _inStance(snapshot.status),
              cut: widget.session.pattern.cut,
              side: snapshot.currentAttack?.side,
              cutProgress: snapshot.cutProgress,
            ),
          ),
          if (snapshot.signal case final signal?)
            CustomPaint(painter: SignalPainter(signal: signal)),
          if (snapshot.status == ExerciseStatus.countdown &&
              snapshot.countdownValue != null)
            Center(
              child: Text(
                '${snapshot.countdownValue}',
                style: textTheme.displayLarge,
              ),
            ),
          Positioned(
            top: 16,
            right: 24,
            child: SafeArea(
              child: Text(
                '${StringsEs.remaining} ${_seconds(snapshot.remaining)} s',
                style: textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          if (snapshot.status == ExerciseStatus.finished)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          ref.read(exerciseControllerProvider.notifier).repeat(),
                      child: const Text(StringsEs.repeat),
                    ),
                    const SizedBox(width: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(StringsEs.back),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// En reposo hasta *Si-jak*; después, la postura del patrón (FR-010a).
  static bool _inStance(ExerciseStatus status) =>
      status != ExerciseStatus.ready && status != ExerciseStatus.countdown;

  static int _seconds(Duration remaining) =>
      (remaining.inMilliseconds / 1000).ceil();
}
