import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo/models/todo_item.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/utils/constants.dart';

class TodoItemWidget extends StatefulWidget {
  final TodoItem todo;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: widget.todo.isCompleted,
                      onChanged: widget.onToggle != null
                          ? (_) => widget.onToggle!()
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSizes.paddingM),

                  // Priority indicator
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.getPriorityColor(widget.todo.priority),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),

                  const SizedBox(width: AppSizes.paddingL),

                  // Todo content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.todo.title,
                          style: widget.todo.isCompleted
                              ? AppTextStyles.strikethrough.copyWith(
                                  fontSize: 17,
                                )
                              : AppTextStyles.body1.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSizes.paddingS),

                        // Metadata row
                        Wrap(
                          spacing: AppSizes.paddingS,
                          runSpacing: 4,
                          children: [
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getPriorityColor(
                                  widget.todo.priority,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                                widget.todo.priority.displayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.getPriorityColor(
                                    widget.todo.priority,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Due date
                            if (widget.todo.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingS,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.todo.isOverdue
                                      ? AppColors.error.withOpacity(0.1)
                                      : AppColors.onSurfaceSecondary
                                            .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusS,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 10,
                                      color: widget.todo.isOverdue
                                          ? AppColors.error
                                          : AppColors.onSurfaceSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _formatDueDate(widget.todo.dueDate!),
                                      style: AppTextStyles.caption.copyWith(
                                        color: widget.todo.isOverdue
                                            ? AppColors.error
                                            : AppColors.onSurfaceSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Created date
                            Text(
                              _formatCreatedDate(widget.todo.createdAt),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSizes.paddingM),

                  // Action buttons - shown on hover or always on mobile
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: AppSizes.iconS,
                          tooltip: AppStrings.editTodo,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline),
                          iconSize: AppSizes.iconS,
                          tooltip: AppStrings.deleteTodo,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.1),
                            foregroundColor: AppColors.error,
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly.isBefore(today)) {
      return AppStrings.overdue;
    } else if (dueDateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(dueDate);
    }
  }

  String _formatCreatedDate(DateTime createdAt) {
    return DateFormat('MMM d').format(createdAt);
  }
}
