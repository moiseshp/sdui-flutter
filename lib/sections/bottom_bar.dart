import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../app/theme.dart';
import 'shared/cta_button.dart';
import 'shared/icons.dart';

/* Props contract (v1) ------------------------------------------------------ */

class BottomBarProps {
  const BottomBarProps({
    required this.title,
    this.message,
    this.cta,
    required this.variant,
    this.icon,
    required this.isDismissible,
  });

  factory BottomBarProps.parse(JsonObject json) {
    final cta = json.objectOrNull('cta');
    return BottomBarProps(
      title: json.string('title'),
      message: json.stringOrNull('message'),
      cta: cta == null ? null : Cta.parse(cta),
      variant: json.semanticEnum('variant', const ['brand', 'dark', 'warning'], 'brand'),
      icon: json.stringOrNull('icon'),
      isDismissible: json.boolean('isDismissible', fallback: true),
    );
  }

  /// Plain text. May arrive personalized by the backend.
  final String title;
  final String? message;
  final Cta? cta;

  /// `brand` follows the screen theme; `warning` is for operational notices.
  final String variant;

  /// Semantic name (`gift`, `map_pin`, `warning`, `bell`). An unknown one is not drawn.
  final String? icon;
  final bool isDismissible;
}

/* View --------------------------------------------------------------------- */

/// Meant for the `bottomBar` slot, which pins it. The client does not know
/// which initiative it shows (sign up, address, incident): the backend picks it.
/// Dismissing it is local state: it comes back on the next load.
class BottomBar extends StatefulWidget {
  const BottomBar(this.props, {super.key});

  final BottomBarProps props;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  var _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final props = widget.props;
    final colors = BrandColors.of(context);
    final (background, foreground, ctaTone, border) = switch (props.variant) {
      'dark' => (colors.ink, Colors.white, CtaTone.highlight, null),
      'warning' => (const Color(0xFFFEF3C7), const Color(0xFF451A03), CtaTone.ink, const Color(0xFFFBBF24)),
      _ => (colors.brand, colors.onBrand, CtaTone.inverse, null),
    };
    // Unknown icon name → no icon.
    final icon = contractIcon(props.icon);
    final message = props.message;
    final cta = props.cta;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.all(12),
      child: Material(
        color: background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            spacing: 12,
            children: [
              if (icon != null) Icon(icon, size: 28, color: foreground),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      props.title,
                      style: TextStyle(color: foreground, fontSize: 14, height: 1.25, fontWeight: FontWeight.bold),
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          message,
                          style: TextStyle(color: foreground.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
                        ),
                      ),
                  ],
                ),
              ),
              if (cta != null) CtaButton(cta: cta, tone: ctaTone, size: CtaSize.sm),
              if (props.isDismissible)
                IconButton(
                  onPressed: () => setState(() => _isVisible = false),
                  tooltip: 'Cerrar',
                  color: foreground,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final bottomBar = SectionDefinition(
  type: 'bottom_bar',
  version: 1,
  parse: BottomBarProps.parse,
  builder: BottomBar.new,
);
