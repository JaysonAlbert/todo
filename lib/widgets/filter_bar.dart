import 'package:flutter/material.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/utils/constants.dart';

class FilterBar extends StatelessWidget {
  final TodoFilter currentFilter;
  final Function(TodoFilter) onFilterChanged;
  final int totalCount;
  final int activeCount;
  final int completedCount;
  final VoidCallback? onClearCompleted;

  const FilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    this.onClearCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            // Filter chips
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSizes.paddingS,
                    children: [
                      _FilterChip(
                        label: AppStrings.filterAll,
                        count: totalCount,
                        isSelected: currentFilter == TodoFilter.all,
                        onTap: () => onFilterChanged(TodoFilter.all),
                      ),
                      _FilterChip(
                        label: AppStrings.filterActive,
                        count: activeCount,
                        isSelected: currentFilter == TodoFilter.active,
                        onTap: () => onFilterChanged(TodoFilter.active),
                      ),
                      _FilterChip(
                        label: AppStrings.filterCompleted,
                        count: completedCount,
                        isSelected: currentFilter == TodoFilter.completed,
                        onTap: () => onFilterChanged(TodoFilter.completed),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Clear completed button
            if (completedCount > 0) ...[
              const SizedBox(height: AppSizes.paddingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClearCompleted,
                  icon: const Icon(Icons.clear_all),
                  label: Text('${AppStrings.clearCompleted} ($completedCount)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: AppSizes.paddingXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingS,
              vertical: AppSizes.paddingXS,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surface
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Text(
              count.toString(),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      showCheckmark: false,
      labelStyle: AppTextStyles.body2.copyWith(
        color: isSelected ? AppColors.primary : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
