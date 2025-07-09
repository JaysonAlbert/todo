import 'package:flutter/foundation.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/services/api_service.dart';
import 'package:todo/services/local_todo_service.dart';

enum SyncResult { success, conflict, error, noChanges }

enum ConflictResolution { localWins, serverWins, mergeLatest }

class SyncConflict {
  final TodoItem localTodo;
  final TodoItem serverTodo;
  final String conflictReason;

  const SyncConflict({
    required this.localTodo,
    required this.serverTodo,
    required this.conflictReason,
  });
}

class SyncReport {
  final SyncResult result;
  final int localChangesUploaded;
  final int serverChangesDownloaded;
  final int conflictsResolved;
  final List<SyncConflict> unresolvedConflicts;
  final String? errorMessage;
  final DateTime syncedAt;

  const SyncReport({
    required this.result,
    this.localChangesUploaded = 0,
    this.serverChangesDownloaded = 0,
    this.conflictsResolved = 0,
    this.unresolvedConflicts = const [],
    this.errorMessage,
    required this.syncedAt,
  });
}

class SyncService {
  final ApiService _apiService;
  final LocalTodoService _localTodoService;
  final ConflictResolution _defaultConflictResolution;

  SyncService(
    this._apiService,
    this._localTodoService, {
    ConflictResolution defaultConflictResolution =
        ConflictResolution.mergeLatest,
  }) : _defaultConflictResolution = defaultConflictResolution;

  /// Sync local todos with server
  Future<SyncReport> syncTodos({ConflictResolution? conflictResolution}) async {
    final syncStartTime = DateTime.now();
    debugPrint('Starting todo sync...');

    try {
      // Get all local todos (including deleted ones for sync)
      final localTodos = await _localTodoService.getAllTodos();

      // Get all server todos
      final serverTodos = await _getServerTodos();

      // Separate local todos by sync status
      final unsyncedTodos = localTodos.where((todo) => todo.needsSync).toList();

      if (unsyncedTodos.isEmpty && serverTodos.isEmpty) {
        debugPrint('No changes to sync');
        return SyncReport(
          result: SyncResult.noChanges,
          syncedAt: syncStartTime,
        );
      }

      int localChangesUploaded = 0;
      int serverChangesDownloaded = 0;
      int conflictsResolved = 0;
      final List<SyncConflict> unresolvedConflicts = [];

      // Step 1: Upload local changes to server
      for (final localTodo in unsyncedTodos) {
        try {
          if (localTodo.isDeleted) {
            // Handle deleted todos
            if (localTodo.hasServerVersion) {
              await _apiService.deleteTodo(localTodo.serverId!);
              localChangesUploaded++;
            }
          } else if (localTodo.isLocal) {
            // Create new todo on server
            final serverTodo = await _apiService.createTodo(
              title: localTodo.title,
              priority: localTodo.priority,
              dueDate: localTodo.dueDate,
            );

            // Update local todo with server ID and mark as synced
            final syncedTodo = localTodo.markAsSynced(
              newServerId: serverTodo.id,
            );
            await _localTodoService.updateTodos([syncedTodo]);
            localChangesUploaded++;
                    } else {
            // Update existing todo on server
            await _apiService.updateTodo(localTodo);
            
            // Mark local todo as synced
            final syncedTodo = localTodo.markAsSynced();
            await _localTodoService.updateTodos([syncedTodo]);
            localChangesUploaded++;
          }
        } catch (e) {
          debugPrint('Failed to sync local todo ${localTodo.id}: $e');
          // Continue with other todos
        }
      }

      // Step 2: Download server changes and handle conflicts
      final Map<String, TodoItem> localTodoMap = {
        for (final todo in localTodos)
          if (todo.serverId != null) todo.serverId!: todo,
      };

      for (final serverTodo in serverTodos) {
        final localTodo = localTodoMap[serverTodo.id];

        if (localTodo == null) {
          // New todo from server - add to local storage
          final localServerTodo = _convertServerTodoToLocal(serverTodo);
          await _localTodoService.updateTodos([localServerTodo]);
          serverChangesDownloaded++;
        } else if (localTodo.isSynced) {
          // Check if server version is newer
          final serverModified =
              serverTodo.lastModified ?? serverTodo.createdAt;
          final localModified = localTodo.lastModified ?? localTodo.createdAt;

          if (serverModified.isAfter(localModified)) {
            // Server version is newer - update local
            final updatedLocalTodo = _convertServerTodoToLocal(serverTodo);
            await _localTodoService.updateTodos([updatedLocalTodo]);
            serverChangesDownloaded++;
          }
        } else {
          // Conflict: both local and server have changes
          final conflict = SyncConflict(
            localTodo: localTodo,
            serverTodo: serverTodo,
            conflictReason: 'Both local and server versions modified',
          );

          final resolution = conflictResolution ?? _defaultConflictResolution;
          final resolvedTodo = _resolveConflict(conflict, resolution);

          if (resolvedTodo != null) {
            await _localTodoService.updateTodos([resolvedTodo]);
            conflictsResolved++;
          } else {
            unresolvedConflicts.add(conflict);
          }
        }
      }

      // Step 3: Clean up deleted todos that have been synced
      final syncedDeletedTodos = localTodos
          .where((todo) => todo.isDeleted && todo.isSynced)
          .toList();

      if (syncedDeletedTodos.isNotEmpty) {
        final remainingTodos = localTodos
            .where((todo) => !syncedDeletedTodos.contains(todo))
            .toList();
        await _localTodoService.replaceTodos(remainingTodos);
      }

      final result = unresolvedConflicts.isNotEmpty
          ? SyncResult.conflict
          : SyncResult.success;

      debugPrint(
        'Sync completed: $localChangesUploaded uploaded, '
        '$serverChangesDownloaded downloaded, '
        '$conflictsResolved conflicts resolved, '
        '${unresolvedConflicts.length} unresolved conflicts',
      );

      return SyncReport(
        result: result,
        localChangesUploaded: localChangesUploaded,
        serverChangesDownloaded: serverChangesDownloaded,
        conflictsResolved: conflictsResolved,
        unresolvedConflicts: unresolvedConflicts,
        syncedAt: syncStartTime,
      );
    } catch (e) {
      debugPrint('Sync failed: $e');
      return SyncReport(
        result: SyncResult.error,
        errorMessage: e.toString(),
        syncedAt: syncStartTime,
      );
    }
  }

