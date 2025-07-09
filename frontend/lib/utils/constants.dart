import 'package:flutter/material.dart';
import 'package:todo/models/priority.dart';

class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0056CC);
  static const Color onPrimary = Colors.white;
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF9F9F9);
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color onSurfaceSecondary = Color(0xFF8E8E93);
  static const Color divider = Color(0xFFE5E5EA);
  static const Color sidebarBackground = Color(0xFFFAFAFA);

  // Priority colors
  static const Color priorityHigh = Color(0xFFFF3B30);
  static const Color priorityMedium = Color(0xFFFF9500);
  static const Color priorityLow = Color(0xFF8E8E93);

  static Color getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return priorityHigh;
      case Priority.medium:
        return priorityMedium;
      case Priority.low:
        return priorityLow;
    }
  }
}

class AppSizes {
  static const double paddingXS = 6.0;
  static const double paddingS = 12.0;
  static const double paddingM = 20.0;
  static const double paddingL = 32.0;
  static const double paddingXL = 48.0;

  static const double radiusS = 6.0;
  static const double radiusM = 12.0;
  static const double radiusL = 20.0;

  static const double iconXS = 14.0;
  static const double iconS = 18.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;

  static const double buttonHeight = 44.0;
  static const double inputHeight = 44.0;

  static const double sidebarWidth = 320.0;
  static const double maxContentWidth = 1200.0;
  static const double minContentWidth = 800.0;
  static const double todoItemHeight = 72.0;
  static const double headerHeight = 80.0;
}

class AppStrings {
  static const String appTitle = 'Todo';
  static const String addTodoHint = 'Add a new todo...';
  static const String addTodoButton = 'Add Todo';
  static const String editTodo = 'Edit Todo';
  static const String deleteTodo = 'Delete Todo';
  static const String markComplete = 'Mark Complete';
  static const String markIncomplete = 'Mark Incomplete';
  static const String noTodos =
      'No todos yet.\nClick "Add Todo" to get started!';
  static const String noActiveTodos =
      'All done! 🎉\nNo active todos remaining.';
  static const String noCompletedTodos = 'No completed todos yet.';
  static const String filterAll = 'All';
  static const String filterActive = 'Active';
  static const String filterCompleted = 'Completed';
  static const String clearCompleted = 'Clear Completed';
  static const String confirmDelete = 'Delete Todo';
  static const String confirmDeleteMessage =
      'Are you sure you want to delete this todo?';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String priority = 'Priority';
  static const String dueDate = 'Due Date';
  static const String overdue = 'Overdue';
  static const String todosSection = 'Your Todos';
  static const String quickAdd = 'Quick Add';
  static const String optional = 'Optional';
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 17,
    color: AppColors.onSurface,
    letterSpacing: -0.1,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 15,
    color: AppColors.onSurfaceSecondary,
    letterSpacing: -0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.onSurfaceSecondary,
    letterSpacing: -0.05,
  );

  static TextStyle strikethrough = body1.copyWith(
    decoration: TextDecoration.lineThrough,
    color: AppColors.onSurfaceSecondary,
  );

  static const TextStyle sidebarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading2,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      ),
    );
  }
}
