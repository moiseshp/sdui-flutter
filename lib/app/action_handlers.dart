/// How THIS app runs each action of the contract. It extends the library's
/// `ActionHandlers`: leave a core action out and it does not compile.
library;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The contract speaks in route ids ("product_detail"); this table is the
/// Flutter translation. The web keeps its own table with the same ids.
/// Returns `null` for missing params.
final _routes = <String, String? Function(Map<String, String> params)>{
  'home': (_) => '/',
  'product_detail': (params) {
    final id = params['id'];
    return id == null ? null : '/product/${Uri.encodeComponent(id)}';
  },
};

class AppActionHandlers extends ActionHandlers {
  const AppActionHandlers();

  @override
  void navigate(BuildContext context, NavigatePayload payload, ActionContext origin) {
    final path = _routes[payload.route]?.call(payload.params);
    // Throwing stops the rest of the chain and reports `action_failed`.
    if (path == null) throw StateError('Unknown route "${payload.route}" on Flutter');
    context.push(path);
  }

  @override
  void trackEvent(BuildContext context, TrackEventPayload payload, ActionContext origin) {
    // Replace the console with your analytics SDK. Every event carries the
    // experiment variant: that is what makes an A/B measurable.
    debugPrint('[analytics] ${payload.name} ${{
      ...payload.params,
      'screen_id': origin.screenId,
      'section_id': origin.sectionId,
      'experiment_id': origin.experiment?.id,
      'variant': origin.experiment?.variant,
    }}');
  }

  @override
  Future<void> openUrl(BuildContext context, OpenUrlPayload payload, ActionContext origin) async {
    final opened = await launchUrl(payload.url, mode: LaunchMode.externalApplication);
    if (!opened) throw StateError('Could not open ${payload.url}');
  }

  /// The payload brings the text; this platform decides it is a dialog.
  @override
  Future<void> showMessage(BuildContext context, ShowMessagePayload payload, ActionContext origin) {
    final title = payload.title;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(payload.message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
      ),
    );
  }
}
