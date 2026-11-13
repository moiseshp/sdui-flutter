/// The three triggers of the contract.
///
///   onPress  any pressable element          → [PressTrigger]
///   onView   the first time a section is at least 50% visible → [ViewTrigger]
///   onMount  once per loaded screen         → [MountTrigger]
library;

import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../contract/action.dart';
import 'sdui_provider.dart';

/// The one pattern for anything pressable inside a section:
///
///   onPressed: PressTrigger.of(context, item.actions),
///
/// `null` when there is nothing to run, which is how Flutter disables a button.
abstract final class PressTrigger {
  static VoidCallback? of(BuildContext context, Triggers? triggers) {
    final actions = triggers?['onPress'];
    if (actions == null || actions.isEmpty) return null;
    return () => dispatch(context, actions);
  }
}

class ViewTrigger extends StatefulWidget {
  const ViewTrigger({super.key, required this.actions, required this.child});

  final List<Object?>? actions;
  final Widget child;

  @override
  State<ViewTrigger> createState() => _ViewTriggerState();
}

class _ViewTriggerState extends State<ViewTrigger> {
  final _key = UniqueKey();
  var _fired = false;

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    if (_fired || actions == null || actions.isEmpty) return widget.child;

    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (info) {
        if (_fired || !mounted || info.visibleFraction < 0.5) return;
        setState(() => _fired = true);
        dispatch(context, actions);
      },
      child: widget.child,
    );
  }
}

/// Fires once per mounted instance. The renderer keys it by screen id, so a
/// different screen fires again.
class MountTrigger extends StatefulWidget {
  const MountTrigger({super.key, required this.actions, required this.child});

  final List<Object?>? actions;
  final Widget child;

  @override
  State<MountTrigger> createState() => _MountTriggerState();
}

class _MountTriggerState extends State<MountTrigger> {
  @override
  void initState() {
    super.initState();
    final actions = widget.actions;
    if (actions == null || actions.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) dispatch(context, actions);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
