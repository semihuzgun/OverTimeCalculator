import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsManager {
  static bool _enabled = true;

  static bool get isEnabled => _enabled;

  static String get adUnitId => Platform.isAndroid
      ? "ca-app-pub-7094276259997672/9741478121"
      : "ca-app-pub-7094276259997672/2298606955";

  static Future<void> initialize() async {
    try {
      print('[AdsManager] Initializing MobileAds...');
      await MobileAds.instance.initialize();
      print('[AdsManager] MobileAds initialized successfully.');
    } catch (e) {
      _enabled = false;
      print('[AdsManager] Failed to initialize MobileAds: $e');
    }
  }
}