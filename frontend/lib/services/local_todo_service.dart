import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/services/storage_service.dart';

class LocalTodoService {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  LocalTodoService(this._storageService);

  /// Get all todos from local storage (including soft-deleted ones for sync purposes)
  Future<List<TodoItem>> getAllTodos() async {
    try {
      return await _storageService.loadTodos();
    } catch (e) {
      debugPrint('Failed to load todos from local storage: $e');
      return [];
    }
  }

  /// Get visible todos (non-deleted) from local storage
  Future<List<TodoItem>> getTodos() async {
    try {
      final allTodos = await _storageService.loadTodos();
      return allTodos.where((todo) => !todo.isDeleted).toList();
    } catch (e) {
      debugPrint('Failed to load todos from local storage: $e');
      return [];
    }
  }

  /// Get todos that need to be synced to the server
  Future<List<TodoItem>> getUnsyncedTodos() async {
    try {
      final allTodos = await _storageService.loadTodos();
      return allTodos.where((todo) => todo.needsSync).toList();
    } catch (e) {
      debugPrint('Failed to load unsynced todos: $e');
      return [];
    }
  }

  /// Get todos by their sync status
  Future<List<TodoItem>> getTodosByStatus({required bool synced}) async {
    try {
      final allTodos = await _storageService.loadTodos();
      return allTodos
          .where((todo) => todo.isSynced == synced && !todo.isDeleted)
          .toList();
    } catch (e) {
      debugPrint('Failed to load todos by sync status: $e');
      return [];
    }
  }

  /// Create a new todo locally
  Future<TodoItem> createTodo({
    required String title,
    required Priority priority,
    DateTime? dueDate,
  }) async {
    try {
      final now = DateTime.now();
      final newTodo = TodoItem(
        id: _uuid.v4(),
        title: title,
        isCompleted: false,
        priority: priority,
        createdAt: now,
        dueDate: dueDate,
        lastModified: now,
        isSynced: false, // New todos are not synced
        serverId: null,
        isDeleted: false,
      );

      final todos = await getAllTodos();
      todos.add(newTodo);
      await _storageService.saveTodos(todos);

      debugPrint('Created local todo: ${newTodo.id}');
      return newTodo;
    } catch (e) {
      debugPrint('Failed to create todo locally: $e');
      rethrow;
    }
  }

  /// Update an existing todo locally
  Future<TodoItem> updateTodo(TodoItem updatedTodo) async {
    try {
      final todos = await getAllTodos();
      final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);

      if (index == -1) {
        throw ArgumentError('Todo with id ${updatedTodo.id} not found');
      }

      // Mark as modified for sync purposes
      final modifiedTodo = updatedTodo.markAsModified();
      todos[index] = modifiedTodo;

      await _storageService.saveTodos(todos);

      debugPrint('Updated local todo: ${modifiedTodo.id}');
      return modifiedTodo;
    } catch (e) {
      debugPrint('Failed to update todo locally: $e');
      rethrow;
    }
  }

  /// Toggle todo completion status
  Future<TodoItem> toggleTodo(String todoId) async {
    try {
      final todos = await getAllTodos();
      final index = todos.indexWhere((todo) => todo.id == todoId);

      if (index == -1) {
        throw ArgumentError('Todo with id $todoId not found');
      }

      final currentTodo = todos[index];
      final updatedTodo = currentTodo.copyWith(
        isCompleted: !currentTodo.isCompleted,
        isSynced: false,
        lastModified: DateTime.now(),
      );

      todos[index] = updatedTodo;
      await _storageService.saveTodos(todos);

      debugPrint('Toggled local todo: $todoId');
      return updatedTodo;
    } catch (e) {
      debugPrint('Failed to toggle todo locally: $e');
      rethrow;
    }
  }

  /// Soft delete a todo (mark as deleted for sync purposes)
  Future<void> deleteTodo(String todoId) async {
    try {
      final todos = await getAllTodos();
      final index = todos.indexWhere((todo) => todo.id == todoId);

      if (index == -1) {
        throw ArgumentError('Todo with id $todoId not found');
      }

      final currentTodo = todos[index];

      // If the todo is only local (no server ID), remove it completely
      if (currentTodo.isLocal) {
        todos.removeAt(index);
      } else {
        // If it has a server ID, mark as deleted for sync
        final deletedTodo = currentTodo.markAsDeleted();
        todos[index] = deletedTodo;
      }

      await _storageService.saveTodos(todos);

      debugPrint('Deleted local todo: $todoId');
    } catch (e) {
      debugPrint('Failed to delete todo locally: $e');
      rethrow;
    }
  }

  /// Hard delete completed todos
  Future<void> clearCompleted() async {
    try {
      final todos = await getAllTodos();
      final List<TodoItem> remaining = [];

      for (final todo in todos) {
        if (todo.isCompleted) {
          // If the todo is only local, skip it (delete completely)
          // If it has a server ID, mark as deleted for sync
          if (todo.hasServerVersion) {
            remaining.add(todo.markAsDeleted());
          }
        } else {
          remaining.add(todo);
        }
      }

      await _storageService.saveTodos(remaining);
      debugPrint('Cleared completed todos locally');
    } catch (e) {
      debugPrint('Failed to clear completed todos locally: $e');
      rethrow;
    }
  }

  /// Update multiple todos at once (useful for sync operations)
  Future<void> updateTodos(List<TodoItem> updatedTodos) async {
    try {
      final currentTodos = await getAllTodos();
      final Map<String, TodoItem> todoMap = {
        for (final todo in currentTodos) todo.id: todo,
      };

      // Update existing todos with new data
      for (final updatedTodo in updatedTodos) {
        todoMap[updatedTodo.id] = updatedTodo;
      }

      await _storageService.saveTodos(todoMap.values.toList());
      debugPrint('Updated ${updatedTodos.length} todos locally');
    } catch (e) {
      debugPrint('Failed to update multiple todos locally: $e');
      rethrow;
    }
  }

  /// Replace all todos (useful for full sync from server)
  Future<void> replaceTodos(List<TodoItem> newTodos) async {
    try {
      await _storageService.saveTodos(newTodos);
      debugPrint('Replaced all todos locally with ${newTodos.length} todos');
    } catch (e) {
      debugPrint('Failed to replace todos locally: $e');
      rethrow;
    }
  }

  /// Get the count of unsynced todos
  Future<int> getUnsyncedCount() async {
    try {
      final unsyncedTodos = await getUnsyncedTodos();
      return unsyncedTodos.length;
    } catch (e) {
      debugPrint('Failed to get unsynced count: $e');
      return 0;
    }
  }

  /// Check if there are any unsynced changes
  Future<bool> hasUnsyncedChanges() async {
    try {
      final unsyncedCount = await getUnsyncedCount();
      return unsyncedCount > 0;
    } catch (e) {
      debugPrint('Failed to check for unsynced changes: $e');
      return false;
    }
  }

  /// Clear all local data
  Future<void> clearAll() async {
    try {
      await _storageService.clearAll();
      debugPrint('Cleared all local todos');
    } catch (e) {
      debugPrint('Failed to clear all local todos: $e');
      rethrow;
    }
  }
}
