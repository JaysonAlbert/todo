import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/models/app_mode.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/providers/auth_provider.dart';

import 'package:todo/utils/constants.dart';

class AppModeWidget extends StatelessWidget {
  const AppModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        border: Border.all(
              color: todoProvider.isOfflineMode 
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Status Header
              Row(
                children: [
                  Icon(
                    todoProvider.isOfflineMode
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    size: AppSizes.iconS,
                    color: todoProvider.isOfflineMode
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todoProvider.currentMode.displayName,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: todoProvider.isOfflineMode
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        Text(
                          todoProvider.currentMode.description,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingM),

              // Connection Status
              Row(
                children: [
                  Icon(
                    todoProvider.isConnected
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    size: AppSizes.iconXS,
                    color: todoProvider.isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Text(
                    todoProvider.isConnected ? 'Connected' : 'No Connection',
                    style: AppTextStyles.caption.copyWith(
                      color: todoProvider.isConnected
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),

              // Unsynced Changes Indicator
              if (todoProvider.hasUnsynced) ...[
                const SizedBox(height: AppSizes.paddingS),
                Row(
                  children: [
                    Icon(
                      Icons.sync_problem_rounded,
                      size: AppSizes.iconXS,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Text(
                      '${todoProvider.unsyncedCount} unsynced changes',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],

              // Sync Status
              if (todoProvider.appModeState.isSyncing) ...[
                const SizedBox(height: AppSizes.paddingS),
                Row(
                  children: [
                    SizedBox(
                      width: AppSizes.iconXS,
                      height: AppSizes.iconXS,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Text('Syncing...', style: AppTextStyles.caption),
                  ],
                ),
              ],

              // Last Sync Time
              if (todoProvider.appModeState.lastSyncAt != null) ...[
                const SizedBox(height: AppSizes.paddingS),
                Text(
                  'Last sync: ${_formatLastSync(todoProvider.appModeState.lastSyncAt!)}',
                  style: AppTextStyles.caption,
                ),
              ],

              const SizedBox(height: AppSizes.paddingM),

              // Mode Switch Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode:',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppMode>(
                      segments: const [
                        ButtonSegment<AppMode>(
                          value: AppMode.offline,
                          label: Text('Offline'),
                          icon: Icon(Icons.cloud_off_rounded, size: 16),
                        ),
                        ButtonSegment<AppMode>(
                          value: AppMode.online,
                          label: Text('Online'),
                          icon: Icon(Icons.cloud_done_rounded, size: 16),
                        ),
                      ],
                      selected: {todoProvider.currentMode},
                      onSelectionChanged: (Set<AppMode> newSelection) {
                        _switchMode(context, todoProvider, newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),

              // Sync Controls (only show when in online mode)
              if (todoProvider.isOnlineMode) ...[
                const SizedBox(height: AppSizes.paddingM),
                const Divider(),
                const SizedBox(height: AppSizes.paddingM),

                Text(
                  'Sync:',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingS),

                // Sync Buttons
                Column(
                  children: [
                    // Main Sync Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            todoProvider.isConnected &&
                                !todoProvider.appModeState.isSyncing
                            ? () => _syncTodos(context, todoProvider)
                            : null,
                        icon: Icon(Icons.sync_rounded, size: AppSizes.iconS),
                        label: Text(
                          todoProvider.hasUnsynced ? 'Sync Changes' : 'Sync',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                      ),
                    ),

                    // Additional Sync Options
                    const SizedBox(height: AppSizes.paddingS),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                todoProvider.isConnected &&
                                    !todoProvider.appModeState.isSyncing
                                ? () => _syncFromServer(context, todoProvider)
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_download_rounded, size: 16),
                                const SizedBox(height: 2),
                                Text(
                                  'From Server',
                                  style: TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                todoProvider.isConnected &&
                                    !todoProvider.appModeState.isSyncing
                                ? () => _syncToServer(context, todoProvider)
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_upload_rounded, size: 16),
                                const SizedBox(height: 2),
                                Text(
                                  'To Server',
                                  style: TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _switchMode(
    BuildContext context,
    TodoProvider provider,
    AppMode newMode,
  ) async {
    if (newMode == provider.currentMode) return;

    if (newMode == AppMode.online && !provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot switch to online mode: No internet connection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is authenticated when trying to switch to online mode
    if (newMode == AppMode.online) {
      final authProvider = context.read<AuthProvider>();
      
      if (authProvider.isOfflineMode) {
        final shouldLogin = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Login Required',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Content
                  Text(
                    'You need to be signed in to use online mode. Would you like to go to the login screen?',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.onSurfaceSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: AppColors.onSurfaceSecondary.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.onSurfaceSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(
                            Icons.login,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            'Go to Login',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (shouldLogin == true) {
          // Sign out to go to login screen
          await authProvider.signOut();
        }
        return;
      }
    }

    // Warn user about unsynced changes when switching to online mode
    if (newMode == AppMode.online && provider.hasUnsynced) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsynced Changes'),
          content: Text(
            'You have ${provider.unsyncedCount} unsynced changes. '
            'Switching to online mode will sync them with the server. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Switch & Sync'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      if (newMode == AppMode.offline) {
        await provider.switchToOfflineMode();
      } else {
        await provider.switchToOnlineMode();

        // Auto-sync if there are unsynced changes
        if (provider.hasUnsynced) {
          await provider.syncTodos();
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${newMode.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _syncTodos(BuildContext context, TodoProvider provider) async {
    try {
      await provider.syncTodos();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _syncFromServer(BuildContext context, TodoProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync from Server'),
        content: const Text(
          'This will download all todos from the server and replace your local data. '
          'Any unsynced local changes will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Replace Local Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.syncFromServer();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced from server successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync from server failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _syncToServer(BuildContext context, TodoProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync to Server'),
        content: const Text(
          'This will upload all your local todos to the server. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upload to Server'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.syncToServer();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced to server successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync to server failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
