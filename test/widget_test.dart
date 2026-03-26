// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight fake `StorageService` used in tests to avoid Hive initialization.
class _FakeStorageService implements StorageService {
  @override
  Future<void> openBoxes() async {}

  @override
  Future<void> save(String box, String key, dynamic value) async {}

  @override
  Future<T?> get<T>(String box, String key) async => null;

  @override
  Future<List<dynamic>> getAll(String box) async => <dynamic>[];

  @override
  Future<void> delete(String box, String key) async {}

  @override
  Future<void> clear(String box) async {}
}

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build the app and ensure it renders. Override storage with a fake.
    await tester.pumpWidget(ProviderScope(overrides: [
      storageServiceProvider.overrideWithValue(_FakeStorageService()),
    ], child: const ChordMasterApp()));

    // The app should contain a MaterialApp (router-based) and build successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
