import 'package:flutter/foundation.dart';
import 'package:todo/services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  offlineMode,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.initial;
  String? _error;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthProvider(this._authService);

  // Getters
  AuthState get state => _state;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isOfflineMode => _state == AuthState.offlineMode;
  bool get canAccessApp =>
      _state == AuthState.authenticated || _state == AuthState.offlineMode;
  String? get userName =>
      _userData?['name'] ??
      (_state == AuthState.offlineMode ? 'Offline User' : null);
  String? get userEmail => _userData?['email'];

  // Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _userData = await _authService.getUserData();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _setError('Failed to initialize authentication');
      _setState(AuthState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithApple();

      if (result.isSuccess && result.data != null) {
        _userData = result.data!['user'];
        _setState(AuthState.authenticated);

        debugPrint('Sign-in successful for user: ${_userData?['name']}');
        return true;
      } else if (result.isCanceled) {
        // User canceled sign-in, don't show error
        debugPrint('User canceled Apple Sign-In');
        _setState(AuthState.unauthenticated);
        return false;
      } else {
        _setError(result.error ?? 'Apple Sign-In failed');
        _setState(AuthState.error);
        return false;
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _setError('Apple Sign-In failed: ${e.toString()}');
      _setState(AuthState.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _userData = null;
      _setState(AuthState.unauthenticated);

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign-out error: $e');
      _setError('Failed to sign out');
      _setState(AuthState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Enter offline mode
  Future<void> enterOfflineMode() async {
    _setLoading(true);
    _clearError();

    try {
      // Clear any existing auth data
      await _authService.signOut();
      _userData = null;
      _setState(AuthState.offlineMode);

      debugPrint('User entered offline mode');
    } catch (e) {
      debugPrint('Offline mode entry error: $e');
      _setError('Failed to enter offline mode');
      _setState(AuthState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (!isAuthenticated) return;

    try {
      _userData = await _authService.getUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh user data: $e');
    }
  }

  // Check if user needs to re-authenticate
  Future<bool> checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (!isAuth && isAuthenticated) {
        // User was authenticated but token is no longer valid
        await signOut();
        return false;
      }
      return isAuth;
    } catch (e) {
      debugPrint('Auth status check failed: $e');
      return false;
    }
  }

  // Get the AuthService instance for direct API calls
  AuthService get authService => _authService;

  // Set authenticated state directly (used for Apple callback processing)
  void setAuthenticatedState(Map<String, dynamic> userData) {
    _userData = userData;
    _setState(AuthState.authenticated);
    debugPrint('Authentication state set for user: ${userData['name']}');
  }

  // Private helper methods
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
