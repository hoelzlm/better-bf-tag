// BF-Tag theme: Designsystem `docs/design/design-system.md` (§2 Farben,
// §3 Typografie, §4 Abstände/Radien/Elevation, §5 Komponenten, §8
// Fokusring, §10 Flutter-Abbildung). Decisions: docs/adr/0027.
//
// Three modes share one set of tokens (table 2.1): `light` is the only
// bright mode, `dark` and `monitor` both use the "Dunkel/Monitor" column
// (§2.2 — app-dark and monitor must look identical). `monitor` additionally
// carries [BftagMonitorTextStyles] for the large 1920x1080 type scale
// (§3.2); it is NOT applied to [ThemeData.textTheme] (same app, third mode,
// not a second MaterialApp).
import 'package:flutter/material.dart';

import 'domain/fms_status.dart';

/// The three theme modes BF-Tag renders: bright admin-web/app, dark app,
/// and the always-dark monitor (never follows system brightness).
enum BftagThemeMode { light, dark, monitor }

/// Returns the [ThemeData] for [mode]. Prefer the named helpers
/// ([bftagLightTheme], [bftagDarkTheme], [bftagMonitorTheme]) at call
/// sites; this exists for generic/parameterized use (e.g. tests iterating
/// all modes).
ThemeData bftagTheme(BftagThemeMode mode) {
  switch (mode) {
    case BftagThemeMode.light:
      return bftagLightTheme();
    case BftagThemeMode.dark:
      return bftagDarkTheme();
    case BftagThemeMode.monitor:
      return bftagMonitorTheme();
  }
}

/// Admin-Web and App (hell).
ThemeData bftagLightTheme() => _buildTheme(_light, isMonitor: false);

/// App (dunkel, `ThemeMode.system`).
ThemeData bftagDarkTheme() => _buildTheme(_dark, isMonitor: false);

/// Monitor: immer dunkel + Monitor-Typskala (§3.2), unabhängig vom
/// System-Theme.
ThemeData bftagMonitorTheme() => _buildTheme(_dark, isMonitor: true);

// ---------------------------------------------------------------------------
// Tokens (Designsystem Tabelle 2.1 — Neutral- und Akzentfarben)
// ---------------------------------------------------------------------------

class _Tokens {
  const _Tokens({
    required this.brightness,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.alarm,
    required this.onAlarm,
    required this.alarmContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
  });

  final Brightness brightness;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color outline;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color alarm;
  final Color onAlarm;
  final Color alarmContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
}

const _light = _Tokens(
  brightness: Brightness.light,
  surface: Color(0xFFFFFFFF),
  surfaceVariant: Color(0xFFF1F3F5),
  surfaceContainer: Color(0xFFE8EAED),
  outline: Color(0xFFC9CED3),
  onSurface: Color(0xFF1B1F23),
  onSurfaceVariant: Color(0xFF4C555C),
  primary: Color(0xFF0B5E6B),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD6EEF2),
  alarm: Color(0xFFD32F2F),
  onAlarm: Color(0xFFFFFFFF),
  alarmContainer: Color(0xFFFBE9E7),
  warning: Color(0xFFB45309),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFDECD2),
);

/// "Dunkel/Monitor" column of table 2.1 — used by both `dark` and
/// `monitor` mode (§2.2: identical palette, no second dark variant).
const _dark = _Tokens(
  brightness: Brightness.dark,
  surface: Color(0xFF14181C),
  surfaceVariant: Color(0xFF1C2126),
  surfaceContainer: Color(0xFF242A30),
  outline: Color(0xFF3A4147),
  onSurface: Color(0xFFEDEFF1),
  onSurfaceVariant: Color(0xFFAAB2B8),
  primary: Color(0xFF4FB8C9),
  onPrimary: Color(0xFF06262B),
  primaryContainer: Color(0xFF0E3A42),
  alarm: Color(0xFFFF5449),
  onAlarm: Color(0xFF1A0000),
  alarmContainer: Color(0xFF4A1410),
  warning: Color(0xFFF2A93B),
  onWarning: Color(0xFF1A1100),
  warningContainer: Color(0xFF4A2E08),
);

