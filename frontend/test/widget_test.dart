// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/main.dart';
import 'package:todo/services/auth_service.dart';
import 'package:todo/services/storage_service.dart';
import 'package:todo/services/local_todo_service.dart';
import 'package:todo/services/api_service.dart';
import 'package:todo/services/sync_service.dart';
import 'package:todo/services/connectivity_service.dart';

void main() {
  testWidgets('Todo app loads successfully', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Initialize services
    final storageService = StorageService();
    await storageService.init();
    final authService = AuthService();
    final connectivityService = ConnectivityService();
    final localTodoService = LocalTodoService(storageService);
    final apiService = ApiService(authService);
    final syncService = SyncService(apiService, localTodoService);

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MyApp(
        storageService: storageService,
        authService: authService,
        connectivityService: connectivityService,
        localTodoService: localTodoService,
        apiService: apiService,
        syncService: syncService,
      ),
    );

    // Just pump a few frames to ensure the app initializes without crashing
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // For now, just verify the app loads without errors
    // The main focus is on the offline/online functionality working correctly
    // More comprehensive UI tests will be added later
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
