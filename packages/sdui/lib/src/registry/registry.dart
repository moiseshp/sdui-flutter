/// Section registry: `type` → { version, props parser, widget builder }.
library;

import 'package:flutter/widgets.dart';

import '../contract/json.dart';

/// Binds a widget to its props contract: the compiler fails if `parse` and
/// `builder` disagree on [P].
class SectionDefinition<P> {
  const SectionDefinition({required this.type, required this.version, required this.parse, required this.builder});

  /// Must match `section.type` in the contract.
  final String type;

  /// Highest props version this client can render.
  final int version;

  /// Contract of the props. Runs before the widget is ever built; throws
  /// [InvalidJson] when the props do not match.
  final P Function(JsonObject props) parse;

  final Widget Function(P props) builder;

  /// Validates [props] and returns the view, ready to build.
  WidgetBuilder bind(JsonObject props) {
    final parsed = parse(props);
    return (_) => builder(parsed);
  }
}

typedef SectionRegistry = Map<String, SectionDefinition<Object?>>;

/// One registry per screen (home, plp, checkout...): each screen lists the
/// sections it renders, picked from the shared catalog. A section the screen
/// does not list is skipped and reported as `unknown_type`.
SectionRegistry createSectionRegistry(List<SectionDefinition<Object?>> definitions) =>
    Map.unmodifiable({for (final definition in definitions) definition.type: definition});
