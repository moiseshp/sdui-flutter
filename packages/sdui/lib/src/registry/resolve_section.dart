/// Decides whether a raw section from the payload can be rendered.
///
/// Same checks, same order, on every platform:
///   1. envelope valid?          → otherwise `invalid_section`
///   2. type in the registry?    → otherwise `unknown_type`
///   3. version supported?       → otherwise `version_mismatch`
///   4. props match the parser?  → otherwise `invalid_props`
/// The platform then builds the view (and turns a crash into `render_error`).
library;

import 'package:flutter/widgets.dart';

import '../contract/issues.dart';
import '../contract/json.dart';
import '../contract/screen.dart';
import 'registry.dart';

sealed class SectionResolution {}

class SectionResolved extends SectionResolution {
  SectionResolved({required this.section, required this.view});
  final Section section;
  final WidgetBuilder view;
}

class SectionRejected extends SectionResolution {
  SectionRejected(this.issue);
  final SduiIssue issue;
}

SectionResolution resolveSection(Object? raw, SectionRegistry registry) {
  final Section section;
  try {
    section = Section.parse(raw);
  } on InvalidJson catch (error) {
    return SectionRejected(SduiIssue(code: IssueCode.invalidSection, message: error.toString()));
  }

  SectionRejected reject(IssueCode code, String message) => SectionRejected(
        SduiIssue(code: code, message: message, sectionId: section.id, sectionType: section.type),
      );

  final definition = registry[section.type];
  if (definition == null) return reject(IssueCode.unknownType, 'Type not in the client registry');

  // A newer props shape cannot be trusted with an older parser.
  if (section.version > definition.version) {
    return reject(
      IssueCode.versionMismatch,
      'Got v${section.version}, client supports up to v${definition.version}',
    );
  }

  try {
    final view = definition.bind(JsonObject.from(section.props ?? const <String, Object?>{}));
    return SectionResolved(section: section, view: view);
  } on InvalidJson catch (error) {
    return reject(IssueCode.invalidProps, error.toString());
  }
}
