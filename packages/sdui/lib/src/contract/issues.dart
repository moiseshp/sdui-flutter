/// Everything that did not go as the contract says. Nothing fails silently:
/// each case is reported with one of these codes, so monitoring (and the
/// backend team) can see when a payload was rejected by a client.
library;

import 'package:flutter/foundation.dart';

enum IssueCode {
  invalidScreen('invalid_screen'), //     envelope unusable → nothing to render
  invalidSection('invalid_section'), //   section without id/type
  unknownType('unknown_type'), //         type not in the client registry
  versionMismatch('version_mismatch'), // section newer than the client supports
  invalidProps('invalid_props'), //       props do not match the section parser
  renderError('render_error'), //         the section view crashed
  invalidAction('invalid_action'), //     malformed action or invalid core payload
  unhandledAction('unhandled_action'), // no handler for that action type
  actionFailed('action_failed'); //       handler threw → remaining actions skipped

  const IssueCode(this.code);

  /// The string shared with every platform and with monitoring.
  final String code;
}

class SduiIssue {
  const SduiIssue({required this.code, required this.message, this.sectionId, this.sectionType, this.actionType});

  final IssueCode code;
  final String message;
  final String? sectionId;
  final String? sectionType;
  final String? actionType;

  @override
  String toString() => [
        '[sdui] ${code.code}: $message',
        if (sectionType != null) 'sectionType=$sectionType',
        if (sectionId != null) 'sectionId=$sectionId',
        if (actionType != null) 'actionType=$actionType',
      ].join(' ');
}

typedef IssueReporter = void Function(SduiIssue issue);

/// Default reporter: the console. `SduiProvider` uses it unless the app passes
/// `onIssue`. To send issues to Sentry, Datadog..., pass your own `onIssue`.
void reportIssue(SduiIssue issue) => debugPrint(issue.toString());
