import 'dart:async';

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
  late final ExerciseController _controller;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // En dispose ya no se puede usar ref: se guarda el controlador aquí.
    _controller = ref.read(exerciseControllerProvider.notifier);
    _ticker = createTicker(_onTick)..start();
    // Segundo plano cancela (FR-022). `inactive` no: la barra de
    // notificaciones también lo dispara (R10).
    _lifecycle = AppLifecycleListener(
      onHide: _cancelAndLeave,
      onPause: _cancelAndLeave,
    );
  }

  /// Única rutina de cancelación: Detener, onHide y onPause. Android emite
  /// onHide y onPause seguidos; solo la llamada que cancela navega.
  Future<void> _cancelAndLeave() async {
    final cancelled = await _controller.cancel();
    if (cancelled && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _onTick(Duration _) {
    ref.read(exerciseControllerProvider.notifier).onFrame();
    if (ref.read(exerciseControllerProvider).status.isTerminal) _ticker.stop();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    // Salida sin Detener (p. ej. botón Atrás de Android): no dejar nada sonando.
    unawaited(_controller.cancel());
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
              guard: widget.session.pattern.guard,
              cut: widget.session.pattern.cut,
              motion: snapshot.motion,
            ),
          ),
          if (snapshot.signal case final signal?)
            CustomPaint(
              painter: SignalPainter(
                signal: signal,
                saberColor: snapshot.saberColor,
              ),
            ),
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
          if (_isActive(snapshot.status))
            Positioned(
              top: 16,
              left: 24,
              child: SafeArea(
                child: OutlinedButton(
                  onPressed: _cancelAndLeave,
                  child: const Text(StringsEs.stop),
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
                      onPressed: () => ref
                          .read(exerciseControllerProvider.notifier)
                          .repeat(),
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

  /// Detener solo se ofrece mientras el ejercicio se puede cancelar.
  static bool _isActive(ExerciseStatus status) =>
      status == ExerciseStatus.countdown ||
      status == ExerciseStatus.running ||
      status == ExerciseStatus.finishing;

  static int _seconds(Duration remaining) =>
      (remaining.inMilliseconds / 1000).ceil();
}
