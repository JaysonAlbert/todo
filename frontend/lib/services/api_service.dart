import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/services/auth_service.dart';

class ApiService {
  final AuthService _authService;

  ApiService(this._authService);

  // Todo CRUD Operations

  Future<List<TodoItem>> getTodos() async {
    try {
      final response = await _authService.get('/todos');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> todosData = response.data['data'];
        return todosData.map((json) => TodoItemApi.fromApiJson(json)).toList();
      }

      throw Exception(
        'Failed to load todos: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      debugPrint('Get todos API error: ${e.response?.data}');
      throw _handleApiError(e);
    }
  }

  Future<TodoItem> createTodo({
    required String title,
    required Priority priority,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _authService.post(
        '/todos',
        data: {
          'title': title,
          'priority': priority.name,
          'due_date': dueDate?.toIso8601String(),
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return TodoItemApi.fromApiJson(response.data['data']);
      }

      throw Exception(
        'Failed to create todo: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      debugPrint('Create todo API error: ${e.response?.data}');
      throw _handleApiError(e);
    }
  }

  Future<TodoItem> updateTodo(TodoItem todo) async {
    try {
      final response = await _authService.put(
        '/todos/${todo.id}',
        data: {
          'title': todo.title,
          'priority': todo.priority.name,
          'is_completed': todo.isCompleted,
          'due_date': todo.dueDate?.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TodoItemApi.fromApiJson(response.data['data']);
      }

      throw Exception(
        'Failed to update todo: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      debugPrint('Update todo API error: ${e.response?.data}');
      throw _handleApiError(e);
    }
  }

  Future<void> deleteTodo(String todoId) async {
    try {
      final response = await _authService.delete('/todos/$todoId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          'Failed to delete todo: ${response.data['message'] ?? 'Unknown error'}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete todo API error: ${e.response?.data}');
      throw _handleApiError(e);
    }
  }

  Future<TodoItem> toggleTodo(String todoId, bool isCompleted) async {
    try {
      final response = await _authService.put(
        '/todos/$todoId',
        data: {'is_completed': isCompleted},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TodoItemApi.fromApiJson(response.data['data']);
      }

      throw Exception(
        'Failed to toggle todo: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      debugPrint('Toggle todo API error: ${e.response?.data}');
      throw _handleApiError(e);
    }
  }

  // Error handling helper
  String _handleApiError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.connectionError:
        return 'Connection failed. Please check your internet connection.';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Unknown error';

        switch (statusCode) {
          case 400:
            return 'Invalid request: $message';
          case 401:
            return 'Authentication failed. Please sign in again.';
          case 403:
            return 'Access denied: $message';
          case 404:
            return 'Resource not found: $message';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Request failed: $message';
        }

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.unknown:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

// Extension to handle API JSON format differences
extension TodoItemApi on TodoItem {
  static TodoItem fromApiJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    };
  }
}
