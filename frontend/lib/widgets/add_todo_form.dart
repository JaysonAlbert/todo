import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo/models/priority.dart';
import 'package:todo/utils/constants.dart';

class AddTodoForm extends StatefulWidget {
  final Function(String title, Priority priority, DateTime? dueDate) onAddTodo;

  const AddTodoForm({super.key, required this.onAddTodo});

  @override
  State<AddTodoForm> createState() => _AddTodoFormState();
}

class _AddTodoFormState extends State<AddTodoForm> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onAddTodo(
        _titleController.text.trim(),
        _selectedPriority,
        _selectedDueDate,
      );

      // Reset form
      _titleController.clear();
      _selectedPriority = Priority.medium;
      _selectedDueDate = null;

      // Unfocus to dismiss keyboard
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDueDate = selectedDate;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: AppStrings.addTodoHint,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _addTodo(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a todo title';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.paddingM),

            // Priority selector
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: AppSizes.iconS,
                  color: AppColors.onSurfaceSecondary,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Text(AppStrings.priority, style: AppTextStyles.body2),
                const SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: DropdownButtonFormField<Priority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingS,
                        vertical: 8,
                      ),
                    ),
                    items: Priority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.getPriorityColor(priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                priority.displayName,
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (priority) {
                      if (priority != null) {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.paddingM),

            // Due date selector
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconS,
                  color: AppColors.onSurfaceSecondary,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: Text(AppStrings.dueDate, style: AppTextStyles.body2),
                ),
                if (_selectedDueDate != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceSecondary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 10,
                          color: AppColors.onSurfaceSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('MMM d').format(_selectedDueDate!),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: _clearDueDate,
                          child: Icon(
                            Icons.close,
                            size: 10,
                            color: AppColors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton(
                  onPressed: _selectDueDate,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    _selectedDueDate == null ? 'Set' : 'Edit',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.paddingL),

            // Add button
            FilledButton.icon(
              onPressed: _isLoading ? null : _addTodo,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: AppSizes.iconS),
              label: Text(
                _isLoading ? 'Adding...' : AppStrings.addTodoButton,
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
