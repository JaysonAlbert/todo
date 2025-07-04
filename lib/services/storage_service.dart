import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/models/todo_item.dart';

class StorageService {
  static const String _todosKey = 'todos';
  SharedPreferences? _prefs;

  bool get isInitialized => _prefs != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    _ensureInitialized();

    try {
      final todoJsonList = todos.map((todo) => todo.toJson()).toList();
      final jsonString = jsonEncode(todoJsonList);
      await _prefs!.setString(_todosKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save todos: $e');
    }
  }

  Future<List<TodoItem>> loadTodos() async {
    _ensureInitialized();

    try {
      final jsonString = _prefs!.getString(_todosKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(jsonString);

      if (decoded == null) {
        return [];
      }

      if (decoded is! List) {
        return [];
      }

      final todos = <TodoItem>[];

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final todo = TodoItem.fromJson(item);
            todos.add(todo);
          } catch (e) {
            // Skip invalid todo items but continue processing others
            continue;
          }
        }
      }

      return todos;
    } catch (e) {
      // Return empty list if there's any error loading/parsing data
      return [];
    }
  }

  Future<void> clearAll() async {
    _ensureInitialized();

    try {
      await _prefs!.remove(_todosKey);
    } catch (e) {
      throw Exception('Failed to clear todos: $e');
    }
  }
}
