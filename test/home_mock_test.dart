import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';
import 'package:sdui_flutter/sections/home_registry.dart';

/// The example screen must be fully renderable by the home registry: every
/// section resolves, with no issue.
void main() {
  test('assets/mocks/home.json resolves with the home registry', () {
    final result = parseScreen(jsonDecode(File('assets/mocks/home.json').readAsStringSync()));
    expect(result, isA<ScreenOk>());

    final screen = (result as ScreenOk).screen;
    final slots = [screen.header, ...screen.sections, screen.bottomBar].nonNulls;
    expect(slots, isNotEmpty);

    for (final raw in slots) {
      final resolution = resolveSection(raw, homeRegistry);
      expect(resolution, isA<SectionResolved>(),
          reason: resolution is SectionRejected ? resolution.issue.toString() : '');
    }
  });
}
