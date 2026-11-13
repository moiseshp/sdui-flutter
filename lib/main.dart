import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app/home_page.dart';
import 'app/product_page.dart';
import 'app/theme.dart';

void main() => runApp(const App());

/// The paths of this app. The contract never sees them: it speaks in route
/// ids, translated in app/action_handlers.dart.
final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/product/:id', builder: (context, state) => ProductPage(id: state.pathParameters['id']!)),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SDUI Starter · Flutter',
      debugShowCheckedModeBanner: false,
      theme: themeOf('default'),
      routerConfig: _router,
    );
  }
}
