import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppInfraService extends ChangeNotifier {
  // Connectivity
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Maintenance & Updates
  bool _isMaintenanceMode = false;
  bool get isMaintenanceMode => _isMaintenanceMode;

  bool _isForceUpdateRequired = false;
  bool get isForceUpdateRequired => _isForceUpdateRequired;

  final String _currentVersion = '2.4.0';
  String get currentVersion => _currentVersion;

  StreamSubscription? _configSubscription;
  StreamSubscription? _authSubscription;
  Timer? _connectivityPingTimer;

  AppInfraService() {
    try {
      // Only set up listeners if Firebase has been initialized (prevents crashes in widget tests)
      _initConnectivityListener();
      _initFirestoreConfigListener();
      _initAuthSessionListener();
    } catch (_) {}
  }

  void _initConnectivityListener() {
    try {
      _connectivityPingTimer = Timer.periodic(const Duration(seconds: 15), (_) => checkConnectivity());
      checkConnectivity();
    } catch (_) {}
  }

  Future<void> checkConnectivity() async {
    try {
      // Small query to verify database response / active web link
      await FirebaseFirestore.instance.collection('app_settings').limit(1).get(
            const GetOptions(source: Source.server),
          );
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // If we get permission-denied or not-found, we successfully reached the servers (we are online).
      // We only consider it offline if there's a connection/network failure.
      bool isNetworkFailure = errStr.contains('socketexception') ||
                             errStr.contains('failed host lookup') ||
                             errStr.contains('network-request-failed') ||
                             errStr.contains('unavailable') ||
                             errStr.contains('failed to fetch') ||
                             errStr.contains('connection-failed');
      
      if (errStr.contains('permission-denied') || errStr.contains('not-found') || errStr.contains('permission denied')) {
        isNetworkFailure = false;
      }

      if (isNetworkFailure) {
        if (_isOnline) {
          _isOnline = false;
          notifyListeners();
        }
      } else {
        if (!_isOnline) {
          _isOnline = true;
          notifyListeners();
        }
      }
    }
  }

  void _initFirestoreConfigListener() {
    try {
      _configSubscription = FirebaseFirestore.instance
          .collection('app_settings')
          .doc('app_config')
          .snapshots()
          .listen((snap) {
        if (snap.exists && snap.data() != null) {
          final d = snap.data()!;
          _isMaintenanceMode = d['maintenanceMode'] ?? false;
          
          final minVersion = d['minRequiredVersion'] ?? '2.4.0';
          _isForceUpdateRequired = _shouldForceUpdate(minVersion);
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  bool _shouldForceUpdate(String minVersion) {
    try {
      final currentParts = _currentVersion.split('.').map(int.parse).toList();
      final minParts = minVersion.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        if (currentParts[i] < minParts[i]) return true;
        if (currentParts[i] > minParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  void _initAuthSessionListener() {
    try {
      _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) {
        if (user == null) {
          // Clear secure variables if needed
        } else {
          // Force silent token refresh to keep session secure
          user.getIdToken(true).catchError((_) => null);
        }
      });
    } catch (_) {}
  }

  // ── Booking Conflict Protection ──────────────────────────────────────────
  Future<bool> lockBookingSlot(String serviceId, String slotId, String userId) async {
    final lockRef = FirebaseFirestore.instance.collection('slot_locks').doc('${serviceId}_$slotId');
    try {
      // Check if slot lock is active and hasn't expired (e.g. 10 minutes limit)
      final snap = await lockRef.get();
      if (snap.exists && snap.data() != null) {
        final d = snap.data()!;
        final expiresAt = (d['expiresAt'] as Timestamp).toDate();
        final activeUser = d['userId'] as String?;
        if (expiresAt.isAfter(DateTime.now()) && activeUser != userId) {
          return false; // Already locked by another transaction
        }
      }

      // Set new temporary lock
      await lockRef.set({
        'serviceId': serviceId,
        'slotId': slotId,
        'userId': userId,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> releaseBookingSlot(String serviceId, String slotId) async {
    try {
      await FirebaseFirestore.instance.collection('slot_locks').doc('${serviceId}_$slotId').delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _authSubscription?.cancel();
    _connectivityPingTimer?.cancel();
    super.dispose();
  }
}
