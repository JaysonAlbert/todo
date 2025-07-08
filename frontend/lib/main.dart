import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/providers/auth_provider.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/screens/login_screen.dart';
import 'package:todo/screens/todo_list_screen.dart';
import 'package:todo/services/api_service.dart';
import 'package:todo/services/auth_service.dart';
import 'package:todo/services/storage_service.dart';
import 'package:todo/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final authService = AuthService();

  runApp(MyApp(storageService: storageService, authService: authService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (context) => TodoProvider(ApiService(authService)),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.state) {
          case AuthState.initial:
          case AuthState.loading:
            return const SplashScreen();

          case AuthState.authenticated:
            return const TodoListScreen();

          case AuthState.unauthenticated:
          case AuthState.error:
            return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
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
            ),

            const SizedBox(height: AppSizes.paddingL),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            const SizedBox(height: AppSizes.paddingM),

            // Loading text
            Text(
              'Loading...',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
