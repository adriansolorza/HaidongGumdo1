import 'package:haidonggumdo/domain/ports/screen_wake_lock.dart';

/// Registra las llamadas y expone si la pantalla quedó encendida.
final class FakeScreenWakeLock implements ScreenWakeLock {
  final List<String> calls = [];
  bool _enabled = false;

  bool get enabled => _enabled;

  @override
  Future<void> enable() async {
    calls.add('enable');
    _enabled = true;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    _enabled = false;
  }
}
