import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../app/theme.dart';
import 'shared/cta_button.dart';

/* Props contract (v1) ------------------------------------------------------ */

class Product {
  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.priceLabel,
    this.originalPriceLabel,
    this.badge,
    this.imageUrl,
    this.actions,
  });

  factory Product.parse(JsonObject json) => Product(
        id: json.string('id'),
        name: json.string('name'),
        description: json.stringOrNull('description'),
        priceLabel: json.string('priceLabel'),
        originalPriceLabel: json.stringOrNull('originalPriceLabel'),
        badge: json.stringOrNull('badge'),
        imageUrl: json.urlOrNull('imageUrl'),
        actions: json.triggersOrNull('actions'),
      );

  final String id;
  final String name;
  final String? description;

  /// Already formatted by the backend ("S/ 54.90"): the client never formats money.
  final String priceLabel;
  final String? originalPriceLabel;
  final String? badge;
  final String? imageUrl;
  final Triggers? actions;
}

class ProductListProps {
  const ProductListProps({required this.title, required this.layout, required this.items, this.cta});

  factory ProductListProps.parse(JsonObject json) {
    final cta = json.objectOrNull('cta');
    return ProductListProps(
      title: json.string('title'),
      layout: json.semanticEnum('layout', const ['grid', 'carousel'], 'grid'),
      items: json.list('items', Product.parse, min: 1),
      cta: cta == null ? null : Cta.parse(cta),
    );
  }

  final String title;
  final String layout;
  final List<Product> items;

  /// Secondary link next to the title ("Ver todo").
  final Cta? cta;
}

/* View --------------------------------------------------------------------- */

const _gutter = 16.0;
const _gap = 12.0;

class ProductList extends StatelessWidget {
  const ProductList(this.props, {super.key});

  final ProductListProps props;

  @override
  Widget build(BuildContext context) {
    final cta = props.cta;

    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    props.title,
                    style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800),
                  ),
                ),
                if (cta != null) ...[const SizedBox(width: 12), CtaLink(cta: cta)],
              ],
            ),
          ),
          if (props.layout == 'carousel') _Carousel(items: props.items) else _Grid(items: props.items),
        ],
      ),
    );
  }
}

/// Horizontal strip: a bit more than two cards per view, so the next one peeks.
class _Carousel extends StatelessWidget {
  const _Carousel({required this.items});

  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width * 0.46;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _gap,
        children: [for (final item in items) SizedBox(width: cardWidth, child: _ProductCard(item: item))],
      ),
    );
  }
}

/// Two columns. Rows are built by hand because cards have different heights.
class _Grid extends StatelessWidget {
  const _Grid({required this.items});

  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _gutter),
      child: Column(
        spacing: 18,
        children: [
          for (var index = 0; index < items.length; index += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: _gap,
              children: [
                Expanded(child: _ProductCard(item: items[index])),
                Expanded(child: index + 1 < items.length ? _ProductCard(item: items[index + 1]) : const SizedBox()),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final Product item;

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    final imageUrl = item.imageUrl;
    final badge = item.badge;
    final description = item.description;
    final originalPriceLabel = item.originalPriceLabel;

    return GestureDetector(
      // Each item carries its own actions: the backend decides what a tap does.
      onTap: PressTrigger.of(context, item.actions),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: colors.surface),
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
                      ),
                      if (badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colors.highlight, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              badge,
                              style: TextStyle(color: colors.onHighlight, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Text(item.name, style: const TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600)),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 13, height: 1.35),
            ),
          ],
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: item.priceLabel,
              style: TextStyle(color: colors.brand, fontSize: 16, fontWeight: FontWeight.w800),
              children: [
                if (originalPriceLabel != null)
                  TextSpan(
                    text: '  $originalPriceLabel',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* Registration ------------------------------------------------------------- */

final productList = SectionDefinition(
  type: 'product_list',
  version: 1,
  parse: ProductListProps.parse,
  builder: ProductList.new,
);
