/// Gets a screen from the backend. Not part of SDUI: it is a service like any
/// other, and this demo's backend happens to be Supabase. The only SDUI step
/// is `parseScreen`.
library;

import 'package:sdui/sdui.dart';
import 'package:supabase/supabase.dart';

Future<Screen> getScreen(String screenId) async {
  final payload = await _fromSupabase(screenId);

  // Development without a backend: use the mock instead of the line above
  // (and uncomment `_fromMock` and its imports at the end of this file).
  // Never commit it.
  // final payload = await _fromMock();

  return switch (parseScreen(payload)) {
    ScreenOk(:final screen) => screen,
    ScreenInvalid(:final message) => throw FormatException('invalid_screen: $message'),
  };
}

/// The `sdui_screens` view has one row per screen: `screen_id` and `payload` (the Screen JSON).
Future<Object?> _fromSupabase(String screenId) async {
  final row = await _supabase().from('sdui_screens').select('payload').eq('screen_id', screenId).single();
  return row['payload'];
}

SupabaseClient? _client;

/// Created on first use, so the mock works without any Supabase variable.
/// The values come from `.env` (see .env.example), passed with
/// `--dart-define-from-file=.env`.
SupabaseClient _supabase() => _client ??= SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL'),
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    );

// import 'dart:convert';
// import 'package:flutter/services.dart';
//
// Future<Object?> _fromMock() async {
//   return jsonDecode(await rootBundle.loadString('assets/mocks/home.json'));
// }
