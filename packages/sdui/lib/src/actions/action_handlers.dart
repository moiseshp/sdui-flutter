/// What every platform MUST implement to run a screen.
///
/// The four core handlers are abstract: if an app forgets one, it does not
/// compile. App-specific actions go in [custom], so the shared surface stays
/// small and explicit.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../contract/action.dart';
import '../contract/screen.dart';

/// Where an action was fired from. Handlers use it, e.g. to tag analytics.
class ActionContext {
  const ActionContext({this.screenId, this.sectionId, this.experiment});

  final String? screenId;
  final String? sectionId;
  final Experiment? experiment;

  /// [inner] wins: a section's scope adds to (never loses) its screen's.
  ActionContext merge(ActionContext inner) => ActionContext(
        screenId: inner.screenId ?? screenId,
        sectionId: inner.sectionId ?? sectionId,
        experiment: inner.experiment ?? experiment,
      );
}

/// A handler for an action outside the core set.
typedef CustomActionHandler = FutureOr<void> Function(
  BuildContext context,
  Map<String, Object?>? payload,
  ActionContext origin,
);

/// `context` is the widget that fired the action: handlers use it to navigate
/// or to show a dialog. `origin` says which screen and section it came from.
abstract class ActionHandlers {
  const ActionHandlers();

  FutureOr<void> navigate(BuildContext context, NavigatePayload payload, ActionContext origin);
  FutureOr<void> trackEvent(BuildContext context, TrackEventPayload payload, ActionContext origin);
  FutureOr<void> openUrl(BuildContext context, OpenUrlPayload payload, ActionContext origin);
  FutureOr<void> showMessage(BuildContext context, ShowMessagePayload payload, ActionContext origin);

  Map<String, CustomActionHandler> get custom => const {};
}
