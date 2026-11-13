/// The SDUI engine: the same in any app and, with the same names, on web.
///
///   contract/  what arrives from the backend
///   registry/  what the client can render
///   actions/   what happens on interaction
///   screen/    how it is rendered
///
/// It knows nothing about the app or the brand: no routes, URLs, analytics,
/// backend or colors.
library;

export 'src/actions/action_handlers.dart';
export 'src/actions/run_actions.dart';
export 'src/actions/sdui_provider.dart';
export 'src/actions/triggers.dart';
export 'src/contract/action.dart';
export 'src/contract/issues.dart';
export 'src/contract/json.dart';
export 'src/contract/screen.dart';
export 'src/registry/registry.dart';
export 'src/registry/resolve_section.dart';
export 'src/screen/screen_renderer.dart';
export 'src/screen/section_slot.dart';
