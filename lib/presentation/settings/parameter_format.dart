import '../../domain/exercise/exercise_parameters.dart';

/// Formatos de la configuración (Spec 005, FR-005, FR-006; data-model §7).
/// Todo con milisegundos enteros, para evitar redondeos de `double`.

/// Segundos con punto decimal, entre uno y dos decimales:
/// 330 ms → "0.33 s", 700 → "0.7 s", 1000 → "1.0 s", 2500 → "2.5 s".
String formatSeconds(Duration d) {
  final ms = d.inMilliseconds;
  final whole = ms ~/ 1000;
  final hundredths = (ms % 1000) ~/ 10;
  final decimals = hundredths % 10 == 0
      ? '${hundredths ~/ 10}'
      : hundredths.toString().padLeft(2, '0');
  return '$whole.$decimals s';
}

/// Duración del ejercicio: "45 s" por debajo de 1 min; "1 min",
/// "2 min 15 s" o "3 min" a partir de 1 min.
String formatDuration(Duration d) {
  final total = d.inSeconds;
  if (total < 60) return '$total s';
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return seconds == 0 ? '$minutes min' : '$minutes min $seconds s';
}

/// Rango real del sorteo del intervalo: desde el piso (velocidad del corte +
/// 0.5 s) hasta el intervalo configurado (FR-005; Spec 001, FR-011).
String formatIntervalRange(ExerciseParameters p) {
  final floor = p.intervalFloor;
  final max = p.attackInterval;
  if (floor == max) return 'Cada ataque: ${formatSeconds(max)}';
  return 'Cada ataque: entre ${formatSeconds(floor)} y '
      '${formatSeconds(max)}, al azar';
}

/// Aviso del ajuste automático del intervalo (FR-008).
String formatAdjustment(Duration interval) =>
    'Intervalo ajustado a ${formatSeconds(interval)}: debe ser al menos la '
    'velocidad del corte + 0.5 s';
