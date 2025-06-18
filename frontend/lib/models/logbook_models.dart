class RuleInfo {
  final int id;
  final String appName;
  final String windowTitleContains;
  final String userDefinedName;

  RuleInfo({
    required this.id,
    required this.appName,
    required this.windowTitleContains,
    required this.userDefinedName,
  });

  factory RuleInfo.fromJson(Map<String, dynamic> json) {
    return RuleInfo(
      id: json['id'],
      appName: json['app_name'],
      windowTitleContains: json['window_title_contains'],
      userDefinedName: json['user_defined_name'],
    );
  }
}

class RecentActivityInfo {
  final int sessionId;
  final String appName;
  final String windowTitle;
  final String userDefinedName;
  final int startTime; // Unix timestamp
  final bool isAuto;

  RecentActivityInfo({
    required this.sessionId,
    required this.appName,
    required this.windowTitle,
    required this.userDefinedName,
    required this.startTime,
    required this.isAuto,
  });

  factory RecentActivityInfo.fromJson(Map<String, dynamic> json) {
    return RecentActivityInfo(
      sessionId: json['session_id'],
      appName: json['app_name'],
      windowTitle: json['window_title'],
      userDefinedName: json['user_defined_name'],
      startTime: json['start_time'],
      isAuto: json['is_auto'] ?? false, // Default to false if null
    );
  }
}

class ExistingClassification {
  final String userDefinedName;
  final String goalContext;
  final bool isHelpful;

  ExistingClassification({
    required this.userDefinedName,
    required this.goalContext,
    required this.isHelpful,
  });

  factory ExistingClassification.fromJson(Map<String, dynamic> json) {
    return ExistingClassification(
      userDefinedName: json['user_defined_name'],
      goalContext: json['goal_context'],
      isHelpful: json['is_helpful'],
    );
  }
} 