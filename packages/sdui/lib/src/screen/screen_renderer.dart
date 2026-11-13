/// Renders a parsed Screen: fires `onMount`, lays out the three slots (header,
/// sections, bottomBar) and hands each raw section to a SectionSlot. It knows
/// nothing about specific sections.
///
/// The theme is the app's job: it wraps the renderer in a `Theme` built from
/// `screen.theme`, and sections never read which theme is on.
library;

import 'package:material_ui/material_ui.dart';

import '../actions/action_handlers.dart';
import '../actions/sdui_provider.dart';
import '../actions/triggers.dart';
import '../contract/screen.dart';
import '../registry/registry.dart';
import 'section_slot.dart';

class ScreenRenderer extends StatelessWidget {
  const ScreenRenderer({super.key, required this.screen, required this.registry});

  final Screen screen;
  final SectionRegistry registry;

  @override
  Widget build(BuildContext context) {
    final header = screen.header;
    final bottomBar = screen.bottomBar;

    return ActionScope(
      value: ActionContext(screenId: screen.screenId, experiment: screen.experiment),
      child: MountTrigger(
        key: ValueKey(screen.screenId),
        actions: screen.actions?['onMount'],
        child: Scaffold(
          // The body scrolls behind the bottom bar, which floats over it.
          extendBody: true,
          body: Column(
            children: [
              // Pinned to the top: it sits outside the scrollable body.
              if (header != null) SectionSlot(raw: header, registry: registry),
              Expanded(
                child: Builder(
                  builder: (context) => ListView.builder(
                    padding: EdgeInsets.only(
                      top: header == null ? MediaQuery.paddingOf(context).top : 0,
                      bottom: 32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: screen.sections.length,
                    itemBuilder: (context, index) {
                      final raw = screen.sections[index];
                      return SectionSlot(key: ValueKey(_keyOf(raw, index)), raw: raw, registry: registry);
                    },
                  ),
                ),
              ),
            ],
          ),
          // Pinned to the bottom.
          bottomNavigationBar: bottomBar == null ? null : SectionSlot(raw: bottomBar, registry: registry),
        ),
      ),
    );
  }
}

String _keyOf(Object? raw, int index) {
  final id = raw is Map ? raw['id'] : null;
  return id is String ? id : '__invalid_$index';
}
