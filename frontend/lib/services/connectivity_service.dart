import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectionStatus { unknown, disconnected, connected }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isDisconnected => _connectionStatus == ConnectionStatus.disconnected;
  Stream<ConnectionStatus> get connectionStream =>
      _connectionStatusController.stream;

  /// Initialize the connectivity service and start listening to changes
  Future<void> initialize() async {
    try {
      // Get initial connectivity status
      final List<ConnectivityResult> connectivityResults = await _connectivity
          .checkConnectivity();
      _updateConnectionStatus(connectivityResults);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity service error: $error');
          _connectionStatus = ConnectionStatus.unknown;
          _connectionStatusController.add(_connectionStatus);
        },
      );

      debugPrint(
        'ConnectivityService initialized with status: $_connectionStatus',
      );
    } catch (e) {
      debugPrint('Failed to initialize ConnectivityService: $e');
      _connectionStatus = ConnectionStatus.unknown;
      _connectionStatusController.add(_connectionStatus);
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    final ConnectionStatus previousStatus = _connectionStatus;

    // Check if any of the connectivity results indicate a connection
    final bool hasConnection = connectivityResults.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    if (hasConnection) {
      _connectionStatus = ConnectionStatus.connected;
    } else if (connectivityResults.contains(ConnectivityResult.none)) {
      _connectionStatus = ConnectionStatus.disconnected;
    } else {
      _connectionStatus = ConnectionStatus.unknown;
    }

    // Only notify if status actually changed
    if (_connectionStatus != previousStatus) {
      debugPrint(
        'Connection status changed: $previousStatus -> $_connectionStatus',
      );
      _connectionStatusController.add(_connectionStatus);
    }
  }

  /// Check current connectivity status without listening to changes
  Future<ConnectionStatus> checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity
          .checkConnectivity();
      _updateConnectionStatus(connectivityResults);
      return _connectionStatus;
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return ConnectionStatus.unknown;
    }
  }

  /// Test if the device can actually reach the internet (not just connected to network)
  Future<bool> hasInternetConnection() async {
    try {
      // This is a simple connectivity check - you might want to ping your actual API endpoint
      final List<ConnectivityResult> connectivityResults = await _connectivity
          .checkConnectivity();

      final bool hasConnection = connectivityResults.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );

      return hasConnection;
    } catch (e) {
      debugPrint('Failed to check internet connection: $e');
      return false;
    }
  }

  /// Dispose of the connectivity service
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
