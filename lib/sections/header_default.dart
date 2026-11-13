import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../app/theme.dart';
import 'shared/icons.dart';

/* Props contract (v1) ------------------------------------------------------ */
/* Shared with header_greeting, which adds a greeting under the same top bar.  */

const headerVariants = ['brand', 'dark'];

/// The logo comes in the payload: the backend can swap it per theme or campaign.
class HeaderLogo {
  const HeaderLogo({required this.imageUrl, required this.alt});

  factory HeaderLogo.parse(JsonObject json) => HeaderLogo(imageUrl: json.url('imageUrl'), alt: json.string('alt'));

  final String imageUrl;
  final String alt;
}

/// A button of the top bar. The backend decides which buttons appear, in which
/// order and what each one does; the client only maps `icon` to its icon set.
/// `label` is the accessible name, and what is shown if the icon is unknown.
class HeaderButton {
  const HeaderButton({required this.icon, required this.label, this.actions});

  factory HeaderButton.parse(JsonObject json) => HeaderButton(
        icon: json.string('icon'),
        label: json.string('label'),
        actions: json.triggersOrNull('actions'),
      );

  final String icon;
  final String label;
  final Triggers? actions;
}

class HeaderDefaultProps {
  const HeaderDefaultProps({required this.logo, required this.variant, required this.buttons});

  factory HeaderDefaultProps.parse(JsonObject json) => HeaderDefaultProps(
        logo: HeaderLogo.parse(json.object('logo')),
        variant: json.semanticEnum('variant', headerVariants, 'brand'),
        buttons: json.list('buttons', HeaderButton.parse),
      );

  final HeaderLogo logo;
  final String variant;
  final List<HeaderButton> buttons;
}

/* View --------------------------------------------------------------------- */

/// Semantic variant → this platform's colors (background, foreground).
(Color, Color) headerColors(BuildContext context, String variant) {
  final colors = BrandColors.of(context);
  return variant == 'dark' ? (colors.ink, Colors.white) : (colors.brand, colors.onBrand);
}

/// Logo and buttons. Being pinned is the `header` slot's job, not this section's.
class HeaderDefault extends StatelessWidget {
  const HeaderDefault(this.props, {super.key});

  final HeaderDefaultProps props;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = headerColors(context, props.variant);
    return HeaderSurface(
      background: background,
      child: HeaderBar(logo: props.logo, buttons: props.buttons, color: foreground),
    );
  }
}

/// The colored area of a header: it paints under the status bar and keeps its
/// content out of it.
class HeaderSurface extends StatelessWidget {
  const HeaderSurface({super.key, required this.background, required this.child, this.bottomPadding = 0});

  final Color background;
  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding), child: child),
      ),
    );
  }
}

/// Top bar shared by both headers.
class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.logo, required this.buttons, required this.color});

  final HeaderLogo logo;
  final List<HeaderButton> buttons;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _Logo(logo, color: color),
          const Spacer(),
          for (final button in buttons) _HeaderBarButton(button: button, color: color),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo(this.logo, {required this.color});

  final HeaderLogo logo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isSvg = Uri.parse(logo.imageUrl).path.toLowerCase().endsWith('.svg');
    // A logo that fails to load degrades to its text.
    Widget fallback() => Text(logo.alt, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900));

    return isSvg
        ? SvgPicture.network(
            logo.imageUrl,
            height: 36,
            semanticsLabel: logo.alt,
            errorBuilder: (context, error, stackTrace) => fallback(),
          )
        : Image.network(
            logo.imageUrl,
            height: 36,
            semanticLabel: logo.alt,
            errorBuilder: (context, error, stackTrace) => fallback(),
          );
  }
}

class _HeaderBarButton extends StatelessWidget {
  const _HeaderBarButton({required this.button, required this.color});

  final HeaderButton button;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onPressed = PressTrigger.of(context, button.actions);
    final icon = contractIcon(button.icon);

    // An icon this client does not know degrades to its label.
    if (icon == null) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: color, disabledForegroundColor: color),
        child: Text(button.label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return IconButton(
      onPressed: onPressed,
      tooltip: button.label,
      color: color,
      disabledColor: color,
      icon: Icon(icon, size: 24),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final headerDefault = SectionDefinition(
  type: 'header_default',
  version: 1,
  parse: HeaderDefaultProps.parse,
  builder: HeaderDefault.new,
);
