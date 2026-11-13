/// Actions and triggers: what the payload says should HAPPEN.
///
///   trigger  a named moment (onMount, onView, onPress)
///   action   `{ type, payload? }`, run in order when its trigger fires
///
/// Actions are validated one by one when they are dispatched (see
/// actions/run_actions.dart), never together with the screen: one bad action
/// must not hide the section that holds it.
library;

import 'json.dart';

/// Triggers: named moments bound to a list of actions.
///   onMount (screen) · onView (section) · onPress (any pressable element)
typedef Triggers = Map<String, List<Object?>>;

/// Minimum shape of any action. Unknown types are valid here; the runtime
/// decides what to do with them.
class SduiAction {
  const SduiAction({required this.type, this.payload});

  factory SduiAction.parse(Object? raw) {
    final json = JsonObject.from(raw);
    return SduiAction(type: json.string('type'), payload: json.objectOrNull('payload'));
  }

  final String type;
  final JsonObject? payload;
}

/* Core actions --------------------------------------------------------------
 * Every platform must implement these. Their payloads are strictly validated:
 * a core action with a bad payload never reaches its handler.
 * -------------------------------------------------------------------------- */

/// NAVIGATE uses a platform-agnostic `route` id, never a path: web and Flutter
/// each resolve it to their own navigation.
class NavigatePayload {
  const NavigatePayload({required this.route, this.params = const {}});

  factory NavigatePayload.parse(JsonObject json) {
    final params = json.objectOrNull('params')?.toMap() ?? const {};
    if (params.values.any((value) => value is! String)) {
      throw const InvalidJson('params', 'expected string values');
    }
    return NavigatePayload(route: json.string('route'), params: params.cast<String, String>());
  }

  final String route;
  final Map<String, String> params;
}

class TrackEventPayload {
  const TrackEventPayload({required this.name, this.params = const {}});

  factory TrackEventPayload.parse(JsonObject json) =>
      TrackEventPayload(name: json.string('name'), params: json.objectOrNull('params')?.toMap() ?? const {});

  final String name;
  final Map<String, Object?> params;
}

class OpenUrlPayload {
  const OpenUrlPayload({required this.url});

  /// Only http(s): blocks `javascript:` and friends coming from a payload.
  factory OpenUrlPayload.parse(JsonObject json) => OpenUrlPayload(url: Uri.parse(json.url('url')));

  final Uri url;
}

/// Plain text shown by the platform's own dialog. The payload never says which widget.
class ShowMessagePayload {
  const ShowMessagePayload({this.title, required this.message});

  factory ShowMessagePayload.parse(JsonObject json) =>
      ShowMessagePayload(title: json.stringOrNull('title'), message: json.string('message'));

  final String? title;
  final String message;
}

/// Reusable call-to-action shape, shared by many sections.
class Cta {
  const Cta({required this.label, this.actions});

  factory Cta.parse(JsonObject json) => Cta(label: json.string('label'), actions: json.triggersOrNull('actions'));

  final String label;
  final Triggers? actions;
}
