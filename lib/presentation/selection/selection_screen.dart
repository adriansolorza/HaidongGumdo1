import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog/catalog.dart';
import '../../domain/exercise/session.dart';
import '../exercise/exercise_controller.dart';
import '../exercise/exercise_screen.dart';
import '../providers.dart';
import '../strings_es.dart';

/// Elección de nivel y patrón (contracts/ui-screens.md). Todos los textos de
/// niveles, patrones y términos salen del catálogo (SC-009).
class SelectionScreen extends ConsumerWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final session = ref.watch(selectedSessionProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: catalog.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(StringsEs.loadingCatalog),
                      ],
                    ),
                  ),
                  error: (_, _) => Center(
                    child: Text(
                      StringsEs.catalogError,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (catalog) => session == null
                      ? const SizedBox.shrink()
                      : _Lists(catalog: catalog, session: session),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: FilledButton(
                  onPressed: catalog.hasValue && session != null
                      ? () => _start(context, ref, session)
                      : null,
                  child: Text(
                    StringsEs.start,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, WidgetRef ref, Session session) {
    ref.read(exerciseControllerProvider.notifier).start(session);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExerciseScreen(session: session)),
    );
  }
}

/// Listas "Nivel" y "Patrón" lado a lado.
class _Lists extends ConsumerWidget {
  const _Lists({required this.catalog, required this.session});

  final Catalog catalog;
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(selectedSessionProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OptionList(
            header: StringsEs.levelHeader,
            children: [
              for (final level in catalog.levels)
                ListTile(
                  title: Text(level.name),
                  subtitle: Text('${level.responseLabel} — ${level.purpose}'),
                  selected: level == session.level,
                  onTap: () => notifier.selectLevel(level),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OptionList(
            header: StringsEs.patternHeader,
            children: [
              for (final pattern in catalog.patterns)
                ListTile(
                  title: Text(pattern.name),
                  subtitle: Text(
                    '${_termLabel(catalog.term(pattern.stanceTermId))} → '
                    '${_termLabel(catalog.term(pattern.cutTermId))}',
                  ),
                  selected: pattern == session.pattern,
                  onTap: () => notifier.selectPattern(pattern),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _termLabel(GlossaryTerm term) => term.hangul == null
      ? term.romanization
      : '${term.romanization} (${term.hangul})';
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.header, required this.children});

  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(header, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Expanded(child: ListView(children: children)),
      ],
    );
  }
}
