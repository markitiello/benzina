import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Font dei titoli e dei prezzi grandi.
TextStyle displayStyle({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.bricolageGrotesque(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.light
      ? AppColors.light
      : AppColors.dark;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.amber,
        brightness: brightness,
      ).copyWith(
        primary: colors.amber,
        onPrimary: colors.onAmber,
        secondary: colors.cheapFill,
        surface: colors.ground,
        onSurface: colors.ink,
        outline: colors.line,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.ground,
    extensions: [colors],
  );

  final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme)
      .apply(bodyColor: colors.ink, displayColor: colors.ink);

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.ground,
      foregroundColor: colors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: displayStyle(fontSize: 20, color: colors.ink),
    ),
    dividerTheme: DividerThemeData(color: colors.lineSoft, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.amber,
      surfaceTintColor: Colors.transparent,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.onAmber
              : colors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.ink
              : colors.muted,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colors.cheapFill : null,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.amber,
        foregroundColor: colors.onAmber,
        minimumSize: const Size(0, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: colors.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
