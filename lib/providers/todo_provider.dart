import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/services/storage_service.dart';

enum TodoFilter { all, active, completed }

class TodoProvider extends ChangeNotifier {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<TodoItem> _todos = [];
  bool _isLoading = false;
  TodoFilter _currentFilter = TodoFilter.all;

  TodoProvider(this._storageService);

  // Getters
  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading;
  TodoFilter get currentFilter => _currentFilter;

  List<TodoItem> get filteredTodos {
    switch (_currentFilter) {
      case TodoFilter.active:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return _todos.where((todo) => todo.isCompleted).toList();
      case TodoFilter.all:
      default:
        return _todos;
    }
  }

  int get totalCount => _todos.length;
  int get activeCount => _todos.where((todo) => !todo.isCompleted).length;
  int get completedCount => _todos.where((todo) => todo.isCompleted).length;

  // Actions
  Future<void> loadTodos() async {
    _setLoading(true);

    try {
      _todos = await _storageService.loadTodos();
      notifyListeners();
    } catch (e) {
      // Handle error gracefully - keep empty list
      _todos = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTodo(
    String title,
    Priority priority, {
    DateTime? dueDate,
  }) async {
    final newTodo = TodoItem(
      id: _uuid.v4(),
      title: title,
      isCompleted: false,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    // Add to beginning of list (newest first)
    _todos.insert(0, newTodo);
    notifyListeners();

    await _saveTodos();
  }

  Future<void> updateTodo(TodoItem updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);

    if (index == -1) {
      throw ArgumentError('Todo with id ${updatedTodo.id} not found');
    }

    _todos[index] = updatedTodo;
    notifyListeners();

    await _saveTodos();
  }

  Future<void> deleteTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);

    if (index == -1) {
      throw ArgumentError('Todo with id $id not found');
    }

    _todos.removeAt(index);
    notifyListeners();

    await _saveTodos();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);

    if (index == -1) {
      throw ArgumentError('Todo with id $id not found');
    }

    _todos[index] = _todos[index].copyWith(
      isCompleted: !_todos[index].isCompleted,
    );
    notifyListeners();

    await _saveTodos();
  }

  void setFilter(TodoFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    _todos.removeWhere((todo) => todo.isCompleted);
    notifyListeners();

    await _saveTodos();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _saveTodos() async {
    try {
      await _storageService.saveTodos(_todos);
    } catch (e) {
      // Handle storage errors gracefully
      // In a real app, you might want to show a user notification
      debugPrint('Failed to save todos: $e');
    }
  }
}
