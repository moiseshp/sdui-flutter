/// Makes the platform's action handlers and issue reporter available to every
/// section, and keeps track of WHERE an action is fired from (screen, section).
library;

import 'package:flutter/widgets.dart';

import '../contract/issues.dart';
import 'action_handlers.dart';
import 'run_actions.dart';

class SduiProvider extends InheritedWidget {
  const SduiProvider({super.key, required this.handlers, this.onIssue, required super.child});

  final ActionHandlers handlers;

  /// Called for every issue. Default: [reportIssue] (the console). Plug Sentry, Datadog... here.
  final IssueReporter? onIssue;

  IssueReporter get report => onIssue ?? reportIssue;

  static SduiProvider of(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<SduiProvider>();
    if (provider == null) throw FlutterError('SDUI widgets must be built inside a SduiProvider.');
    return provider;
  }

  @override
  bool updateShouldNotify(SduiProvider oldWidget) => handlers != oldWidget.handlers || onIssue != oldWidget.onIssue;
}

/// Adds screen/section info to every action fired inside it. Used by the renderer.
class ActionScope extends StatelessWidget {
  const ActionScope({super.key, required this.value, required this.child});

  final ActionContext value;
  final Widget child;

  static ActionContext of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ActionScope>()?.value ?? const ActionContext();

  @override
  Widget build(BuildContext context) => _ActionScope(value: of(context).merge(value), child: child);
}

class _ActionScope extends InheritedWidget {
  const _ActionScope({required this.value, required super.child});

  final ActionContext value;

  @override
  bool updateShouldNotify(_ActionScope oldWidget) => false;
}

/// Runs [actions] with the handlers and the scope found at [context]. Triggers use it.
Future<void> dispatch(BuildContext context, List<Object?>? actions) {
  final provider = SduiProvider.of(context);
  return runActions(context, actions ?? const [], provider.handlers, provider.report, ActionScope.of(context));
}
