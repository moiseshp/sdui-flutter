import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../app/theme.dart';
import 'shared/cta_button.dart';

/* Props contract (v1) ------------------------------------------------------ */

class PromoBannerProps {
  const PromoBannerProps({
    required this.title,
    this.description,
    required this.variant,
    this.imageUrl,
    this.badge,
    this.cta,
  });

  factory PromoBannerProps.parse(JsonObject json) {
    final cta = json.objectOrNull('cta');
    return PromoBannerProps(
      title: json.string('title'),
      description: json.stringOrNull('description'),
      variant: json.semanticEnum('variant', const ['brand', 'dark', 'highlight'], 'brand'),
      imageUrl: json.urlOrNull('imageUrl'),
      badge: json.stringOrNull('badge'),
      cta: cta == null ? null : Cta.parse(cta),
    );
  }

  final String title;
  final String? description;

  /// Semantic intent, never a hex color: each platform maps it to its tokens.
  final String variant;

  /// Decorative product image, shown on the right side.
  final String? imageUrl;

  /// Short tag above the title ("SOLO HOY").
  final String? badge;
  final Cta? cta;
}

/* View --------------------------------------------------------------------- */

class PromoBanner extends StatelessWidget {
  const PromoBanner(this.props, {super.key});

  final PromoBannerProps props;

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    final (background, foreground) = switch (props.variant) {
      'dark' => (colors.ink, Colors.white),
      'highlight' => (colors.highlight, colors.onHighlight),
      _ => (colors.brand, colors.onBrand),
    };
    final imageUrl = props.imageUrl;
    final badge = props.badge;
    final description = props.description;
    final cta = props.cta;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          if (imageUrl != null)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: 0.4,
                // Fades into the banner color on its left edge.
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    stops: [0, 0.5],
                  ).createShader(bounds),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: imageUrl == null ? 1 : 0.62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: foreground),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                    ),
                  Text(
                    props.title,
                    style: TextStyle(color: foreground, fontSize: 26, height: 1, fontWeight: FontWeight.w900),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(color: foreground, fontSize: 16, height: 1.6)),
                  ],
                  if (cta != null) ...[
                    const SizedBox(height: 16),
                    CtaButton(cta: cta, tone: props.variant == 'highlight' ? CtaTone.solid : CtaTone.inverse),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final promoBanner = SectionDefinition(
  type: 'promo_banner',
  version: 1,
  parse: PromoBannerProps.parse,
  builder: PromoBanner.new,
);
