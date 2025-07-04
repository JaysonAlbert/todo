import 'package:flutter_test/flutter_test.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';

void main() {
  group('TodoItem', () {
    late DateTime testDate;
    late DateTime testDueDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0);
      testDueDate = DateTime(2024, 1, 2, 12, 0);
    });

    group('constructor', () {
      test('should create a TodoItem with required parameters', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        expect(todo.id, equals('test-id'));
        expect(todo.title, equals('Test Todo'));
        expect(todo.isCompleted, equals(false));
        expect(todo.priority, equals(Priority.medium));
        expect(todo.createdAt, equals(testDate));
        expect(todo.dueDate, isNull);
      });

      test('should create a TodoItem with optional due date', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.high,
          createdAt: testDate,
          dueDate: testDueDate,
        );

        expect(todo.dueDate, equals(testDueDate));
      });

      test('should handle empty title', () {
        final todo = TodoItem(
          id: 'test-id',
          title: '',
          isCompleted: false,
          priority: Priority.low,
          createdAt: testDate,
        );

        expect(todo.title, equals(''));
      });
    });

    group('copyWith', () {
      late TodoItem originalTodo;

      setUp(() {
        originalTodo = TodoItem(
          id: 'original-id',
          title: 'Original Title',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );
      });

      test('should create a copy with updated title', () {
        final updatedTodo = originalTodo.copyWith(title: 'Updated Title');

        expect(updatedTodo.title, equals('Updated Title'));
        expect(updatedTodo.id, equals(originalTodo.id));
        expect(updatedTodo.isCompleted, equals(originalTodo.isCompleted));
        expect(updatedTodo.priority, equals(originalTodo.priority));
        expect(updatedTodo.createdAt, equals(originalTodo.createdAt));
      });

      test('should create a copy with updated completion status', () {
        final updatedTodo = originalTodo.copyWith(isCompleted: true);

        expect(updatedTodo.isCompleted, equals(true));
        expect(updatedTodo.title, equals(originalTodo.title));
      });

      test('should create a copy with updated priority', () {
        final updatedTodo = originalTodo.copyWith(priority: Priority.high);

        expect(updatedTodo.priority, equals(Priority.high));
        expect(updatedTodo.title, equals(originalTodo.title));
      });

      test('should create a copy with added due date', () {
        final updatedTodo = originalTodo.copyWith(dueDate: testDueDate);

        expect(updatedTodo.dueDate, equals(testDueDate));
        expect(updatedTodo.title, equals(originalTodo.title));
      });

      test('should create a copy with removed due date', () {
        final todoWithDueDate = originalTodo.copyWith(dueDate: testDueDate);
        final updatedTodo = todoWithDueDate.copyWith(dueDate: null);

        expect(updatedTodo.dueDate, isNull);
      });
    });

    group('serialization', () {
      test('should convert to JSON correctly', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: true,
          priority: Priority.high,
          createdAt: testDate,
          dueDate: testDueDate,
        );

        final json = todo.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['title'], equals('Test Todo'));
        expect(json['isCompleted'], equals(true));
        expect(json['priority'], equals('high'));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['dueDate'], equals(testDueDate.toIso8601String()));
      });

      test('should convert to JSON without due date', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.low,
          createdAt: testDate,
        );

        final json = todo.toJson();

        expect(json['dueDate'], isNull);
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Todo',
          'isCompleted': true,
          'priority': 'medium',
          'createdAt': testDate.toIso8601String(),
          'dueDate': testDueDate.toIso8601String(),
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.id, equals('test-id'));
        expect(todo.title, equals('Test Todo'));
        expect(todo.isCompleted, equals(true));
        expect(todo.priority, equals(Priority.medium));
        expect(todo.createdAt, equals(testDate));
        expect(todo.dueDate, equals(testDueDate));
      });

      test('should create from JSON without due date', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Todo',
          'isCompleted': false,
          'priority': 'low',
          'createdAt': testDate.toIso8601String(),
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.dueDate, isNull);
      });

      test('should handle invalid priority in JSON', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Todo',
          'isCompleted': false,
          'priority': 'invalid',
          'createdAt': testDate.toIso8601String(),
        };

        expect(() => TodoItem.fromJson(json), throwsA(isA<ArgumentError>()));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final todo1 = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        final todo2 = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        expect(todo1, equals(todo2));
        expect(todo1.hashCode, equals(todo2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final todo1 = TodoItem(
          id: 'test-id-1',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        final todo2 = TodoItem(
          id: 'test-id-2',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        expect(todo1, isNot(equals(todo2)));
      });
    });

    group('convenience methods', () {
      test('isOverdue should return true when due date is in the past', () {
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 1));

        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
          dueDate: pastDate,
        );

        expect(todo.isOverdue, equals(true));
      });

      test('isOverdue should return false when due date is in the future', () {
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 1));

        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
          dueDate: futureDate,
        );

        expect(todo.isOverdue, equals(false));
      });

      test('isOverdue should return false when no due date is set', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: false,
          priority: Priority.medium,
          createdAt: testDate,
        );

        expect(todo.isOverdue, equals(false));
      });

      test('isOverdue should return false when completed even if overdue', () {
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 1));

        final todo = TodoItem(
          id: 'test-id',
          title: 'Test Todo',
          isCompleted: true,
          priority: Priority.medium,
          createdAt: testDate,
          dueDate: pastDate,
        );

        expect(todo.isOverdue, equals(false));
      });
    });
  });
}
