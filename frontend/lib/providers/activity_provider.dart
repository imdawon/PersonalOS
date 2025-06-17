import 'package:flutter/material.dart';
import '../models/activity_session.dart';
import '../models/classification_request.dart';
import '../models/today_summary.dart';
import '../services/api_service.dart';

class ActivityProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ActivitySession> _unclassifiedSessions = [];
  List<TodaySummaryItem> _todaySummary = [];
  bool _isLoading = false;

  List<ActivitySession> get unclassifiedSessions => _unclassifiedSessions;
  List<TodaySummaryItem> get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;

  ActivityProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _unclassifiedSessions = await _apiService.getUnclassifiedSessions();
      _todaySummary = await _apiService.getTodaySummary();
    } catch (e) {
      // Handle error appropriately in a real app (e.g., show a snackbar)
      print("error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> classify(ClassificationRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.classifySession(request);
      // After classifying, refresh all data to update the UI
      await fetchAllData();
    } catch (e) {
      print(e);
      _isLoading = false;
      notifyListeners();
    }
  }
}