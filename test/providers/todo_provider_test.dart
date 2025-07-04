import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/services/storage_service.dart';

void main() {
  group('TodoProvider', () {
    late TodoProvider todoProvider;
    late StorageService storageService;
    late List<TodoItem> testTodos;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      storageService = StorageService();
      await storageService.init();

      todoProvider = TodoProvider(storageService);

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
      test('should start with empty todos list', () {
        expect(todoProvider.todos, equals([]));
        expect(todoProvider.isLoading, equals(false));
      });

      test('should load todos from storage on init', () async {
        // Save test data to storage first
        await storageService.saveTodos(testTodos);

        // Create new provider and load data
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        expect(newProvider.todos.length, equals(testTodos.length));
        expect(newProvider.isLoading, equals(false));
      });

      test('should set loading state during load', () async {
        bool wasLoading = false;

        todoProvider.addListener(() {
          if (todoProvider.isLoading) {
            wasLoading = true;
          }
        });

        await todoProvider.loadTodos();

        expect(wasLoading, equals(true));
        expect(todoProvider.isLoading, equals(false));
      });
    });

    group('addTodo', () {
      test('should add new todo with generated ID', () async {
        const title = 'New Todo';
        const priority = Priority.medium;

        await todoProvider.addTodo(title, priority);

        expect(todoProvider.todos.length, equals(1));

        final addedTodo = todoProvider.todos.first;
        expect(addedTodo.title, equals(title));
        expect(addedTodo.priority, equals(priority));
        expect(addedTodo.isCompleted, equals(false));
        expect(addedTodo.id, isNotEmpty);
        expect(addedTodo.createdAt, isNotNull);
      });

      test('should add todo with due date', () async {
        const title = 'Todo with Due Date';
        final dueDate = DateTime(2024, 12, 31);

        await todoProvider.addTodo(title, Priority.high, dueDate: dueDate);

        final addedTodo = todoProvider.todos.first;
        expect(addedTodo.dueDate, equals(dueDate));
      });

      test('should add todo to beginning of list', () async {
        await todoProvider.addTodo('First Todo', Priority.low);
        await todoProvider.addTodo('Second Todo', Priority.high);

        expect(todoProvider.todos.length, equals(2));
        expect(todoProvider.todos.first.title, equals('Second Todo'));
        expect(todoProvider.todos.last.title, equals('First Todo'));
      });

      test('should persist todo to storage', () async {
        await todoProvider.addTodo('Persistent Todo', Priority.medium);

        // Create new provider and load from storage
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        expect(newProvider.todos.length, equals(1));
        expect(newProvider.todos.first.title, equals('Persistent Todo'));
      });

      test('should handle empty title', () async {
        await todoProvider.addTodo('', Priority.low);

        expect(todoProvider.todos.length, equals(1));
        expect(todoProvider.todos.first.title, equals(''));
      });
    });

    group('updateTodo', () {
      setUp(() async {
        // Add test todos
        for (final todo in testTodos) {
          await todoProvider.addTodo(
            todo.title,
            todo.priority,
            dueDate: todo.dueDate,
          );
        }
      });

      test('should update existing todo', () async {
        final todoId = todoProvider.todos.first.id;
        final updatedTodo = todoProvider.todos.first.copyWith(
          title: 'Updated Title',
          isCompleted: true,
        );

        await todoProvider.updateTodo(updatedTodo);

        final foundTodo = todoProvider.todos.firstWhere((t) => t.id == todoId);
        expect(foundTodo.title, equals('Updated Title'));
        expect(foundTodo.isCompleted, equals(true));
      });

      test('should persist updated todo to storage', () async {
        final todoId = todoProvider.todos.first.id;
        final updatedTodo = todoProvider.todos.first.copyWith(
          title: 'Persistent Update',
        );

        await todoProvider.updateTodo(updatedTodo);

        // Create new provider and verify persistence
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        final foundTodo = newProvider.todos.firstWhere((t) => t.id == todoId);
        expect(foundTodo.title, equals('Persistent Update'));
      });

      test('should throw when todo not found', () async {
        final nonExistentTodo = TodoItem(
          id: 'non-existent',
          title: 'Non-existent',
          isCompleted: false,
          priority: Priority.low,
          createdAt: DateTime.now(),
        );

        expect(
          () => todoProvider.updateTodo(nonExistentTodo),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('deleteTodo', () {
      setUp(() async {
        // Add test todos
        for (final todo in testTodos) {
          await todoProvider.addTodo(
            todo.title,
            todo.priority,
            dueDate: todo.dueDate,
          );
        }
      });

      test('should delete existing todo', () async {
        final initialCount = todoProvider.todos.length;
        final todoToDelete = todoProvider.todos.first;

        await todoProvider.deleteTodo(todoToDelete.id);

        expect(todoProvider.todos.length, equals(initialCount - 1));
        expect(
          todoProvider.todos.any((t) => t.id == todoToDelete.id),
          equals(false),
        );
      });

      test('should persist deletion to storage', () async {
        final todoToDeleteId = todoProvider.todos.first.id;

        await todoProvider.deleteTodo(todoToDeleteId);

        // Create new provider and verify persistence
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        expect(
          newProvider.todos.any((t) => t.id == todoToDeleteId),
          equals(false),
        );
      });

      test('should throw when todo not found', () async {
        expect(
          () => todoProvider.deleteTodo('non-existent-id'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toggleTodo', () {
      setUp(() async {
        await todoProvider.addTodo('Test Todo', Priority.medium);
      });

      test('should toggle completion status', () async {
        final todo = todoProvider.todos.first;
        final initialStatus = todo.isCompleted;

        await todoProvider.toggleTodo(todo.id);

        final updatedTodo = todoProvider.todos.first;
        expect(updatedTodo.isCompleted, equals(!initialStatus));
      });

      test('should persist toggle to storage', () async {
        final todoId = todoProvider.todos.first.id;

        await todoProvider.toggleTodo(todoId);

        // Create new provider and verify persistence
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        final foundTodo = newProvider.todos.firstWhere((t) => t.id == todoId);
        expect(foundTodo.isCompleted, equals(true));
      });

      test('should throw when todo not found', () async {
        expect(
          () => todoProvider.toggleTodo('non-existent-id'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('filtering', () {
      setUp(() async {
        // Add mixed todos
        await todoProvider.addTodo('Active Todo 1', Priority.high);
        await todoProvider.addTodo('Active Todo 2', Priority.medium);
        await todoProvider.addTodo('Completed Todo', Priority.low);

        // Complete one todo
        await todoProvider.toggleTodo(todoProvider.todos.last.id);
      });

      test('should filter active todos', () {
        todoProvider.setFilter(TodoFilter.active);

        final activeTodos = todoProvider.filteredTodos;
        expect(activeTodos.length, equals(2));
        expect(activeTodos.every((t) => !t.isCompleted), equals(true));
      });

      test('should filter completed todos', () {
        todoProvider.setFilter(TodoFilter.completed);

        final completedTodos = todoProvider.filteredTodos;
        expect(completedTodos.length, equals(1));
        expect(completedTodos.every((t) => t.isCompleted), equals(true));
      });

      test('should show all todos with all filter', () {
        todoProvider.setFilter(TodoFilter.all);

        final allTodos = todoProvider.filteredTodos;
        expect(allTodos.length, equals(todoProvider.todos.length));
      });

      test('should default to all filter', () {
        expect(todoProvider.currentFilter, equals(TodoFilter.all));
        expect(
          todoProvider.filteredTodos.length,
          equals(todoProvider.todos.length),
        );
      });
    });

    group('statistics', () {
      setUp(() async {
        await todoProvider.addTodo('Active 1', Priority.high);
        await todoProvider.addTodo('Active 2', Priority.medium);
        await todoProvider.addTodo('Completed', Priority.low);

        // Complete one todo
        await todoProvider.toggleTodo(todoProvider.todos.last.id);
      });

      test('should count total todos', () {
        expect(todoProvider.totalCount, equals(3));
      });

      test('should count active todos', () {
        expect(todoProvider.activeCount, equals(2));
      });

      test('should count completed todos', () {
        expect(todoProvider.completedCount, equals(1));
      });

      test('should update counts when todos change', () async {
        await todoProvider.addTodo('New Todo', Priority.medium);

        expect(todoProvider.totalCount, equals(4));
        expect(todoProvider.activeCount, equals(3));
        expect(todoProvider.completedCount, equals(1));
      });
    });

    group('clearCompleted', () {
      setUp(() async {
        await todoProvider.addTodo('Active Todo', Priority.high);
        await todoProvider.addTodo('Completed Todo 1', Priority.medium);
        await todoProvider.addTodo('Completed Todo 2', Priority.low);

        // Complete two todos
        await todoProvider.toggleTodo(todoProvider.todos[1].id);
        await todoProvider.toggleTodo(todoProvider.todos[2].id);
      });

      test('should remove all completed todos', () async {
        expect(todoProvider.completedCount, equals(2));

        await todoProvider.clearCompleted();

        expect(todoProvider.completedCount, equals(0));
        expect(todoProvider.activeCount, equals(1));
        expect(todoProvider.totalCount, equals(1));
      });

      test('should persist clearing to storage', () async {
        await todoProvider.clearCompleted();

        // Create new provider and verify persistence
        final newProvider = TodoProvider(storageService);
        await newProvider.loadTodos();

        expect(newProvider.completedCount, equals(0));
        expect(newProvider.totalCount, equals(1));
      });

      test('should do nothing when no completed todos', () async {
        // Clear existing completed todos first
        await todoProvider.clearCompleted();

        final initialCount = todoProvider.totalCount;
        await todoProvider.clearCompleted();

        expect(todoProvider.totalCount, equals(initialCount));
      });
    });

    group('error handling', () {
      test('should handle storage errors gracefully', () async {
        // This test would require mocking storage failures
        // For now, we test that the methods complete without throwing
        await expectLater(
          todoProvider.addTodo('Test', Priority.low),
          completes,
        );
      });
    });
  });
}
