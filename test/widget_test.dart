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
import 'package:todo/services/storage_service.dart';
import 'package:todo/utils/constants.dart';

void main() {
  testWidgets('Todo app loads successfully', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Initialize storage service
    final storageService = StorageService();
    await storageService.init();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(storageService: storageService));

    // Verify that our app loads with the correct title
    expect(find.text(AppStrings.appTitle), findsOneWidget);

    // Verify that the add todo form is present
    expect(find.text(AppStrings.addTodoHint), findsOneWidget);

    // Verify that the filter bar is present
    expect(find.text(AppStrings.filterAll), findsOneWidget);
    expect(find.text(AppStrings.filterActive), findsOneWidget);
    expect(find.text(AppStrings.filterCompleted), findsOneWidget);

    // Verify empty state is shown
    expect(find.text(AppStrings.noTodos), findsOneWidget);
  });
}
