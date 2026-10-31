import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/ports/voice_announcer.dart';

/// Llamada registrada por [FakeVoiceAnnouncer].
sealed class VoiceCall {
  const VoiceCall();
}

final class PrepareCall extends VoiceCall {
  const PrepareCall(this.catalog);

  final Catalog catalog;
}

final class AnnounceCall extends VoiceCall {
  const AnnounceCall(this.command);

  final VoiceCommand command;

  @override
  bool operator ==(Object other) =>
      other is AnnounceCall && other.command == command;

  @override
  int get hashCode => command.hashCode;
}

final class StopCall extends VoiceCall {
  const StopCall();

  @override
  bool operator ==(Object other) => other is StopCall;

  @override
  int get hashCode => (StopCall).hashCode;
}

/// Registra en orden las llamadas a la voz.
final class FakeVoiceAnnouncer implements VoiceAnnouncer {
  final List<VoiceCall> calls = [];

  /// Comandos anunciados, en orden.
  List<VoiceCommand> get announced => [
    for (final call in calls)
      if (call is AnnounceCall) call.command,
  ];

  @override
  Future<void> prepare(Catalog catalog) async =>
      calls.add(PrepareCall(catalog));

  @override
  void announce(VoiceCommand command) => calls.add(AnnounceCall(command));

  @override
  Future<void> stop() async => calls.add(const StopCall());
}
