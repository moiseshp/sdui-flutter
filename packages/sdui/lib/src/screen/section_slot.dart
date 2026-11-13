/// One section of the screen. Asks the registry whether it can be rendered
/// (`resolveSection`), then builds it. Any failure stays inside this slot and
/// is reported; the rest of the screen is unaffected.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../actions/action_handlers.dart';
import '../actions/sdui_provider.dart';
import '../actions/triggers.dart';
import '../contract/issues.dart';
import '../registry/registry.dart';
import '../registry/resolve_section.dart';

class SectionSlot extends StatefulWidget {
  const SectionSlot({super.key, required this.raw, required this.registry});

  final Object? raw;
  final SectionRegistry registry;

  @override
  State<SectionSlot> createState() => _SectionSlotState();
}

class _SectionSlotState extends State<SectionSlot> {
  late SectionResolution _resolution;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(SectionSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.raw, widget.raw) || !identical(oldWidget.registry, widget.registry)) _resolve();
  }

  /// Resolved (and reported) once per payload, not on every build.
  void _resolve() {
    final resolution = _resolution = resolveSection(widget.raw, widget.registry);
    if (resolution is SectionRejected) SduiProvider.of(context).report(resolution.issue);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_resolution) {
      SectionRejected(:final issue) => _SectionFallback(issue: issue),
      SectionResolved(:final section, :final view) => ActionScope(
          value: ActionContext(sectionId: section.id),
          child: ViewTrigger(
            actions: section.actions?['onView'],
            child: Builder(
              builder: (context) {
                // Flutter has no error boundary: this catches a section whose
                // builder throws. An error deeper in its tree goes to
                // `ErrorWidget.builder` / `FlutterError.onError`, like any widget.
                try {
                  return view(context);
                } catch (error) {
                  final issue = SduiIssue(
                    code: IssueCode.renderError,
                    message: '$error',
                    sectionId: section.id,
                    sectionType: section.type,
                  );
                  SduiProvider.of(context).report(issue);
                  return _SectionFallback(issue: issue);
                }
              },
            ),
          ),
        ),
    };
  }
}

/// Debug: the failure is visible, so whoever writes the payload sees it.
/// Release: the section simply does not appear (the issue is still reported).
class _SectionFallback extends StatelessWidget {
  const _SectionFallback({required this.issue});

  final SduiIssue issue;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    const ink = Color(0xFF78350F);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: ink, fontSize: 13, height: 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sección no renderizada · ${issue.code.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${issue.sectionType ?? 'sin tipo'} / ${issue.sectionId ?? 'sin id'}'),
            Text(issue.message, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
