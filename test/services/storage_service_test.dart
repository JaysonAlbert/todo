import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    late List<TodoItem> testTodos;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();

      // Create test data
      testTodos = [
        TodoItem(
          id: 'todo-1',
          title: 'Test Todo 1',
          isCompleted: false,
          priority: Priority.high,
          createdAt: DateTime(2024, 1, 1),
        ),
        TodoItem(
          id: 'todo-2',
          title: 'Test Todo 2',
          isCompleted: true,
          priority: Priority.medium,
          createdAt: DateTime(2024, 1, 2),
          dueDate: DateTime(2024, 1, 3),
        ),
        TodoItem(
          id: 'todo-3',
          title: 'Test Todo 3',
          isCompleted: false,
          priority: Priority.low,
          createdAt: DateTime(2024, 1, 3),
        ),
      ];
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        final service = StorageService();
        await expectLater(service.init(), completes);
      });

      test('should be initialized after init() call', () async {
        final service = StorageService();
        expect(service.isInitialized, equals(false));

        await service.init();
        expect(service.isInitialized, equals(true));
      });
    });

    group('saveTodos', () {
      test('should save empty list successfully', () async {
        await expectLater(storageService.saveTodos([]), completes);
      });

      test('should save single todo successfully', () async {
        await expectLater(
          storageService.saveTodos([testTodos.first]),
          completes,
        );
      });

      test('should save multiple todos successfully', () async {
        await expectLater(storageService.saveTodos(testTodos), completes);
      });

      test('should throw when not initialized', () async {
        final uninitializedService = StorageService();

        expect(
          () => uninitializedService.saveTodos(testTodos),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('loadTodos', () {
      test('should return empty list when no todos saved', () async {
        final todos = await storageService.loadTodos();
        expect(todos, equals([]));
      });

      test('should load saved todos correctly', () async {
        // Save todos first
        await storageService.saveTodos(testTodos);

        // Load and verify
        final loadedTodos = await storageService.loadTodos();
        expect(loadedTodos.length, equals(testTodos.length));

        for (int i = 0; i < testTodos.length; i++) {
          expect(loadedTodos[i], equals(testTodos[i]));
        }
      });

      test('should preserve todo order', () async {
        await storageService.saveTodos(testTodos);

        final loadedTodos = await storageService.loadTodos();

        for (int i = 0; i < testTodos.length; i++) {
          expect(loadedTodos[i].id, equals(testTodos[i].id));
        }
      });

      test('should throw when not initialized', () async {
        final uninitializedService = StorageService();

        expect(
          () => uninitializedService.loadTodos(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('data persistence', () {
      test('should persist data across service instances', () async {
        // Save with first instance
        await storageService.saveTodos(testTodos);

        // Create new instance and load
        final newService = StorageService();
        await newService.init();
        final loadedTodos = await newService.loadTodos();

        expect(loadedTodos.length, equals(testTodos.length));
        expect(loadedTodos.first.id, equals(testTodos.first.id));
      });

      test('should handle overwriting existing data', () async {
        // Save initial data
        await storageService.saveTodos(testTodos);

        // Save new data
        final newTodos = [
          TodoItem(
            id: 'new-todo',
            title: 'New Todo',
            isCompleted: false,
            priority: Priority.medium,
            createdAt: DateTime.now(),
          ),
        ];
        await storageService.saveTodos(newTodos);

        // Verify only new data exists
        final loadedTodos = await storageService.loadTodos();
        expect(loadedTodos.length, equals(1));
        expect(loadedTodos.first.id, equals('new-todo'));
      });
    });

    group('error handling', () {
      test('should handle corrupted data gracefully', () async {
        // Manually set corrupted data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('todos', 'invalid-json');

        final loadedTodos = await storageService.loadTodos();
        expect(loadedTodos, equals([]));
      });

      test('should handle missing fields in saved data', () async {
        // Manually set incomplete data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('todos', '[{"id": "test", "title": "test"}]');

        final loadedTodos = await storageService.loadTodos();
        expect(loadedTodos, equals([]));
      });

      test('should handle null values gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('todos', 'null');

        final loadedTodos = await storageService.loadTodos();
        expect(loadedTodos, equals([]));
      });
    });

    group('data integrity', () {
      test('should preserve all todo properties', () async {
        final todoWithAllFields = TodoItem(
          id: 'complete-todo',
          title: 'Complete Todo with All Fields',
          isCompleted: true,
          priority: Priority.high,
          createdAt: DateTime(2024, 1, 1, 12, 30),
          dueDate: DateTime(2024, 1, 2, 15, 45),
        );

        await storageService.saveTodos([todoWithAllFields]);
        final loadedTodos = await storageService.loadTodos();

        final loadedTodo = loadedTodos.first;
        expect(loadedTodo.id, equals(todoWithAllFields.id));
        expect(loadedTodo.title, equals(todoWithAllFields.title));
        expect(loadedTodo.isCompleted, equals(todoWithAllFields.isCompleted));
        expect(loadedTodo.priority, equals(todoWithAllFields.priority));
        expect(loadedTodo.createdAt, equals(todoWithAllFields.createdAt));
        expect(loadedTodo.dueDate, equals(todoWithAllFields.dueDate));
      });

      test('should handle special characters in title', () async {
        final specialTodo = TodoItem(
          id: 'special-todo',
          title: 'Special chars: éñ中文🚀"\'<>&',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: DateTime.now(),
        );

        await storageService.saveTodos([specialTodo]);
        final loadedTodos = await storageService.loadTodos();

        expect(loadedTodos.first.title, equals(specialTodo.title));
      });

      test('should handle very long titles', () async {
        final longTitle = 'A' * 1000; // 1000 character title
        final longTitleTodo = TodoItem(
          id: 'long-title-todo',
          title: longTitle,
          isCompleted: false,
          priority: Priority.low,
          createdAt: DateTime.now(),
        );

        await storageService.saveTodos([longTitleTodo]);
        final loadedTodos = await storageService.loadTodos();

        expect(loadedTodos.first.title, equals(longTitle));
      });
    });

    group('clearAll', () {
      test('should clear all saved todos', () async {
        // Save some todos
        await storageService.saveTodos(testTodos);

        // Verify they exist
        var loadedTodos = await storageService.loadTodos();
        expect(loadedTodos.length, equals(testTodos.length));

        // Clear all
        await storageService.clearAll();

        // Verify they're gone
        loadedTodos = await storageService.loadTodos();
        expect(loadedTodos, equals([]));
      });

      test('should throw when not initialized', () async {
        final uninitializedService = StorageService();

        expect(
          () => uninitializedService.clearAll(),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