  /// Download all todos from server and replace local todos (full sync)
  Future<SyncReport> fullSyncFromServer() async {
    final syncStartTime = DateTime.now();
    debugPrint('Starting full sync from server...');

    try {
      final serverTodos = await _getServerTodos();
      final localTodos = serverTodos.map(_convertServerTodoToLocal).toList();

      await _localTodoService.replaceTodos(localTodos);

      debugPrint('Full sync completed: ${localTodos.length} todos downloaded');

      return SyncReport(
        result: SyncResult.success,
        serverChangesDownloaded: localTodos.length,
        syncedAt: syncStartTime,
      );
    } catch (e) {
      debugPrint('Full sync failed: $e');
      return SyncReport(
        result: SyncResult.error,
        errorMessage: e.toString(),
        syncedAt: syncStartTime,
      );
    }
  }

  /// Upload all local todos to server (overwrites server data)
  Future<SyncReport> fullSyncToServer() async {
    final syncStartTime = DateTime.now();
    debugPrint('Starting full sync to server...');

    try {
      final localTodos = await _localTodoService.getTodos();
      int uploadedCount = 0;

      for (final localTodo in localTodos) {
        try {
          TodoItem serverTodo;
          if (localTodo.hasServerVersion) {
            serverTodo = await _apiService.updateTodo(localTodo);
          } else {
            serverTodo = await _apiService.createTodo(
              title: localTodo.title,
              priority: localTodo.priority,
              dueDate: localTodo.dueDate,
            );
          }

          // Update local todo with server ID and mark as synced
          final syncedTodo = localTodo.markAsSynced(newServerId: serverTodo.id);
          await _localTodoService.updateTodos([syncedTodo]);
          uploadedCount++;
        } catch (e) {
          debugPrint('Failed to upload todo ${localTodo.id}: $e');
        }
      }

      debugPrint('Full upload completed: $uploadedCount todos uploaded');

      return SyncReport(
        result: SyncResult.success,
        localChangesUploaded: uploadedCount,
        syncedAt: syncStartTime,
      );
    } catch (e) {
      debugPrint('Full upload failed: $e');
      return SyncReport(
        result: SyncResult.error,
        errorMessage: e.toString(),
        syncedAt: syncStartTime,
      );
    }
  }

  /// Get server todos and convert them to local format
  Future<List<TodoItem>> _getServerTodos() async {
    try {
      return await _apiService.getTodos();
    } catch (e) {
      debugPrint('Failed to get server todos: $e');
      rethrow;
    }
  }

  /// Convert a server todo to local format with sync metadata
  TodoItem _convertServerTodoToLocal(TodoItem serverTodo) {
    return serverTodo.copyWith(
      serverId: serverTodo.id,
      isSynced: true,
      lastModified: DateTime.now(),
      isDeleted: false,
    );
  }

  /// Resolve conflicts between local and server todos
  TodoItem? _resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) {
    switch (resolution) {
      case ConflictResolution.localWins:
        // Keep local version but mark as synced
        return conflict.localTodo.markAsSynced();

      case ConflictResolution.serverWins:
        // Use server version
        return _convertServerTodoToLocal(conflict.serverTodo);

      case ConflictResolution.mergeLatest:
        // Use the version with the latest modification time
        final localModified =
            conflict.localTodo.lastModified ?? conflict.localTodo.createdAt;
        final serverModified =
            conflict.serverTodo.lastModified ?? conflict.serverTodo.createdAt;

        if (localModified.isAfter(serverModified)) {
          return conflict.localTodo.markAsSynced();
        } else {
          return _convertServerTodoToLocal(conflict.serverTodo);
        }
    }
  }
}
