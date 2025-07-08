import 'package:flutter/foundation.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/services/api_service.dart';

enum TodoFilter { all, active, completed }

class TodoProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<TodoItem> _todos = [];
  bool _isLoading = false;
  TodoFilter _currentFilter = TodoFilter.all;
  String? _error;

  TodoProvider(this._apiService);

  // Getters
  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading;
  TodoFilter get currentFilter => _currentFilter;
  String? get error => _error;

  List<TodoItem> get filteredTodos {
    switch (_currentFilter) {
      case TodoFilter.active:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return _todos.where((todo) => todo.isCompleted).toList();
      case TodoFilter.all:
        return _todos;
    }
  }

  int get totalCount => _todos.length;
  int get activeCount => _todos.where((todo) => !todo.isCompleted).length;
  int get completedCount => _todos.where((todo) => todo.isCompleted).length;

  // Actions
  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();

    try {
      _todos = await _apiService.getTodos();
      // Sort todos with newest first
      _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load todos: $e');
      _setError(e.toString());
      // Keep existing todos on error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTodo(
    String title,
    Priority priority, {
    DateTime? dueDate,
  }) async {
    _clearError();

    try {
      final newTodo = await _apiService.createTodo(
        title: title,
        priority: priority,
        dueDate: dueDate,
      );

      // Add to beginning of list (newest first)
      _todos.insert(0, newTodo);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add todo: $e');
      _setError(e.toString());
      rethrow; // Rethrow so UI can handle the error
    }
  }

  Future<void> updateTodo(TodoItem updatedTodo) async {
    _clearError();

    try {
      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);

      if (index == -1) {
        throw ArgumentError('Todo with id ${updatedTodo.id} not found');
      }

      final apiUpdatedTodo = await _apiService.updateTodo(updatedTodo);
      _todos[index] = apiUpdatedTodo;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update todo: $e');
      _setError(e.toString());
      rethrow; // Rethrow so UI can handle the error
    }
  }

  Future<void> deleteTodo(String id) async {
    _clearError();

    try {
      final index = _todos.indexWhere((todo) => todo.id == id);

      if (index == -1) {
        throw ArgumentError('Todo with id $id not found');
      }

      await _apiService.deleteTodo(id);
      _todos.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete todo: $e');
      _setError(e.toString());
      rethrow; // Rethrow so UI can handle the error
    }
  }

  Future<void> toggleTodo(String id) async {
    _clearError();

    try {
      final index = _todos.indexWhere((todo) => todo.id == id);

      if (index == -1) {
        throw ArgumentError('Todo with id $id not found');
      }

      final currentTodo = _todos[index];
      final newCompletedState = !currentTodo.isCompleted;
      
      final updatedTodo = await _apiService.toggleTodo(id, newCompletedState);
      _todos[index] = updatedTodo;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to toggle todo: $e');
      _setError(e.toString());
      rethrow; // Rethrow so UI can handle the error
    }
  }

  void setFilter(TodoFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    _clearError();

    try {
      final completedTodos = _todos.where((todo) => todo.isCompleted).toList();
      
      // Delete each completed todo from the API
      for (final todo in completedTodos) {
        await _apiService.deleteTodo(todo.id);
      }
      
      // Remove from local list
      _todos.removeWhere((todo) => todo.isCompleted);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear completed todos: $e');
      _setError(e.toString());
      rethrow; // Rethrow so UI can handle the error
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
