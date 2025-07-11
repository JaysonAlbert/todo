import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:todo/utils/constants.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  final Dio _dio;
  final Dio _refreshDio; // Separate instance for token refresh
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false; // Prevent multiple simultaneous refreshes

  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppUrls.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
      _refreshDio = Dio(
        BaseOptions(
          baseUrl: AppUrls.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
      _storage = const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor to add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors by attempting to refresh the token
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            debugPrint('Received 401, attempting token refresh...');
            final refreshed = await _refreshTokenIfNeeded();
            if (refreshed) {
              debugPrint('Token refreshed successfully, retrying request...');
              // Retry the original request with new token
              final newToken = await getAccessToken();
              if (newToken != null) {
                final retryOptions = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $newToken',
                  },
                );

                try {
                  final clonedRequest = await _dio.request(
                    error.requestOptions.path,
                    options: retryOptions,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(clonedRequest);
                } catch (retryError) {
                  debugPrint('Retry request failed: $retryError');
                  return handler.next(error);
                }
              }
            } else {
              debugPrint('Token refresh failed, clearing auth data...');
              await signOut(); // Clear invalid tokens
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Apple Sign-In Methods

  /// Check if Apple Sign-In is supported on the current platform
  bool get isAppleSignInSupported {
    if (kIsWeb) {
      return true; // Web is supported with proper configuration
    }

    // Apple Sign-In is only supported on iOS and macOS
    if (!kIsWeb) {
      try {
        return Platform.isIOS || Platform.isMacOS;
      } catch (e) {
        // If Platform check fails, assume unsupported
        return false;
      }
    }

    return false;
  }

  Future<LoginResult> signInWithApple() async {
    try {
      // First check if Apple Sign-In is supported on this platform
      if (!isAppleSignInSupported) {
        return LoginResult.failure(
          'Apple Sign-In is not supported on this platform. Please use offline mode or try a different device.',
        );
      }

      // Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        return LoginResult.failure(
          'Apple Sign-In is not available on this device',
        );
      }

      // Special handling for web platform
      if (kIsWeb) {
        debugPrint('Attempting Apple Sign-In on web platform');

        // For local development, provide a fallback
        if (AppUrls.appleServiceId == 'com.yourcompany.yourapp.service') {
          debugPrint('Apple Sign-In web not configured for production use');
          return LoginResult.failure(
            'Apple Sign-In web is not configured. Please set up your Apple Service ID or use a different sign-in method.',
          );
        }

        // For web, we need to provide additional configuration
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: AppUrls.appleServiceId,
            redirectUri: Uri.parse(AppUrls.appleRedirectUri),
          ),
        );

        debugPrint(
          'Apple Sign-In successful on web. UserID: ${credential.userIdentifier}',
        );

        // Send the authorization code to our backend
        final loginResponse = await _authenticateWithBackend(credential);

        if (loginResponse != null) {
          // Store tokens and user data
          await _storeAuthData(loginResponse);
          return LoginResult.success(loginResponse);
        } else {
          return LoginResult.failure('Failed to authenticate with backend');
        }
      } else {
        // Native platform handling (iOS, macOS)
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        debugPrint(
          'Apple Sign-In successful. UserID: ${credential.userIdentifier}',
        );

        // Send the authorization code to our backend
        final loginResponse = await _authenticateWithBackend(credential);

        if (loginResponse != null) {
          // Store tokens and user data
          await _storeAuthData(loginResponse);
          return LoginResult.success(loginResponse);
        } else {
          return LoginResult.failure('Failed to authenticate with backend');
        }
      }
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');

      // Handle platform-specific errors
      if (e.toString().contains('MissingPluginException')) {
        return LoginResult.failure(
          'Apple Sign-In is not supported on this platform. Please use offline mode or try a different device.',
        );
      }

      // Check if user canceled the sign-in
      final errorString = e.toString();
      if (errorString.contains('AuthorizationErrorCode.canceled') ||
          errorString.contains('error 1001')) {
        debugPrint('User canceled Apple Sign-In');
        return LoginResult.canceled();
      }

      // Handle specific web errors
      if (kIsWeb && errorString.contains('TypeErrorImpl')) {
        debugPrint('Web JavaScript interop error detected');
        return LoginResult.failure(
          'Apple Sign-In is not properly configured for web. Please set up your Apple Service ID or use offline mode.',
        );
      }

      return LoginResult.failure('Apple Sign-In failed: ${e.toString()}');
    }
  }

  // Process Apple Sign-In callback from URL (for web)
  Future<LoginResult> processAppleCallback(String code, String? state) async {
    try {
      debugPrint('Processing Apple callback with authorization code');

      final response = await _dio.post(
        '/auth/apple/callback',
        data: {'code': code, 'state': state},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final loginData = response.data['data'];
        await _storeAuthData(loginData);
        return LoginResult.success(loginData);
      } else {
        return LoginResult.failure('Failed to authenticate with backend');
      }
    } on DioException catch (e) {
      debugPrint('Apple callback processing error: ${e.response?.data}');
      return LoginResult.failure('Authentication failed: ${e.message}');
    } catch (e) {
      debugPrint('Apple callback processing error: $e');
      return LoginResult.failure('Authentication failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> _authenticateWithBackend(
    AuthorizationCredentialAppleID credential,
  ) async {
    try {
      // Prepare user data if available (only on first sign-in)
      Map<String, dynamic>? userData;
      if (credential.givenName != null || credential.familyName != null) {
        userData = {
          'name': {
            'firstName': credential.givenName ?? '',
            'lastName': credential.familyName ?? '',
          },
        };
      }

      final response = await _dio.post(
        '/auth/apple/callback',
        data: {
          'code': credential.authorizationCode,
          'user': userData != null ? jsonEncode(userData) : null,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Backend authentication error: ${e.response?.data}');
      return null;
    }
  }

  // Token Management

  Future<void> _storeAuthData(Map<String, dynamic> loginData) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: loginData['access_token']),
      _storage.write(key: _refreshTokenKey, value: loginData['refresh_token']),
      _storage.write(key: _userDataKey, value: jsonEncode(loginData['user'])),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<bool> _refreshTokenIfNeeded() async {
    if (_isRefreshing) {
      debugPrint('Token refresh already in progress...');
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return false;
      }

      debugPrint('Attempting to refresh token...');

      // Use separate Dio instance to avoid interceptor loops
      final response = await _refreshDio.post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('Token refresh API call successful');
        await _storeAuthData(response.data['data']);
        return true;
      } else {
        debugPrint('Token refresh API call failed: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh failed with error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> signOut() async {
    try {
      // Reset refresh flag
      _isRefreshing = false;

      // Clear stored tokens and user data
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userDataKey),
      ]);

      debugPrint('Sign out completed successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // API Methods for making authenticated requests

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

// Result classes for better error handling

class LoginResult {
  final bool isSuccess;
  final bool isCanceled;
  final String? error;
  final Map<String, dynamic>? data;

  LoginResult._(this.isSuccess, this.isCanceled, this.error, this.data);

  factory LoginResult.success(Map<String, dynamic> data) {
    return LoginResult._(true, false, null, data);
  }

  factory LoginResult.failure(String error) {
    return LoginResult._(false, false, error, null);
  }

  factory LoginResult.canceled() {
    return LoginResult._(false, true, null, null);
  }
}
