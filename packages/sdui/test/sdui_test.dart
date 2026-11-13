import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sdui/sdui.dart';

/// A section with one required prop, enough to exercise the registry.
final _title = SectionDefinition<String>(
  type: 'title',
  version: 1,
  parse: (json) => json.string('text'),
  builder: (text) => Text(text),
);

final _registry = createSectionRegistry([_title]);

class _Handlers extends ActionHandlers {
  final calls = <String>[];

  @override
  void navigate(BuildContext context, NavigatePayload payload, ActionContext origin) {
    if (payload.route == 'missing') throw StateError('Unknown route');
    calls.add('NAVIGATE ${payload.route} from ${origin.sectionId}');
  }

  @override
  void trackEvent(BuildContext context, TrackEventPayload payload, ActionContext origin) =>
      calls.add('TRACK_EVENT ${payload.name}');

  @override
  void openUrl(BuildContext context, OpenUrlPayload payload, ActionContext origin) => calls.add('OPEN_URL ${payload.url}');

  @override
  void showMessage(BuildContext context, ShowMessagePayload payload, ActionContext origin) =>
      calls.add('SHOW_MESSAGE ${payload.message}');
}

void main() {
  group('parseScreen', () {
    test('accepts a 1.x envelope and degrades an unknown theme', () {
      final result = parseScreen({'schemaVersion': '1.4.0', 'screenId': 'home', 'theme': 'halloween', 'sections': []});
      expect(result, isA<ScreenOk>());
      expect((result as ScreenOk).screen.theme, 'default');
    });

    test('rejects a newer major and a broken envelope', () {
      expect(parseScreen({'schemaVersion': '2.0.0', 'screenId': 'home', 'sections': []}), isA<ScreenInvalid>());
      expect(parseScreen({'schemaVersion': '1.0.0', 'sections': []}), isA<ScreenInvalid>());
      expect(parseScreen('not a screen'), isA<ScreenInvalid>());
    });
  });

  group('resolveSection', () {
    IssueCode? codeOf(Object? raw) => switch (resolveSection(raw, _registry)) {
          SectionRejected(:final issue) => issue.code,
          SectionResolved() => null,
        };

    test('resolves a valid section', () {
      expect(codeOf({'id': 'a', 'type': 'title', 'props': {'text': 'Hola'}}), isNull);
    });

    test('reports each reason a section cannot be rendered', () {
      expect(codeOf({'type': 'title'}), IssueCode.invalidSection);
      expect(codeOf({'id': 'a', 'type': 'countdown_timer'}), IssueCode.unknownType);
      expect(codeOf({'id': 'a', 'type': 'title', 'version': 2, 'props': {'text': 'Hola'}}), IssueCode.versionMismatch);
      expect(codeOf({'id': 'a', 'type': 'title', 'props': {}}), IssueCode.invalidProps);
    });
  });

  group('runActions', () {
    late _Handlers handlers;
    late List<IssueCode> issues;

    Future<void> run(WidgetTester tester, List<Object?> actions) async {
      handlers = _Handlers();
      issues = [];
      await tester.pumpWidget(const SizedBox());
      await runActions(
        tester.element(find.byType(SizedBox)),
        actions,
        handlers,
        (issue) => issues.add(issue.code),
        const ActionContext(sectionId: 'hero'),
      );
    }

    testWidgets('runs the list in order, with its origin', (tester) async {
      await run(tester, [
        {'type': 'TRACK_EVENT', 'payload': {'name': 'click'}},
        {'type': 'NAVIGATE', 'payload': {'route': 'home'}},
        {'type': 'SHOW_MESSAGE', 'payload': {'message': 'Hola'}},
      ]);
      expect(handlers.calls, ['TRACK_EVENT click', 'NAVIGATE home from hero', 'SHOW_MESSAGE Hola']);
      expect(issues, isEmpty);
    });

    testWidgets('skips a bad action and keeps going', (tester) async {
      await run(tester, [
        {'payload': {}},
        {'type': 'OPEN_URL', 'payload': {'url': 'javascript:alert(1)'}},
        {'type': 'SHARE'},
        {'type': 'TRACK_EVENT', 'payload': {'name': 'still_sent'}},
      ]);
      expect(issues, [IssueCode.invalidAction, IssueCode.invalidAction, IssueCode.unhandledAction]);
      expect(handlers.calls, ['TRACK_EVENT still_sent']);
    });

    testWidgets('stops the list when a handler throws', (tester) async {
      await run(tester, [
        {'type': 'NAVIGATE', 'payload': {'route': 'missing'}},
        {'type': 'TRACK_EVENT', 'payload': {'name': 'never_sent'}},
      ]);
      expect(issues, [IssueCode.actionFailed]);
      expect(handlers.calls, isEmpty);
    });
  });

  testWidgets('ScreenRenderer paints valid sections and reports the rest', (tester) async {
    final issues = <IssueCode>[];
    final screen = (parseScreen({
      'schemaVersion': '1.1.0',
      'screenId': 'home',
      'sections': [
        {'id': 'a', 'type': 'title', 'props': {'text': 'Primera'}},
        {'id': 'b', 'type': 'countdown_timer'},
        {'id': 'c', 'type': 'title', 'props': {'text': 'Última'}},
      ],
    }) as ScreenOk)
        .screen;

    await tester.pumpWidget(MaterialApp(
      home: SduiProvider(
        handlers: _Handlers(),
        onIssue: (issue) => issues.add(issue.code),
        child: ScreenRenderer(screen: screen, registry: _registry),
      ),
    ));

    expect(find.text('Primera'), findsOneWidget);
    expect(find.text('Última'), findsOneWidget);
    expect(issues, [IssueCode.unknownType]);
  });
}
