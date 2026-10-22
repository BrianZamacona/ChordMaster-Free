// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_store.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build the app and ensure it renders. Override storage with a fake.
    await tester.pumpWidget(ProviderScope(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryStore()),
    ], child: const ChordMasterApp()));

    // The app should contain a MaterialApp (router-based) and build successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
