import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/ServerSyncService.dart';
import '../models/AuthState.dart';

class ConnectivityState {
  static final RxBool isOnline = true.obs;
  static final RxBool isSyncing = false.obs;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static final Connectivity _connectivity = Connectivity();

  static void initialize() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectivityStatus(results);
      },
    );
  }

  static Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      isOnline.value = false;
    }
  }

  static void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = isOnline.value;
    // Check if any connection type is available
    final hasConnection = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    isOnline.value = hasConnection;
    
    // If we just came online and user is logged in, trigger sync
    if (!wasOnline && isOnline.value && AuthState.isLoggedIn.value && !isSyncing.value) {
      _triggerSync();
    }
  }

  static Future<void> _triggerSync() async {
    if (isSyncing.value) return;
    
    isSyncing.value = true;
    try {
      debugPrint('Connectivity restored - syncing data to server...');
      await ServerSyncService.syncAllToServer();
      debugPrint('Data synced successfully after connectivity restored');
    } catch (e) {
      debugPrint('Error syncing after connectivity restored: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  // Manual connectivity check
  static Future<bool> checkConnectivity() async {
    try {
      await _checkConnectivity();
      return isOnline.value;
    } catch (e) {
      isOnline.value = false;
      return false;
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}
