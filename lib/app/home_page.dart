import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

import '../sections/home_registry.dart';
import 'action_handlers.dart';
import 'get_screen.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Created once: a FutureBuilder must not get a new future on every build.
  late final Future<Screen> _screen = getScreen('home');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _screen,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[screen] ${snapshot.error}');
          return const _Message('No pudimos cargar el inicio. Inténtalo de nuevo en unos segundos.');
        }
        final screen = snapshot.data;
        if (screen == null) return const _Message('Cargando…');

        return SduiProvider(
          handlers: const AppActionHandlers(),
          child: Theme(
            data: themeOf(screen.theme),
            child: ScreenRenderer(screen: screen, registry: homeRegistry),
          ),
        );
      },
    );
  }
}

/// Plain text on purpose: each app brings its own loading and error states.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Text(text))));
  }
}
