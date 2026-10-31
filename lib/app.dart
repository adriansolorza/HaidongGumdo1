import 'package:flutter/material.dart';

import 'presentation/strings_es.dart';
import 'presentation/theme.dart';

class HaidongGumdoApp extends StatelessWidget {
  const HaidongGumdoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: StringsEs.appTitle,
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      // Temporal hasta que exista la pantalla de selección (T036).
      home: const Scaffold(),
    );
  }
}
