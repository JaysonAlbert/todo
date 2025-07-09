enum AppMode {
  offline,
  online;

  String get displayName {
    switch (this) {
      case AppMode.offline:
        return 'Offline Mode';
      case AppMode.online:
        return 'Online Mode';
    }
  }

  String get description {
    switch (this) {
      case AppMode.offline:
        return 'All todos are stored locally on your device';
      case AppMode.online:
        return 'Todos are stored on the server and synced across devices';
    }
  }
}

class AppModeState {
  final AppMode currentMode;
  final bool hasUnsynced;
  final int unsyncedCount;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final String? syncError;

  const AppModeState({
    required this.currentMode,
    this.hasUnsynced = false,
    this.unsyncedCount = 0,
    this.lastSyncAt,
    this.isSyncing = false,
    this.syncError,
  });

  AppModeState copyWith({
    AppMode? currentMode,
    bool? hasUnsynced,
    int? unsyncedCount,
    DateTime? lastSyncAt,
    bool? isSyncing,
    String? syncError,
  }) {
    return AppModeState(
      currentMode: currentMode ?? this.currentMode,
      hasUnsynced: hasUnsynced ?? this.hasUnsynced,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError ?? this.syncError,
    );
  }
}
