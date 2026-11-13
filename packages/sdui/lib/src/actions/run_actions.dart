/// Runs a list of declared actions, in order.
///
///  - Malformed action, invalid core payload or no handler → reported, skipped;
///    the rest of the list still runs.
///  - A handler that throws → reported and the list STOPS, because later
///    actions may depend on it (e.g. "save, then navigate").
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../contract/action.dart';
import '../contract/issues.dart';
import '../contract/json.dart';
import 'action_handlers.dart';

Future<void> runActions(
  BuildContext context,
  List<Object?> list,
  ActionHandlers handlers,
  IssueReporter report,
  ActionContext origin,
) async {
  for (final raw in list) {
    // The widget that fired the actions is gone (e.g. the screen was replaced).
    if (!context.mounted) return;

    final SduiAction action;
    try {
      action = SduiAction.parse(raw);
    } on InvalidJson {
      report(SduiIssue(
        code: IssueCode.invalidAction,
        message: 'Action without a valid "type"',
        sectionId: origin.sectionId,
      ));
      continue;
    }

    SduiIssue issue(IssueCode code, String message) =>
        SduiIssue(code: code, message: message, actionType: action.type, sectionId: origin.sectionId);

    final FutureOr<void> Function()? run;
    try {
      // Core payloads are strict: a bad one never reaches its handler.
      run = _bind(context, action, handlers, origin);
    } on InvalidJson catch (error) {
      report(issue(IssueCode.invalidAction, error.toString()));
      continue;
    }

    if (run == null) {
      report(issue(IssueCode.unhandledAction, 'No handler registered'));
      continue;
    }

    try {
      await run();
    } catch (error) {
      report(issue(IssueCode.actionFailed, '$error (remaining actions skipped)'));
      return;
    }
  }
}

/// Validates the payload and returns the call to make, or `null` if no handler knows the type.
FutureOr<void> Function()? _bind(
  BuildContext context,
  SduiAction action,
  ActionHandlers handlers,
  ActionContext origin,
) {
  final json = action.payload ?? JsonObject.empty;

  switch (action.type) {
    case 'NAVIGATE':
      final payload = NavigatePayload.parse(json);
      return () => handlers.navigate(context, payload, origin);
    case 'TRACK_EVENT':
      final payload = TrackEventPayload.parse(json);
      return () => handlers.trackEvent(context, payload, origin);
    case 'OPEN_URL':
      final payload = OpenUrlPayload.parse(json);
      return () => handlers.openUrl(context, payload, origin);
    case 'SHOW_MESSAGE':
      final payload = ShowMessagePayload.parse(json);
      return () => handlers.showMessage(context, payload, origin);
    default:
      final custom = handlers.custom[action.type];
      return custom == null ? null : () => custom(context, action.payload?.toMap(), origin);
  }
}
