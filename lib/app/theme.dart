/// Translates the contract's semantic intent into this platform's tokens.
///
/// [BrandColors] declares the tokens sections paint with (brand, onBrand...).
/// `screen.theme` only swaps their values: the page wraps the screen in
/// `Theme(data: themeOf(screen.theme))` and sections never know which theme
/// is on. (Web: app/theme.css.)
library;

import 'package:material_ui/material_ui.dart';

class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.brand,
    required this.onBrand,
    required this.highlight,
    required this.onHighlight,
    this.ink = const Color(0xFF1D1B1A),
    this.muted = const Color(0xFF6B6460),
    this.surface = const Color(0xFFF3F2F0),
  });

  final Color brand;
  final Color onBrand;
  final Color highlight;
  final Color onHighlight;
  final Color ink;
  final Color muted;
  final Color surface;

  static BrandColors of(BuildContext context) => Theme.of(context).extension<BrandColors>()!;

  @override
  BrandColors copyWith({Color? brand, Color? onBrand, Color? highlight, Color? onHighlight}) => BrandColors(
        brand: brand ?? this.brand,
        onBrand: onBrand ?? this.onBrand,
        highlight: highlight ?? this.highlight,
        onHighlight: onHighlight ?? this.onHighlight,
        ink: ink,
        muted: muted,
        surface: surface,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) => other == null
      ? this
      : BrandColors(
          brand: Color.lerp(brand, other.brand, t)!,
          onBrand: Color.lerp(onBrand, other.onBrand, t)!,
          highlight: Color.lerp(highlight, other.highlight, t)!,
          onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
          ink: Color.lerp(ink, other.ink, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
        );
}

const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF1D1B1A);

const _themes = <String, BrandColors>{
  'default': BrandColors(
    brand: Color(0xFFD6001C),
    onBrand: _white,
    highlight: Color(0xFFFFC72C),
    onHighlight: _ink,
  ),
  'loyalty': BrandColors(
    brand: _ink,
    onBrand: _white,
    highlight: Color(0xFFC9A227),
    onHighlight: _ink,
  ),
  'christmas': BrandColors(
    brand: Color(0xFF0E6B3A),
    onBrand: _white,
    highlight: Color(0xFFD6001C),
    onHighlight: _white,
  ),
  'valentine': BrandColors(
    brand: Color(0xFFC2185B),
    onBrand: _white,
    highlight: Color(0xFFFFD6E4),
    onHighlight: Color(0xFF7A0F3A),
  ),
  'rush': BrandColors(
    brand: Color(0xFFC2410C),
    onBrand: _white,
    highlight: Color(0xFFFFE600),
    onHighlight: _ink,
  ),
};

/// A theme this client does not know falls back to `default`.
ThemeData themeOf(String theme) {
  final colors = _themes[theme] ?? _themes['default']!;
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: colors.brand, primary: colors.brand, onPrimary: colors.onBrand),
    scaffoldBackgroundColor: _white,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: colors.ink, displayColor: colors.ink),
  );
}
