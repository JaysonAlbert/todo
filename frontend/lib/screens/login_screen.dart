import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:todo/providers/auth_provider.dart';
import 'package:todo/utils/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    _buildLogo(),

                    const SizedBox(height: AppSizes.paddingXL),

                    // Welcome text
                    _buildWelcomeText(),

                    const SizedBox(height: AppSizes.paddingXL),

                    // Apple Sign-In button
                    _buildAppleSignInButton(context, authProvider),

                    const SizedBox(height: AppSizes.paddingM),

                    // Error message
                    if (authProvider.error != null)
                      _buildErrorMessage(authProvider.error!),

                    const SizedBox(height: AppSizes.paddingXL),

                    // Features preview
                    _buildFeaturesPreview(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome to Todo',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingS),
        Text(
          'Organize your tasks and boost your productivity with our beautiful, intuitive todo app.',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.onSurfaceSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppleSignInButton(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Container(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: authProvider.isLoading
          ? Container(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Signing in...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SignInWithAppleButton(
              onPressed: () => _handleAppleSignIn(context, authProvider),
              style: SignInWithAppleButtonStyle.black,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              text: 'Continue with Apple ID',
            ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconS,
          ),
          const SizedBox(width: AppSizes.paddingS),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.body2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPreview() {
    return Column(
      children: [
        Text(
          'What you\'ll get:',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.paddingM),
        _buildFeatureItem(
          icon: Icons.sync,
          title: 'Sync Across Devices',
          description: 'Access your todos from anywhere',
        ),
        const SizedBox(height: AppSizes.paddingS),
        _buildFeatureItem(
          icon: Icons.priority_high,
          title: 'Priority Management',
          description: 'Organize tasks by importance',
        ),
        const SizedBox(height: AppSizes.paddingS),
        _buildFeatureItem(
          icon: Icons.calendar_today,
          title: 'Due Date Tracking',
          description: 'Never miss important deadlines',
        ),
        const SizedBox(height: AppSizes.paddingS),
        _buildFeatureItem(
          icon: Icons.security,
          title: 'Secure & Private',
          description: 'Your data is protected with Apple ID',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(icon, color: AppColors.primary, size: AppSizes.iconS),
        ),
        const SizedBox(width: AppSizes.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAppleSignIn(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    try {
      final success = await authProvider.signInWithApple();

      if (success && context.mounted) {
        // Navigation will be handled by the main app based on auth state
        // We could show a success message here if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${authProvider.userName ?? 'User'}!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      // Error handling is done in the AuthProvider
      // Additional UI feedback could be added here if needed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    }
  }
}
