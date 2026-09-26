import 'package:flutter/material.dart';

/// Palette dell'app, definita una volta per tema e letta con
/// `context.colors`. I valori seguono il mockup approvato.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.muted,
    required this.line,
    required this.lineSoft,
    required this.amber,
    required this.onAmber,
    required this.cheap,
    required this.cheapFill,
    required this.cheapChipBg,
    required this.cheapChipFg,
    required this.pricey,
    required this.priceyFill,
    required this.neutralPinBg,
    required this.neutralPinFg,
    required this.heroBg,
    required this.heroFg,
    required this.heroMuted,
    required this.heroBorder,
    required this.selectedChipBg,
    required this.selectedChipFg,
    required this.star,
  });

  /// Sfondo delle schermate.
  final Color ground;

  /// Schede e barre.
  final Color surface;

  /// Sfondo dei selettori a segmenti e delle icone nelle liste.
  final Color surfaceMuted;

  /// Testo principale.
  final Color ink;

  /// Testo secondario.
  final Color muted;

  /// Bordi delle schede.
  final Color line;

  /// Divisori interni alle schede.
  final Color lineSoft;

  /// Giallo carburante: azione principale, scheda attiva, logo.
  final Color amber;
  final Color onAmber;

  /// Prezzo sotto la media (testo e linee).
  final Color cheap;

  /// Prezzo sotto la media (riempimenti con testo bianco).
  final Color cheapFill;
  final Color cheapChipBg;
  final Color cheapChipFg;

  /// Prezzo sopra la media (testo e linee).
  final Color pricey;

  /// Prezzo sopra la media (riempimenti con testo bianco).
  final Color priceyFill;
  final Color neutralPinBg;
  final Color neutralPinFg;

  /// Scheda "Il più economico".
  final Color heroBg;
  final Color heroFg;
  final Color heroMuted;
  final Color heroBorder;

  final Color selectedChipBg;
  final Color selectedChipFg;
  final Color star;

  static const light = AppColors(
    ground: Color(0xFFF4F2ED),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE6E2D9),
    ink: Color(0xFF16181D),
    muted: Color(0xFF5A5E66),
    line: Color(0xFFE3E0D8),
    lineSoft: Color(0xFFEEEBE4),
    amber: Color(0xFFF2B632),
    onAmber: Color(0xFF16181D),
    cheap: Color(0xFF1D5BD6),
    cheapFill: Color(0xFF1D5BD6),
    cheapChipBg: Color(0xFFDCE7FF),
    cheapChipFg: Color(0xFF123F99),
    pricey: Color(0xFFB4540A),
    priceyFill: Color(0xFFB4540A),
    neutralPinBg: Color(0xFFFFFFFF),
    neutralPinFg: Color(0xFF16181D),
    heroBg: Color(0xFF16181D),
    heroFg: Color(0xFFFFFFFF),
    heroMuted: Color(0xFFB9BBC2),
    heroBorder: Color(0x00000000),
    selectedChipBg: Color(0xFF16181D),
    selectedChipFg: Color(0xFFFFFFFF),
    star: Color(0xFFE09A00),
  );

  static const dark = AppColors(
    ground: Color(0xFF0F1115),
    surface: Color(0xFF1A1D23),
    surfaceMuted: Color(0xFF262A31),
    ink: Color(0xFFECEDEF),
    muted: Color(0xFF9A9FA8),
    line: Color(0xFF2C3038),
    lineSoft: Color(0xFF262A31),
    amber: Color(0xFFF2B632),
    onAmber: Color(0xFF16181D),
    cheap: Color(0xFF8FB2FF),
    cheapFill: Color(0xFF2F6BE0),
    cheapChipBg: Color(0xFF1E2B4D),
    cheapChipFg: Color(0xFFA9C4FF),
    pricey: Color(0xFFF59A52),
    priceyFill: Color(0xFFA94F0A),
    neutralPinBg: Color(0xFF2C3038),
    neutralPinFg: Color(0xFFECEDEF),
    heroBg: Color(0xFF1C1F26),
    heroFg: Color(0xFFECEDEF),
    heroMuted: Color(0xFF9A9FA8),
    heroBorder: Color(0xFFF2B632),
    selectedChipBg: Color(0xFFECEDEF),
    selectedChipFg: Color(0xFF0F1115),
    star: Color(0xFFF2B632),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      ground: l(ground, other.ground),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      lineSoft: l(lineSoft, other.lineSoft),
      amber: l(amber, other.amber),
      onAmber: l(onAmber, other.onAmber),
      cheap: l(cheap, other.cheap),
      cheapFill: l(cheapFill, other.cheapFill),
      cheapChipBg: l(cheapChipBg, other.cheapChipBg),
      cheapChipFg: l(cheapChipFg, other.cheapChipFg),
      pricey: l(pricey, other.pricey),
      priceyFill: l(priceyFill, other.priceyFill),
      neutralPinBg: l(neutralPinBg, other.neutralPinBg),
      neutralPinFg: l(neutralPinFg, other.neutralPinFg),
      heroBg: l(heroBg, other.heroBg),
      heroFg: l(heroFg, other.heroFg),
      heroMuted: l(heroMuted, other.heroMuted),
      heroBorder: l(heroBorder, other.heroBorder),
      selectedChipBg: l(selectedChipBg, other.selectedChipBg),
      selectedChipFg: l(selectedChipFg, other.selectedChipFg),
      star: l(star, other.star),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