// FMS-Statusfarben (Tabelle 2.4) — fix, identisch in allen drei Modi.
const _fms1 = Color(0xFF2E7D32);
const _onFms1 = Color(0xFFFFFFFF);
const _fms2 = Color(0xFF43A047);
const _onFms2 = Color(0xFF0B1F0D);
const _fms3 = Color(0xFFF2A900);
const _onFms3 = Color(0xFF1B1300);
const _fms4 = Color(0xFF7A3FC2);
const _onFms4 = Color(0xFFFFFFFF);
const _fms5 = Color(0xFFAD1A72);
const _onFms5 = Color(0xFFFFFFFF);
const _fms6 = Color(0xFF6B7280);
const _onFms6 = Color(0xFFFFFFFF);
const _fms7 = Color(0xFF2660D1);
const _onFms7 = Color(0xFFFFFFFF);
const _fms8 = Color(0xFF1455B0);
const _onFms8 = Color(0xFFFFFFFF);

const _fontFamily = 'Inter';
const _fontPackage = 'bftag_core';

// ---------------------------------------------------------------------------
// ThemeData assembly
// ---------------------------------------------------------------------------

ThemeData _buildTheme(_Tokens t, {required bool isMonitor}) {
  final colorScheme = ColorScheme(
    brightness: t.brightness,
    primary: t.primary,
    onPrimary: t.onPrimary,
    primaryContainer: t.primaryContainer,
    onPrimaryContainer: t.onSurface,
    secondary: t.primary,
    onSecondary: t.onPrimary,
    secondaryContainer: t.primaryContainer,
    onSecondaryContainer: t.onSurface,
    tertiary: t.primary,
    onTertiary: t.onPrimary,
    tertiaryContainer: t.primaryContainer,
    onTertiaryContainer: t.onSurface,
    // ColorScheme.error maps to the `warning` tokens (Formular-/
    // Validierungsfehler), NOT to `alarm` — Grundprinzip 1, §2.1/§10.
    // Alarmrot lebt ausschließlich in [BftagAlarmColors].
    error: t.warning,
    onError: t.onWarning,
    errorContainer: t.warningContainer,
    onErrorContainer: t.onSurface,
    surface: t.surface,
    onSurface: t.onSurface,
    surfaceDim: t.surfaceVariant,
    surfaceBright: t.surface,
    surfaceContainerLowest: t.surface,
    surfaceContainerLow: t.surfaceVariant,
    surfaceContainer: t.surfaceVariant,
    surfaceContainerHigh: t.surfaceContainer,
    surfaceContainerHighest: t.surfaceContainer,
    onSurfaceVariant: t.onSurfaceVariant,
    outline: t.outline,
    outlineVariant: t.outline,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: t.onSurface,
    onInverseSurface: t.surface,
    inversePrimary: t.brightness == Brightness.light
        ? _dark.primary
        : _light.primary,
    // No `fromSeed`-derived tonal elevation tint (§4.3: Flächentrennung
    // über Farbe, nicht über Tönung).
    surfaceTint: Colors.transparent,
  );

  final textTheme = _textTheme(t);
  final radii = const BftagRadii();
  final spacing = const BftagSpacing();

  return ThemeData(
    useMaterial3: true,
    brightness: t.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: t.surface,
    textTheme: textTheme,
    focusColor: t.primary.withValues(alpha: 0.4),
    splashFactory: InkRipple.splashFactory,
    cardTheme: CardThemeData(
      color: t.surfaceVariant,
      elevation: t.brightness == Brightness.light ? 1 : 0,
      shadowColor: t.brightness == Brightness.light
          ? Colors.black
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.large),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.large),
      ),
      titleTextStyle: textTheme.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.primaryContainer,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.onSurface),
      actionTextColor: t.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.medium),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.warning),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.warning, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.medium),
        borderSide: BorderSide(color: t.outline.withValues(alpha: 0.4)),
      ),
      labelStyle: textTheme.bodyLarge?.copyWith(color: t.onSurfaceVariant),
      errorStyle: textTheme.bodyMedium?.copyWith(color: t.warning),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.medium),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: t.primary, width: 2)
              : null,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(t.onSurface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.medium),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: t.primary, width: 2)
              : BorderSide(color: t.outline, width: 1),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ? t.surfaceVariant : null,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(t.primary),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.medium),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: t.primary, width: 2)
              : null,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surfaceVariant,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => (textTheme.labelMedium ?? const TextStyle()).copyWith(
          color: states.contains(WidgetState.selected)
              ? t.primary
              : t.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? t.primary
              : t.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: t.surfaceVariant,
      indicatorColor: t.primaryContainer,
      selectedIconTheme: IconThemeData(color: t.primary),
      unselectedIconTheme: IconThemeData(color: t.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: t.primary),
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: t.onSurfaceVariant,
      ),
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: t.primary,
      selectedTileColor: t.primaryContainer,
      iconColor: t.onSurfaceVariant,
      textColor: t.onSurface,
    ),
    extensions: <ThemeExtension<dynamic>>[
      BftagStatusColors(
        fms1: _fms1,
        fms2: _fms2,
        fms3: _fms3,
        fms4: _fms4,
        fms5: _fms5,
        fms6: _fms6,
        fms7: _fms7,
        fms8: _fms8,
        onFms1: _onFms1,
        onFms2: _onFms2,
        onFms3: _onFms3,
        onFms4: _onFms4,
        onFms5: _onFms5,
        onFms6: _onFms6,
        onFms7: _onFms7,
        onFms8: _onFms8,
      ),
      BftagAlarmColors(
        alarm: t.alarm,
        onAlarm: t.onAlarm,
        alarmContainer: t.alarmContainer,
      ),
      spacing,
      radii,
      _monitorTextStyles(t),
    ],
  );
}

