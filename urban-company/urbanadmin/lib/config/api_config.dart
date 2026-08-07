import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  /// Change this to your live Render URL once deployed!
  /// Example: 'https://nexora-backend.onrender.com'
  static const String liveBackendUrl = 'https://nexora-94dt.onrender.com'; 

  static String get baseUrl {
    if (liveBackendUrl.isNotEmpty) {
      return liveBackendUrl;
    }
    
    // Fallbacks for local testing
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000'; // Android Emulator
    }
    return 'http://localhost:5000'; // Web or iOS Simulator
  }
}
