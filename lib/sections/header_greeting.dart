import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import 'header_default.dart';

/* Props contract (v1) ------------------------------------------------------ */

class HeaderGreetingProps {
  const HeaderGreetingProps({
    required this.title,
    this.subtitle,
    required this.logo,
    required this.variant,
    required this.buttons,
  });

  factory HeaderGreetingProps.parse(JsonObject json) => HeaderGreetingProps(
        title: json.string('title'),
        subtitle: json.stringOrNull('subtitle'),
        logo: HeaderLogo.parse(json.object('logo')),
        variant: json.semanticEnum('variant', headerVariants, 'brand'),
        buttons: json.list('buttons', HeaderButton.parse),
      );

  /// Already personalized by the backend ("¡Hola, Ana!"): the client never builds it.
  final String title;
  final String? subtitle;
  final HeaderLogo logo;
  final String variant;
  final List<HeaderButton> buttons;
}

/* View --------------------------------------------------------------------- */

class HeaderGreeting extends StatelessWidget {
  const HeaderGreeting(this.props, {super.key});

  final HeaderGreetingProps props;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = headerColors(context, props.variant);
    final subtitle = props.subtitle;

    return HeaderSurface(
      background: background,
      bottomPadding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderBar(logo: props.logo, buttons: props.buttons, color: foreground),
          const SizedBox(height: 8),
          Text(
            props.title,
            style: TextStyle(color: foreground, fontSize: 32, height: 1, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: foreground.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final headerGreeting = SectionDefinition(
  type: 'header_greeting',
  version: 1,
  parse: HeaderGreetingProps.parse,
  builder: HeaderGreeting.new,
);
