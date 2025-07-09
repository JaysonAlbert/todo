import 'package:flutter/foundation.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/models/app_mode.dart';
import 'package:todo/services/api_service.dart';
import 'package:todo/services/local_todo_service.dart';
import 'package:todo/services/sync_service.dart';
import 'package:todo/services/connectivity_service.dart';

enum TodoFilter { all, active, completed }

class TodoProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocalTodoService _localTodoService;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;

  List<TodoItem> _todos = [];
  bool _isLoading = false;
  TodoFilter _currentFilter = TodoFilter.all;
  String? _error;
  AppModeState _appModeState = const AppModeState(currentMode: AppMode.offline);

  TodoProvider(
    this._apiService,
    this._localTodoService,
    this._syncService,
    this._connectivityService,
  ) {
    _initializeConnectivity();
  }

  // Getters
  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading;
  TodoFilter get currentFilter => _currentFilter;
  String? get error => _error;
  AppModeState get appModeState => _appModeState;
  AppMode get currentMode => _appModeState.currentMode;
  bool get isOfflineMode => _appModeState.currentMode == AppMode.offline;
  bool get isOnlineMode => _appModeState.currentMode == AppMode.online;
  bool get hasUnsynced => _appModeState.hasUnsynced;
  int get unsyncedCount => _appModeState.unsyncedCount;
  bool get isConnected => _connectivityService.isConnected;

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

  // Initialization
  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _connectivityService.connectionStream.listen(_onConnectivityChanged);

    // Update app mode state with initial connectivity
    await _updateUnsyncedStatus();
  }

  void _onConnectivityChanged(ConnectionStatus status) {
    debugPrint('Connectivity changed: $status');
    // Optionally auto-switch modes based on connectivity
    // For now, just update the UI with connectivity status
    notifyListeners();
  }

  // Actions
  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();

    try {
      if (isOfflineMode) {
        _todos = await _localTodoService.getTodos();
      } else {
        _todos = await _apiService.getTodos();
      }

      // Sort todos with newest first
      _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _updateUnsyncedStatus();
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
      TodoItem newTodo;

      if (isOfflineMode) {
        newTodo = await _localTodoService.createTodo(
          title: title,
          priority: priority,
          dueDate: dueDate,
        );
      } else {
        // Create on server first
        newTodo = await _apiService.createTodo(
          title: title,
          priority: priority,
          dueDate: dueDate,
        );
        
        // Also store in local storage with synced status
        final syncedTodo = newTodo.copyWith(
          serverId: newTodo.id,
          isSynced: true,
        );
        await _localTodoService.updateTodos([syncedTodo]);
      }

      // Add to beginning of list (newest first)
      _todos.insert(0, newTodo);
      await _updateUnsyncedStatus();
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

      TodoItem resultTodo;

      if (isOfflineMode) {
        resultTodo = await _localTodoService.updateTodo(updatedTodo);
      } else {
        // Update on server first
        resultTodo = await _apiService.updateTodo(updatedTodo);
        
        // Also update in local storage with synced status
        final syncedTodo = resultTodo.copyWith(
          serverId: resultTodo.id,
          isSynced: true,
        );
        await _localTodoService.updateTodos([syncedTodo]);
      }

      _todos[index] = resultTodo;
      await _updateUnsyncedStatus();
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

      if (isOfflineMode) {
        await _localTodoService.deleteTodo(id);
        _todos.removeAt(index);
      } else {
        // Delete from server first
        await _apiService.deleteTodo(id);
        _todos.removeAt(index);
        
        // Also remove from local storage
        await _localTodoService.deleteTodo(id);
      }
      
      await _updateUnsyncedStatus();
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

      TodoItem updatedTodo;
      
      if (isOfflineMode) {
        updatedTodo = await _localTodoService.toggleTodo(id);
      } else {
        final currentTodo = _todos[index];
        final newCompletedState = !currentTodo.isCompleted;
        updatedTodo = await _apiService.toggleTodo(id, newCompletedState);
        
        // Also update in local storage with synced status
        final syncedTodo = updatedTodo.copyWith(
          serverId: updatedTodo.id,
          isSynced: true,
        );
        await _localTodoService.updateTodos([syncedTodo]);
      }
      
      _todos[index] = updatedTodo;
      await _updateUnsyncedStatus();
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

  // Mode and Sync Management
  Future<void> switchToOfflineMode() async {
    _appModeState = _appModeState.copyWith(currentMode: AppMode.offline);
    await loadTodos(); // Reload todos from local storage
    debugPrint('Switched to offline mode');
    notifyListeners();
  }

  Future<void> switchToOnlineMode() async {
    if (!_connectivityService.isConnected) {
      _setError('Cannot switch to online mode: No internet connection');
      return;
    }

    _appModeState = _appModeState.copyWith(currentMode: AppMode.online);
    await loadTodos(); // Reload todos from server
    debugPrint('Switched to online mode');
    notifyListeners();
  }

  Future<void> syncTodos({ConflictResolution? conflictResolution}) async {
    if (!_connectivityService.isConnected) {
      _setError('Cannot sync: No internet connection');
      return;
    }

    _appModeState = _appModeState.copyWith(isSyncing: true);
    _clearError();
    notifyListeners();

    try {
      final syncReport = await _syncService.syncTodos(
        conflictResolution: conflictResolution,
      );

      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        lastSyncAt: syncReport.syncedAt,
        syncError: syncReport.errorMessage,
      );

      if (syncReport.result == SyncResult.success || 
          syncReport.result == SyncResult.conflict) {
        await loadTodos(); // Reload todos after sync
        debugPrint('Sync completed: ${syncReport.localChangesUploaded} uploaded, '
            '${syncReport.serverChangesDownloaded} downloaded');
      } else {
        _setError(syncReport.errorMessage ?? 'Sync failed');
      }
    } catch (e) {
      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
      _setError('Sync failed: $e');
      debugPrint('Sync error: $e');
    }

    await _updateUnsyncedStatus();
    notifyListeners();
  }

  Future<void> syncFromServer() async {
    if (!_connectivityService.isConnected) {
      _setError('Cannot sync: No internet connection');
      return;
    }

    _appModeState = _appModeState.copyWith(isSyncing: true);
    _clearError();
    notifyListeners();

    try {
      final syncReport = await _syncService.fullSyncFromServer();
      
      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        lastSyncAt: syncReport.syncedAt,
        syncError: syncReport.errorMessage,
      );

      if (syncReport.result == SyncResult.success) {
        await loadTodos(); // Reload todos after sync
        debugPrint('Full sync from server completed');
      } else {
        _setError(syncReport.errorMessage ?? 'Sync from server failed');
      }
    } catch (e) {
      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
      _setError('Sync from server failed: $e');
      debugPrint('Sync from server error: $e');
    }

    await _updateUnsyncedStatus();
    notifyListeners();
  }

  Future<void> syncToServer() async {
    if (!_connectivityService.isConnected) {
      _setError('Cannot sync: No internet connection');
      return;
    }

    _appModeState = _appModeState.copyWith(isSyncing: true);
    _clearError();
    notifyListeners();

    try {
      final syncReport = await _syncService.fullSyncToServer();
      
      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        lastSyncAt: syncReport.syncedAt,
        syncError: syncReport.errorMessage,
      );

      if (syncReport.result == SyncResult.success) {
        await loadTodos(); // Reload todos after sync
        debugPrint('Full sync to server completed');
      } else {
        _setError(syncReport.errorMessage ?? 'Sync to server failed');
      }
    } catch (e) {
      _appModeState = _appModeState.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
      _setError('Sync to server failed: $e');
      debugPrint('Sync to server error: $e');
    }

    await _updateUnsyncedStatus();
    notifyListeners();
  }

    Future<void> clearCompleted() async {
    _clearError();

    try {
      if (isOfflineMode) {
        await _localTodoService.clearCompleted();
      } else {
        final completedTodos = _todos.where((todo) => todo.isCompleted).toList();
        
        // Delete each completed todo from the API and local storage
        for (final todo in completedTodos) {
          await _apiService.deleteTodo(todo.id);
          await _localTodoService.deleteTodo(todo.id);
        }
      }
      
      // Remove from local list
      _todos.removeWhere((todo) => todo.isCompleted);
      await _updateUnsyncedStatus();
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

  Future<void> _updateUnsyncedStatus() async {
    try {
      final unsyncedCount = await _localTodoService.getUnsyncedCount();
      _appModeState = _appModeState.copyWith(
        hasUnsynced: unsyncedCount > 0,
        unsyncedCount: unsyncedCount,
      );
    } catch (e) {
      debugPrint('Failed to update unsynced status: $e');
    }
  }
}