TextTheme _textTheme(_Tokens t) {
  TextStyle style(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontFamily: _fontFamily,
        package: _fontPackage,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: t.onSurface,
      );

  return TextTheme(
    displaySmall: style(32, 40, FontWeight.w600),
    headlineSmall: style(24, 32, FontWeight.w600),
    titleLarge: style(20, 28, FontWeight.w600),
    titleMedium: style(16, 24, FontWeight.w500),
    bodyLarge: style(16, 24, FontWeight.w400),
    bodyMedium: style(14, 20, FontWeight.w400),
    labelLarge: style(14, 20, FontWeight.w500),
    labelMedium: style(12, 16, FontWeight.w500),
  );
}

/// Monitor-Typskala (§3.2) — eigene Extension statt `TextTheme`, siehe §10.
BftagMonitorTextStyles _monitorTextStyles(_Tokens t) {
  TextStyle style(double size, FontWeight weight) => TextStyle(
    fontFamily: _fontFamily,
    package: _fontPackage,
    fontSize: size,
    fontWeight: weight,
    color: t.onSurface,
  );

  return BftagMonitorTextStyles(
    alarmTitle: style(96, FontWeight.w700),
    display: style(64, FontWeight.w600),
    headline: style(40, FontWeight.w600),
    body: style(28, FontWeight.w400),
    label: style(22, FontWeight.w500),
  );
}

// ---------------------------------------------------------------------------
// ThemeExtensions (Designsystem §10)
// ---------------------------------------------------------------------------

/// FMS-Statusfarben (Tabelle 2.4) — identisch in allen drei Modi.
@immutable
class BftagStatusColors extends ThemeExtension<BftagStatusColors> {
  const BftagStatusColors({
    required this.fms1,
    required this.fms2,
    required this.fms3,
    required this.fms4,
    required this.fms5,
    required this.fms6,
    required this.fms7,
    required this.fms8,
    required this.onFms1,
    required this.onFms2,
    required this.onFms3,
    required this.onFms4,
    required this.onFms5,
    required this.onFms6,
    required this.onFms7,
    required this.onFms8,
  });

