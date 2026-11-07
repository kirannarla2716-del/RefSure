// lib/services/tour_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages whether the app tour has been seen by the user.
class TourService {
  static const _key = 'app_tour_seen';

  /// Fires whenever the tour is reset so live widgets can re-check state.
  static final resetNotifier = ValueNotifier<int>(0);

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    // Notify any live listeners (e.g. _AppTourCard on Home screen)
    resetNotifier.value++;
  }
}
