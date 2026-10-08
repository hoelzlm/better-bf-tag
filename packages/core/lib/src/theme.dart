import 'package:flutter/material.dart';

/// The shared BF-Tag theme: Material 3 with a red (Feuerwehr) seed color.
ThemeData bftagTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
  );
}