  final Color fms1, fms2, fms3, fms4, fms5, fms6, fms7, fms8;
  final Color onFms1, onFms2, onFms3, onFms4, onFms5, onFms6, onFms7, onFms8;

  /// Fläche für [status] (Tabelle 2.4).
  Color colorFor(FmsStatus status) => switch (status) {
    FmsStatus.s1 => fms1,
    FmsStatus.s2 => fms2,
    FmsStatus.s3 => fms3,
    FmsStatus.s4 => fms4,
    FmsStatus.s5 => fms5,
    FmsStatus.s6 => fms6,
    FmsStatus.s7 => fms7,
    FmsStatus.s8 => fms8,
  };

  /// Text-/Icon-Farbe auf der Fläche von [status] (Tabelle 2.4).
  Color onColorFor(FmsStatus status) => switch (status) {
    FmsStatus.s1 => onFms1,
    FmsStatus.s2 => onFms2,
    FmsStatus.s3 => onFms3,
    FmsStatus.s4 => onFms4,
    FmsStatus.s5 => onFms5,
    FmsStatus.s6 => onFms6,
    FmsStatus.s7 => onFms7,
    FmsStatus.s8 => onFms8,
  };

  @override
  BftagStatusColors copyWith({
    Color? fms1,
    Color? fms2,
    Color? fms3,
    Color? fms4,
    Color? fms5,
    Color? fms6,
    Color? fms7,
    Color? fms8,
    Color? onFms1,
    Color? onFms2,
    Color? onFms3,
    Color? onFms4,
    Color? onFms5,
    Color? onFms6,
    Color? onFms7,
    Color? onFms8,
  }) {
    return BftagStatusColors(
      fms1: fms1 ?? this.fms1,
      fms2: fms2 ?? this.fms2,
      fms3: fms3 ?? this.fms3,
      fms4: fms4 ?? this.fms4,
      fms5: fms5 ?? this.fms5,
      fms6: fms6 ?? this.fms6,
      fms7: fms7 ?? this.fms7,
      fms8: fms8 ?? this.fms8,
      onFms1: onFms1 ?? this.onFms1,
      onFms2: onFms2 ?? this.onFms2,
      onFms3: onFms3 ?? this.onFms3,
      onFms4: onFms4 ?? this.onFms4,
      onFms5: onFms5 ?? this.onFms5,
      onFms6: onFms6 ?? this.onFms6,
      onFms7: onFms7 ?? this.onFms7,
      onFms8: onFms8 ?? this.onFms8,
    );
  }

  @override
  BftagStatusColors lerp(ThemeExtension<BftagStatusColors>? other, double t) {
    if (other is! BftagStatusColors) return this;
    return BftagStatusColors(
      fms1: Color.lerp(fms1, other.fms1, t)!,
      fms2: Color.lerp(fms2, other.fms2, t)!,
      fms3: Color.lerp(fms3, other.fms3, t)!,
      fms4: Color.lerp(fms4, other.fms4, t)!,
      fms5: Color.lerp(fms5, other.fms5, t)!,
      fms6: Color.lerp(fms6, other.fms6, t)!,
      fms7: Color.lerp(fms7, other.fms7, t)!,
      fms8: Color.lerp(fms8, other.fms8, t)!,
      onFms1: Color.lerp(onFms1, other.onFms1, t)!,
      onFms2: Color.lerp(onFms2, other.onFms2, t)!,
      onFms3: Color.lerp(onFms3, other.onFms3, t)!,
      onFms4: Color.lerp(onFms4, other.onFms4, t)!,
      onFms5: Color.lerp(onFms5, other.onFms5, t)!,
      onFms6: Color.lerp(onFms6, other.onFms6, t)!,
      onFms7: Color.lerp(onFms7, other.onFms7, t)!,
      onFms8: Color.lerp(onFms8, other.onFms8, t)!,
    );
  }
}

