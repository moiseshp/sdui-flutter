import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../app/theme.dart';

/* Props contract (v1) ------------------------------------------------------ */

class HeroSlide {
  const HeroSlide({required this.imageUrl, required this.alt, this.actions});

  factory HeroSlide.parse(JsonObject json) => HeroSlide(
        imageUrl: json.url('imageUrl'),
        alt: json.string('alt'),
        actions: json.triggersOrNull('actions'),
      );

  final String imageUrl;

  /// Describes the banner: the image usually carries the text.
  final String alt;
  final Triggers? actions;
}

class HeroCarouselProps {
  const HeroCarouselProps({required this.items, required this.layout, required this.autoplay});

  factory HeroCarouselProps.parse(JsonObject json) => HeroCarouselProps(
        items: json.list('items', HeroSlide.parse, min: 1),
        layout: json.semanticEnum('layout', const ['full', 'peek'], 'full'),
        autoplay: json.boolean('autoplay', fallback: true),
      );

  final List<HeroSlide> items;

  /// `full`: one banner per view. `peek`: the next banner shows at the edge.
  final String layout;
  final bool autoplay;
}

/* View --------------------------------------------------------------------- */

/// How long each banner stays, and its shape. Timing and proportions are
/// platform decisions, not the payload's.
const _autoplay = Duration(seconds: 5);
const _slide = Duration(milliseconds: 400);
const _aspectRatio = 4 / 5;

class HeroCarousel extends StatefulWidget {
  const HeroCarousel(this.props, {super.key});

  final HeroCarouselProps props;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final bool _isPeek = widget.props.layout == 'peek';
  late final _controller = PageController(viewportFraction: _isPeek ? 0.88 : 1);
  Timer? _timer;
  var _current = 0;

  int get _count => widget.props.items.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAutoplay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Restarts on every slide change, so a manual swipe also resets the timer.
  void _restartAutoplay() {
    _timer?.cancel();
    if (!widget.props.autoplay || _count < 2 || MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer(_autoplay, () => _goTo(_current + 1));
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(index % _count, duration: _slide, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    final items = widget.props.items;
    final hasMany = _count > 1;

    return Column(
      children: [
        if (_isPeek) const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxWidth * _controller.viewportFraction / _aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: _count,
                  onPageChanged: (index) {
                    setState(() => _current = index);
                    _restartAutoplay();
                  },
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: _isPeek ? 6 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_isPeek ? 16 : 0),
                      child: _SlideView(item: items[index]),
                    ),
                  ),
                ),
                if (hasMany && !_isPeek) ...[
                  Positioned(
                    left: 12,
                    child: _ArrowButton(
                      icon: LucideIcons.chevronLeft,
                      label: 'Banner anterior',
                      onPressed: () => _goTo(_current - 1 + _count),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: _ArrowButton(
                      icon: LucideIcons.chevronRight,
                      label: 'Banner siguiente',
                      onPressed: () => _goTo(_current + 1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasMany)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _count; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _current ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _current ? colors.brand : colors.ink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.item});

  final HeroSlide item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: PressTrigger.of(context, item.actions),
      child: ColoredBox(
        color: BrandColors.of(context).surface,
        child: Image.network(
          item.imageUrl,
          semanticLabel: item.alt,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.brand,
        elevation: 3,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(width: 32, height: 48, child: Icon(icon, size: 20, color: colors.onBrand)),
        ),
      ),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final heroCarousel = SectionDefinition(
  type: 'hero_carousel',
  version: 1,
  parse: HeroCarouselProps.parse,
  builder: HeroCarousel.new,
);
