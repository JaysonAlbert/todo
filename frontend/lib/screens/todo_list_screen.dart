import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/providers/auth_provider.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/widgets/add_todo_form.dart';
import 'package:todo/widgets/app_mode_widget.dart';
import 'package:todo/widgets/todo_item_widget.dart';
import 'package:todo/utils/constants.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  void initState() {
    super.initState();
    // Load todos when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final todoProvider = context.read<TodoProvider>();

      // If user is in offline mode from login, ensure TodoProvider is in offline mode
      if (authProvider.isOfflineMode && todoProvider.isOnlineMode) {
        todoProvider.switchToOfflineMode();
      } else {
        todoProvider.loadTodos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          return Row(
            children: [
              // Left Sidebar
              _buildSidebar(context, todoProvider),

              // Divider
              Container(width: 1, color: AppColors.divider),

              // Main Content Area
              Expanded(child: _buildMainContent(context, todoProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, TodoProvider todoProvider) {
    return Container(
      width: AppSizes.sidebarWidth,
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.appTitle, style: AppTextStyles.heading3),
                Text(
                  '${todoProvider.totalCount} ${todoProvider.totalCount == 1 ? 'todo' : 'todos'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // User Profile Section
          _buildUserProfileSection(context),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            height: 1,
            color: AppColors.divider,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Mode Section
                  const AppModeWidget(),

                  const SizedBox(height: AppSizes.paddingXL),

                  // Quick Add Section
                  _buildQuickAddSection(todoProvider),

                  const SizedBox(height: AppSizes.paddingXL),

                  // Filters Section
                  _buildFiltersSection(todoProvider),

                  const SizedBox(height: AppSizes.paddingXL),

                  // Statistics Section
                  _buildStatisticsSection(todoProvider),

                  // Add bottom padding
                  const SizedBox(height: AppSizes.paddingL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(TodoProvider todoProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.quickAdd, style: AppTextStyles.sidebarTitle),
        const SizedBox(height: AppSizes.paddingM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AddTodoForm(
            onAddTodo: (title, priority, dueDate) async {
              await todoProvider.addTodo(title, priority, dueDate: dueDate);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(TodoProvider todoProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filters', style: AppTextStyles.sidebarTitle),
        const SizedBox(height: AppSizes.paddingM),
        _buildFilterOption(
          'All Tasks',
          todoProvider.totalCount,
          TodoFilter.all,
          todoProvider.currentFilter,
          Icons.list_rounded,
          () => todoProvider.setFilter(TodoFilter.all),
        ),
        const SizedBox(height: AppSizes.paddingS),
        _buildFilterOption(
          'Active',
          todoProvider.activeCount,
          TodoFilter.active,
          todoProvider.currentFilter,
          Icons.radio_button_unchecked_rounded,
          () => todoProvider.setFilter(TodoFilter.active),
        ),
        const SizedBox(height: AppSizes.paddingS),
        _buildFilterOption(
          'Completed',
          todoProvider.completedCount,
          TodoFilter.completed,
          todoProvider.currentFilter,
          Icons.check_circle_outline_rounded,
          () => todoProvider.setFilter(TodoFilter.completed),
        ),

        if (todoProvider.completedCount > 0) ...[
          const SizedBox(height: AppSizes.paddingL),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showClearCompletedDialog(context, todoProvider),
              icon: const Icon(Icons.clear_all_rounded, size: AppSizes.iconS),
              label: Text(AppStrings.clearCompleted),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterOption(
    String title,
    int count,
    TodoFilter filter,
    TodoFilter currentFilter,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isSelected = filter == currentFilter;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconS,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceSecondary,
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.onSurfaceSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(TodoProvider todoProvider) {
    final completionRate = todoProvider.totalCount > 0
        ? (todoProvider.completedCount / todoProvider.totalCount * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: AppTextStyles.sidebarTitle),
        const SizedBox(height: AppSizes.paddingM),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatItem(
                'Total Tasks',
                '${todoProvider.totalCount}',
                Icons.assignment_outlined,
              ),
              const SizedBox(height: AppSizes.paddingS),
              _buildStatItem(
                'Active',
                '${todoProvider.activeCount}',
                Icons.pending_outlined,
              ),
              const SizedBox(height: AppSizes.paddingS),
              _buildStatItem(
                'Completed',
                '${todoProvider.completedCount}',
                Icons.check_circle_outline,
              ),
              const SizedBox(height: AppSizes.paddingS),
              _buildStatItem(
                'Completion Rate',
                '$completionRate%',
                Icons.trending_up_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconS, color: AppColors.onSurfaceSecondary),
        const SizedBox(width: AppSizes.paddingS),
        Expanded(child: Text(label, style: AppTextStyles.body2)),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, TodoProvider todoProvider) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.todosSection, style: AppTextStyles.heading3),
              Text(
                _getFilterDescription(todoProvider.currentFilter, todoProvider),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),

        // Divider
        Container(height: 1, color: AppColors.divider),

        // Todo List
        Expanded(child: _buildTodoList(context, todoProvider)),
      ],
    );
  }

  String _getFilterDescription(TodoFilter filter, TodoProvider provider) {
    switch (filter) {
      case TodoFilter.all:
        return 'Showing all ${provider.totalCount} ${provider.totalCount == 1 ? 'todo' : 'todos'}';
      case TodoFilter.active:
        return 'Showing ${provider.activeCount} active ${provider.activeCount == 1 ? 'todo' : 'todos'}';
      case TodoFilter.completed:
        return 'Showing ${provider.completedCount} completed ${provider.completedCount == 1 ? 'todo' : 'todos'}';
    }
  }

  Widget _buildTodoList(BuildContext context, TodoProvider todoProvider) {
    if (todoProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final todos = todoProvider.filteredTodos;

    if (todos.isEmpty) {
      return _buildEmptyState(todoProvider.currentFilter);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        itemCount: todos.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.paddingS),
        itemBuilder: (context, index) {
          final todo = todos[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TodoItemWidget(
              todo: todo,
              onToggle: () => todoProvider.toggleTodo(todo.id),
              onEdit: () => _showEditTodoDialog(context, todoProvider, todo),
              onDelete: () =>
                  _showDeleteTodoDialog(context, todoProvider, todo),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(TodoFilter filter) {
    String message;
    IconData icon;

    switch (filter) {
      case TodoFilter.active:
        message = AppStrings.noActiveTodos;
        icon = Icons.check_circle_outline_rounded;
        break;
      case TodoFilter.completed:
        message = AppStrings.noCompletedTodos;
        icon = Icons.assignment_turned_in_outlined;
        break;
      case TodoFilter.all:
        message = AppStrings.noTodos;
        icon = Icons.add_task_rounded;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.onSurfaceSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.paddingL),
          Text(
            message,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTodoDialog(
    BuildContext context,
    TodoProvider todoProvider,
    TodoItem todo,
  ) async {
    final result = await showDialog<TodoItem>(
      context: context,
      builder: (context) => _EditTodoDialog(todo: todo),
    );

    if (result != null) {
      await todoProvider.updateTodo(result);
    }
  }

  Future<void> _showDeleteTodoDialog(
    BuildContext context,
    TodoProvider todoProvider,
    TodoItem todo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text(
          AppStrings.confirmDeleteMessage,
          style: AppTextStyles.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await todoProvider.deleteTodo(todo.id);
    }
  }

  Future<void> _showClearCompletedDialog(
    BuildContext context,
    TodoProvider todoProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCompleted),
        content: Text(
          'Are you sure you want to clear all completed todos?',
          style: AppTextStyles.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.clearCompleted),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await todoProvider.clearCompleted();
    }
  }

  Widget _buildUserProfileSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.all(AppSizes.paddingM),
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: authProvider.isOfflineMode
              ? _buildOfflineUserSection(context, authProvider)
              : _buildAuthenticatedUserSection(context, authProvider),
        );
      },
    );
  }

  Widget _buildOfflineUserSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        // Top row with avatar and user info
        Row(
          children: [
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.orange.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: AppSizes.paddingS),

            // User Info
            Expanded(
              child: Text(
                'Offline User',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Login Button
            authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      child: InkWell(
                        onTap: () => _handleLogin(context, authProvider),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.login,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),

        const SizedBox(height: AppSizes.paddingXS),

        // Bottom row with description
        Row(
          children: [
            const SizedBox(width: 48), // Space to align with text above
            Expanded(
              child: Text(
                'Tap to sync with cloud',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthenticatedUserSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Row(
      children: [
        // User Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),

        const SizedBox(width: AppSizes.paddingM),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.userName ?? 'User',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (authProvider.userEmail != null)
                Text(
                  authProvider.userEmail!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // Sign Out Button
        Container(
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: InkWell(
              onTap: authProvider.isLoading
                  ? null
                  : () => _handleSignOut(context, authProvider),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login'),
        content: const Text(
          'Do you want to go to the login screen to sign in with your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }

  Future<void> _handleSignOut(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error,),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }
}

class _EditTodoDialog extends StatefulWidget {
  final TodoItem todo;

  const _EditTodoDialog({required this.todo});

  @override
  State<_EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<_EditTodoDialog> {
  late TextEditingController _titleController;
  late Priority _selectedPriority;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _selectedPriority = widget.todo.priority;
    _selectedDueDate = widget.todo.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.editTodo),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Todo Title',
                hintText: 'Enter todo title',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSizes.paddingM),
            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              decoration: const InputDecoration(labelText: AppStrings.priority),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Text(priority.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (priority) {
                if (priority != null) {
                  setState(() => _selectedPriority = priority);
                }
              },
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDueDate == null
                        ? 'No due date'
                        : 'Due: ${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}',
                    style: AppTextStyles.body1,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedDueDate = date);
                    }
                  },
                  child: Text(_selectedDueDate == null ? 'Set Date' : 'Change'),
                ),
                if (_selectedDueDate != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDueDate = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () {
                  final updatedTodo = widget.todo.copyWith(
                    title: _titleController.text.trim(),
                    priority: _selectedPriority,
                    dueDate: _selectedDueDate,
                  );
                  Navigator.of(context).pop(updatedTodo);
                },
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
