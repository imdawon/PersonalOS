import 'package:flutter/material.dart';
import '../models/activity_session.dart';
import '../models/classification_request.dart';
import '../models/today_summary.dart';
import '../models/logbook_models.dart';
import '../services/api_service.dart';
import 'dart:async';
import '../models/skill_progress.dart';

class ActivityProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ActivitySession> _rawUnclassifiedSessions = [];
  Map<String, List<ActivitySession>> _groupedUnclassifiedSessions = {};
  Map<String, int> _unclassifiedDurationPerApp = {}; // To display total duration per app

  List<TodaySummaryItem> _todaySummary = [];
  List<RuleInfo> _rules = [];
  List<RecentActivityInfo> _recentActivities = [];
  List<ExistingClassification> _existingClassifications = [];
  List<SkillProgress> _skills = [];

  bool _isLoading = false;
  String? _error;

  // Polling related fields
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  static const Duration _pollingInterval = Duration(seconds: 5);

  // Getters
  Map<String, List<ActivitySession>> get groupedUnclassifiedSessions => _groupedUnclassifiedSessions;
  Map<String, int> get unclassifiedDurationPerApp => _unclassifiedDurationPerApp;
  List<TodaySummaryItem> get todaySummary => _todaySummary;
  List<RuleInfo> get rules => _rules;
  List<RecentActivityInfo> get recentActivities => _recentActivities;
  List<ExistingClassification> get existingClassifications => _existingClassifications;
  List<SkillProgress> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPollingActive => _isPollingActive;

  ActivityProvider() {
    fetchAllData();
  }

  // Start polling for unclassified data
  void startPolling() {
    if (_isPollingActive) return;

    _isPollingActive = true;
    notifyListeners(); // Optimistically update UI
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      // Only poll if we're not currently loading to avoid overlapping requests
      if (!_isLoading) {
        _fetchUnclassifiedDataSilently();
      }
    });
  }

  // Stop polling for unclassified data
  void stopPolling() {
    if (!_isPollingActive) return;

    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingActive = false;

    // Defer the notification to prevent calling it while the widget tree is locked.
    Future.microtask(() {
      if (!_isPollingActive && _pollingTimer == null) {
        notifyListeners();
      }
    });
  }

  // Fetch unclassified data silently (without showing loading indicators)
  Future<void> _fetchUnclassifiedDataSilently() async {
    try {
      final newUnclassifiedSessions = await _apiService.getUnclassifiedSessions();
      
      // Check if the data has actually changed before updating
      if (_hasUnclassifiedDataChanged(newUnclassifiedSessions)) {
        _rawUnclassifiedSessions = newUnclassifiedSessions;
        _groupAndSortSessions();
        _error = null; // Clear any previous errors
        notifyListeners();
      }
    } catch (e) {
      // Log the error but don't update the UI for silent polling errors
      // This prevents disrupting the user experience with network errors during background polling
    }
  }

  // Check if unclassified data has changed
  bool _hasUnclassifiedDataChanged(List<ActivitySession> newSessions) {
    if (_rawUnclassifiedSessions.length != newSessions.length) {
      return true;
    }
    
    // Compare session IDs or timestamps to detect changes
    for (int i = 0; i < _rawUnclassifiedSessions.length; i++) {
      final oldSession = _rawUnclassifiedSessions[i];
      final newSession = newSessions[i];
      
      if (oldSession.appName != newSession.appName ||
          oldSession.windowTitle != newSession.windowTitle ||
          oldSession.duration != newSession.duration ||
          oldSession.startTime != newSession.startTime ||
          oldSession.endTime != newSession.endTime) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // These are the core data fetches for the main tabs
      final unclassifiedFuture = _apiService.getUnclassifiedSessions();
      final summaryFuture = _apiService.getTodaySummary();
      final rulesFuture = _apiService.getClassificationRules();
      final recentFuture = _apiService.getRecentActivity();
      final classificationsFuture = _apiService.getExistingClassifications();
      final skillsFuture = _apiService.getSkills();

      final results = await Future.wait([unclassifiedFuture, summaryFuture, rulesFuture, recentFuture, classificationsFuture, skillsFuture]);
      
      _rawUnclassifiedSessions = results[0] as List<ActivitySession>;
      _groupAndSortSessions();
      _todaySummary = results[1] as List<TodaySummaryItem>;
      _rules = results[2] as List<RuleInfo>;
      _recentActivities = results[3] as List<RecentActivityInfo>;
      _existingClassifications = results[4] as List<ExistingClassification>;
      _skills = results[5] as List<SkillProgress>;

    } catch (e) {
      print("Error fetching data: $e");
      _error = "Failed to load data. Please try again.";
      // Clear data on error to avoid showing stale info
      _rawUnclassifiedSessions = [];
      _groupedUnclassifiedSessions = {};
      _unclassifiedDurationPerApp = {};
      _todaySummary = [];
      _rules = [];
      _recentActivities = [];
      _existingClassifications = [];
      _skills = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUnclassifiedData() async {
    // If already loading, don't start another request
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rawUnclassifiedSessions = await _apiService.getUnclassifiedSessions();
      _groupAndSortSessions();
    } catch (e) {
      print("Error fetching unclassified data: $e");
      _error = "Failed to load unclassified activities. Please try again.";
      // Clear data on error to avoid showing stale info
      _rawUnclassifiedSessions = [];
      _groupedUnclassifiedSessions = {};
      _unclassifiedDurationPerApp = {};
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

    // Sort sessions within each app group by start time (most recent first)
    _groupedUnclassifiedSessions.forEach((appName, sessions) {
      sessions.sort((a, b) {
        if (a.startTime != null && b.startTime != null) {
          return b.startTime!.compareTo(a.startTime!);
        }
        return b.duration.compareTo(a.duration); // fallback to duration
      });
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

  Future<void> createRuleAndClassifyAppGroup({
    required String appName,
    required String windowTitleContains,
    required String userDefinedName,
    required bool isHelpful,
    required String goalContext,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, create the rule
      final ruleRequest = CreateClassificationRuleRequest(
        appName: appName,
        windowTitleContains: windowTitleContains,
        userDefinedName: userDefinedName,
        isHelpful: isHelpful,
        goalContext: goalContext,
      );
      await _apiService.createClassificationRule(ruleRequest);

      // Then, classify the current group
      await classifyAppGroup(appName, userDefinedName, isHelpful, goalContext);
    } catch (e) {
      print("Error creating rule and classifying group: $e");
      _error = "Failed to create rule or classify group.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRule(int ruleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteClassificationRule(ruleId);
      await fetchAllData(); // Refresh all data to reflect the change
    } catch (e) {
      print("Error deleting rule: $e");
      _error = "Failed to delete the rule.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reclassifySession(int sessionId, String userDefinedName, bool isHelpful, String goalContext) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.reclassifySession(sessionId, userDefinedName, isHelpful, goalContext);
      await fetchAllData(); // Refresh all data to reflect the change
    } catch (e) {
      print("Error reclassifying session: $e");
      _error = "Failed to reclassify the session.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(int sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteSession(sessionId);
      await fetchAllData(); // Refresh all data to reflect the change
    } catch (e) {
      print("Error deleting session: $e");
      _error = "Failed to delete the session.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}