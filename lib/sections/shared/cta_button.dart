import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../../app/theme.dart';

enum CtaTone { solid, inverse, highlight, ink }

enum CtaSize { md, sm }

/// Shared CTA. Knows nothing about what its actions do: it only fires `onPress`.
class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.cta, this.tone = CtaTone.solid, this.size = CtaSize.md});

  final Cta cta;
  final CtaTone tone;
  final CtaSize size;

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    final (background, foreground) = switch (tone) {
      CtaTone.solid => (colors.brand, colors.onBrand),
      CtaTone.inverse => (Colors.white, colors.ink),
      CtaTone.highlight => (colors.highlight, colors.onHighlight),
      CtaTone.ink => (colors.ink, Colors.white),
    };
    final isSmall = size == CtaSize.sm;

    return FilledButton(
      // No actions → `null` → the button is disabled.
      onPressed: PressTrigger.of(context, cta.actions),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.6),
        disabledForegroundColor: foreground.withValues(alpha: 0.6),
        minimumSize: Size(0, isSmall ? 40 : 46),
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 22),
        shape: const StadiumBorder(),
        textStyle: TextStyle(fontSize: isSmall ? 14 : 15, fontWeight: FontWeight.bold),
      ),
      child: Text(cta.label),
    );
  }
}

/// Text-only CTA, for secondary links like "Ver todo".
class CtaLink extends StatelessWidget {
  const CtaLink({super.key, required this.cta});

  final Cta cta;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: PressTrigger.of(context, cta.actions),
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.of(context).brand,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      iconAlignment: IconAlignment.end,
      icon: const Icon(LucideIcons.arrowRight, size: 16),
      label: Text(cta.label),
    );
  }
}
