/// Screen and Section: what the backend SENDS, as seen by a client.
///
/// Validation is layered on purpose, so a problem stays as small as possible:
///   Screen  → only the envelope; a broken one means there is nothing to render.
///   Section → validated one by one (registry/resolve_section.dart); a broken one is skipped.
///   Props   → validated by each section's own parser (see lib/sections in the app).
///   Action  → validated one by one when it is dispatched (see action.dart).
library;

import 'action.dart';
import 'json.dart';

/// Major version of the envelope this client understands. Minor/patch bumps
/// are always compatible.
const supportedSchemaMajor = 1;

/// Screen-level visual intent. Each platform maps it to its own tokens.
const screenThemes = ['default', 'loyalty', 'christmas', 'valentine', 'rush'];

class Section {
  const Section({required this.id, required this.type, required this.version, this.props, this.actions});

  factory Section.parse(Object? raw) {
    final json = JsonObject.from(raw);
    final version = json.raw('version') ?? 1;
    if (version is! int || version < 1) throw const InvalidJson('version', 'expected a positive integer');
    return Section(
      id: json.string('id'),
      type: json.string('type'),
      version: version,
      props: json.raw('props'),
      actions: json.triggersOrNull('actions'),
    );
  }

  /// Stable id: widget key, analytics, debugging.
  final String id;

  /// Which widget renders it.
  final String type;

  /// Shape version of `props`. Bumps only on breaking changes.
  final int version;

  /// Validated later by the section's own parser.
  final Object? props;
  final Triggers? actions;
}

class Experiment {
  const Experiment({required this.id, required this.variant});

  final String id;
  final String variant;
}

/// Named slots (v1.1). The screen has three regions, each one rendered with
/// the same Section envelope and the same registry:
///
///   header     one section, pinned to the top
///   sections   the scrollable body, in order
///   bottomBar  one section, pinned to the bottom
///
/// The SLOT decides the behavior (pinned); the section only decides how it
/// looks. Both slots are optional: an absent one is simply not rendered.
class Screen {
  const Screen({
    required this.schemaVersion,
    required this.screenId,
    required this.theme,
    required this.sections,
    this.header,
    this.bottomBar,
    this.actions,
    this.title,
    this.experiment,
  });

  final String schemaVersion;
  final String screenId;
  final String theme;

  /// Kept untyped: validated like any other section, so a broken header only hides the header.
  final Object? header;

  /// Kept untyped: each section is validated on its own by the renderer.
  final List<Object?> sections;

  /// Kept untyped, same as [header].
  final Object? bottomBar;
  final Triggers? actions;
  final String? title;
  final Experiment? experiment;
}

sealed class ParseScreenResult {}

class ScreenOk extends ParseScreenResult {
  ScreenOk(this.screen);
  final Screen screen;
}

class ScreenInvalid extends ParseScreenResult {
  ScreenInvalid(this.message);
  final String message;
}

/// Never throws: the caller decides what to show when the envelope is unusable.
/// This is the one function a fetch needs from the library, whatever does the
/// fetching.
ParseScreenResult parseScreen(Object? input) {
  try {
    final json = JsonObject.from(input);

    final schemaVersion = json.string('schemaVersion');
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(schemaVersion)) {
      throw const InvalidJson('schemaVersion', 'expected a semver string');
    }
    if (int.parse(schemaVersion.split('.').first) > supportedSchemaMajor) {
      return ScreenInvalid('schemaVersion $schemaVersion is newer than $supportedSchemaMajor.x');
    }

    final sections = json.raw('sections');
    if (sections is! List) throw const InvalidJson('sections', 'expected a list');

    final meta = json.objectOrNull('meta');
    final experiment = meta?.objectOrNull('experiment');

    return ScreenOk(Screen(
      schemaVersion: schemaVersion,
      screenId: json.string('screenId'),
      theme: json.semanticEnum('theme', screenThemes, 'default'),
      header: json.raw('header'),
      sections: List.of(sections),
      bottomBar: json.raw('bottomBar'),
      actions: json.triggersOrNull('actions'),
      title: meta?.stringOrNull('title'),
      experiment:
          experiment == null ? null : Experiment(id: experiment.string('id'), variant: experiment.string('variant')),
    ));
  } on InvalidJson catch (error) {
    return ScreenInvalid(error.toString());
  }
}
