import 'package:flutter/material.dart';
import '../models/activity_session.dart';
import '../models/classification_request.dart';
import '../models/today_summary.dart';
import '../services/api_service.dart';

class ActivityProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ActivitySession> _rawUnclassifiedSessions = [];
  Map<String, List<ActivitySession>> _groupedUnclassifiedSessions = {};
  Map<String, int> _unclassifiedDurationPerApp = {}; // To display total duration per app

  List<TodaySummaryItem> _todaySummary = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, List<ActivitySession>> get groupedUnclassifiedSessions => _groupedUnclassifiedSessions;
  Map<String, int> get unclassifiedDurationPerApp => _unclassifiedDurationPerApp;
  List<TodaySummaryItem> get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ActivityProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rawUnclassifiedSessions = await _apiService.getUnclassifiedSessions();
      _groupAndSortSessions(); // New method to process
      _todaySummary = await _apiService.getTodaySummary();
    } catch (e) {
      print("Error fetching data: $e");
      _error = "Failed to load data. Please try again.";
      _rawUnclassifiedSessions = [];
      _groupedUnclassifiedSessions = {};
      _unclassifiedDurationPerApp = {};
      // _todaySummary can retain old data or be cleared
    }

    _isLoading = false;
    notifyListeners();
  }

  void _groupAndSortSessions() {
    _groupedUnclassifiedSessions = {};
    _unclassifiedDurationPerApp = {};

    for (var session in _rawUnclassifiedSessions) {
      _groupedUnclassifiedSessions.putIfAbsent(session.appName, () => []);
      _groupedUnclassifiedSessions[session.appName]!.add(session);

      _unclassifiedDurationPerApp.update(
        session.appName,
        (value) => value + session.duration,
        ifAbsent: () => session.duration,
      );
    }

    // Sort sessions within each app group by duration (descending)
    _groupedUnclassifiedSessions.forEach((appName, sessions) {
      sessions.sort((a, b) => b.duration.compareTo(a.duration));
    });

    // Sort app groups by total duration (descending)
    var sortedAppEntries = _unclassifiedDurationPerApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _unclassifiedDurationPerApp = Map.fromEntries(sortedAppEntries);
    
    // Ensure _groupedUnclassifiedSessions keys are ordered same as _unclassifiedDurationPerApp
    Map<String, List<ActivitySession>> tempGrouped = {};
    for(var appName in _unclassifiedDurationPerApp.keys){
        if(_groupedUnclassifiedSessions.containsKey(appName)){
            tempGrouped[appName] = _groupedUnclassifiedSessions[appName]!;
        }
    }
    _groupedUnclassifiedSessions = tempGrouped;
  }

  Future<void> classifySingleSession(ClassificationRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.classifySession(request);
      await fetchAllData(); // Refresh all data
    } catch (e) {
      print("Error classifying single session: $e");
      _error = "Failed to classify session.";
      // isLoading will be set to false in finally
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> classifyAppGroup(
    String appName,
    String userDefinedName,
    bool isHelpful,
    String goalContext,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sessionsToClassify = _groupedUnclassifiedSessions[appName] ?? [];
      if (sessionsToClassify.isEmpty) {
        throw Exception("No sessions to classify for app: $appName");
      }

      final batchRequest = BatchClassificationRequest(
        sessions: sessionsToClassify
            .map((s) => SessionIdentifier(
                  appName: s.appName,
                  windowTitle: s.windowTitle,
                ))
            .toList(),
        userDefinedName: userDefinedName,
        isHelpful: isHelpful,
        goalContext: goalContext,
      );

      await _apiService.classifySessionBatch(batchRequest);
      await fetchAllData(); // Refresh all data after the batch is done
    } catch (e) {
      print("Error classifying app group: $e");
      _error = "Failed to classify group.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}