/// Alarmfarben (Tabelle 2.1) — ausschließlich hier, NICHT in
/// `ColorScheme.error` (Grundprinzip 1).
@immutable
class BftagAlarmColors extends ThemeExtension<BftagAlarmColors> {
  const BftagAlarmColors({
    required this.alarm,
    required this.onAlarm,
    required this.alarmContainer,
  });

  final Color alarm, onAlarm, alarmContainer;

  @override
  BftagAlarmColors copyWith({
    Color? alarm,
    Color? onAlarm,
    Color? alarmContainer,
  }) {
    return BftagAlarmColors(
      alarm: alarm ?? this.alarm,
      onAlarm: onAlarm ?? this.onAlarm,
      alarmContainer: alarmContainer ?? this.alarmContainer,
    );
  }

  @override
  BftagAlarmColors lerp(ThemeExtension<BftagAlarmColors>? other, double t) {
    if (other is! BftagAlarmColors) return this;
    return BftagAlarmColors(
      alarm: Color.lerp(alarm, other.alarm, t)!,
      onAlarm: Color.lerp(onAlarm, other.onAlarm, t)!,
      alarmContainer: Color.lerp(alarmContainer, other.alarmContainer, t)!,
    );
  }
}

/// Abstandsraster (§4.1), 4/8-pt.
@immutable
class BftagSpacing extends ThemeExtension<BftagSpacing> {
  const BftagSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
    this.huge = 64,
  });

  final double xs, sm, md, lg, xl, xxl, xxxl, huge;

  @override
  BftagSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
  }) {
    return BftagSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
    );
  }

  @override
  BftagSpacing lerp(ThemeExtension<BftagSpacing>? other, double t) {
    if (other is! BftagSpacing) return this;
    return BftagSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
      xxxl: lerpDouble(xxxl, other.xxxl, t),
      huge: lerpDouble(huge, other.huge, t),
    );
  }
}

/// Radien (§4.2).
@immutable
class BftagRadii extends ThemeExtension<BftagRadii> {
  const BftagRadii({
    this.small = 8,
    this.medium = 12,
    this.large = 16,
    this.full = 999,
  });

  final double small, medium, large, full;

  @override
  BftagRadii copyWith({
    double? small,
    double? medium,
    double? large,
    double? full,
  }) {
    return BftagRadii(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      full: full ?? this.full,
    );
  }

  @override
  BftagRadii lerp(ThemeExtension<BftagRadii>? other, double t) {
    if (other is! BftagRadii) return this;
    return BftagRadii(
      small: lerpDouble(small, other.small, t),
      medium: lerpDouble(medium, other.medium, t),
      large: lerpDouble(large, other.large, t),
      full: lerpDouble(full, other.full, t),
    );
  }
}

/// Monitor-Typskala (§3.2) — eigenständig, da keine `ColorScheme`/
/// `TextTheme`-Rolle (§10).
@immutable
class BftagMonitorTextStyles extends ThemeExtension<BftagMonitorTextStyles> {
  const BftagMonitorTextStyles({
    required this.alarmTitle,
    required this.display,
    required this.headline,
    required this.body,
    required this.label,
  });

  final TextStyle alarmTitle, display, headline, body, label;

  @override
  BftagMonitorTextStyles copyWith({
    TextStyle? alarmTitle,
    TextStyle? display,
    TextStyle? headline,
    TextStyle? body,
    TextStyle? label,
  }) {
    return BftagMonitorTextStyles(
      alarmTitle: alarmTitle ?? this.alarmTitle,
      display: display ?? this.display,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      label: label ?? this.label,
    );
  }

  @override
  BftagMonitorTextStyles lerp(
    ThemeExtension<BftagMonitorTextStyles>? other,
    double t,
  ) {
    if (other is! BftagMonitorTextStyles) return this;
    return BftagMonitorTextStyles(
      alarmTitle: TextStyle.lerp(alarmTitle, other.alarmTitle, t)!,
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;
