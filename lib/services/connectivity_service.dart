import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service to monitor internet connectivity in real-time
/// 
/// Features:
/// - Real-time connection monitoring
/// - 3-second debounce to prevent flickering (reduced from 5)
/// - Actual internet verification (not just WiFi connected)
/// - Stream-based updates for reactive UI
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  
  // Stream controller for connection status
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  Timer? _debounceTimer;
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  
  /// Initialize the connectivity service
  Future<void> initialize() async {
    // Check initial connection
    await _checkConnection();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    
    // ✅ NEW: Periodic check every 10 seconds as backup
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnection(),
    );
    
    if (kDebugMode) {
      debugPrint('✅ ConnectivityService initialized');
    }
  }
  
  /// Handle connectivity changes with debouncing
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (kDebugMode) {
      debugPrint('📡 Connectivity changed: $results');
    }
    
    // Cancel existing timer
    _debounceTimer?.cancel();
    
    // ✅ REDUCED: Wait 3 seconds before checking (was 5)
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      await _checkConnection();
    });
  }
  
  /// Check actual internet connection (not just WiFi/mobile data)
  Future<void> _checkConnection() async {
    try {
      // Check if device has connectivity
      final results = await _connectivity.checkConnectivity();
      
      if (kDebugMode) {
        debugPrint('🔍 Checking connection: $results');
      }
      
      // If no connectivity at all
      if (results.contains(ConnectivityResult.none)) {
        if (kDebugMode) {
          debugPrint('❌ No connectivity detected');
        }
        _updateConnectionStatus(false);
        return;
      }
      
      // ✅ IMPROVED: Try multiple endpoints for reliability
      bool hasInternet = false;
      
      try {
        // Try Google first
        final response = await http.get(
          Uri.parse('https://www.google.com'),
        ).timeout(
          const Duration(seconds: 5),
        );
        
        hasInternet = response.statusCode == 200;
        if (kDebugMode) {
          debugPrint('✅ Google ping: ${response.statusCode}');
        }
      } catch (e) {
       if (kDebugMode) {
          debugPrint('⚠️ Google ping failed: $e');
        }
        // Try Cloudflare as backup
        try {
          final response2 = await http.get(
            Uri.parse('https://1.1.1.1'),
          ).timeout(
            const Duration(seconds: 5),
          );
          
          hasInternet = response2.statusCode == 200;
          if (kDebugMode) {
            debugPrint('✅ Cloudflare ping: ${response2.statusCode}');
          }
        } catch (e2) {
         if (kDebugMode) {
            debugPrint('⚠️ Cloudflare ping failed: $e2');
          }
          hasInternet = false;
        }
      }
      
      _updateConnectionStatus(hasInternet);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking connection: $e');
      }
      _updateConnectionStatus(false);
    }
  }
  
  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(isConnected);
      
     if (kDebugMode) {
        debugPrint(
          '🌐 Connection status changed: ${isConnected ? "ONLINE" : "OFFLINE"}',
        );
      }
    } else {
      if (kDebugMode) {
        debugPrint('ℹ️ Connection status unchanged: ${isConnected ? "ONLINE" : "OFFLINE"}');
      }
    }
  }
  
  /// Manually retry connection check
  Future<void> retry() async {
    debugPrint('🔄 Manual retry requested...');
    await _checkConnection();
  }
  
  /// Dispose the service
  void dispose() {
    _debounceTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
    if (kDebugMode) {
      debugPrint('🗑️ ConnectivityService disposed');
    }
  }
}