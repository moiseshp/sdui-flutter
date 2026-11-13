import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Destination of NAVIGATE → product_detail. Not server-driven.
class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final colors = BrandColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(foregroundColor: colors.brand, padding: EdgeInsets.zero),
                child: const Text('Volver al inicio', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Text(id, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 8),
              Text(
                'Llegaste con { route: "product_detail", params: { id } }. Flutter lo tradujo a /product/$id; '
                'la web lo traduce a su propia ruta.',
                style: TextStyle(color: colors.muted, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
