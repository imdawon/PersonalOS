import 'dart:convert';

class ClassificationRequest {
  final String appName;
  final String windowTitle;
  final String userDefinedName;
  final bool isHelpful;
  final String goalContext;

  ClassificationRequest({
    required this.appName,
    required this.windowTitle,
    required this.userDefinedName,
    required this.isHelpful,
    required this.goalContext,
  });

  String toJson() {
    return json.encode({
      'app_name': appName,
      'window_title': windowTitle,
      'user_defined_name': userDefinedName,
      'is_helpful': isHelpful,
      'goal_context': goalContext,
    });
  }
}

class SessionIdentifier {
  final String appName;
  final String windowTitle;

  SessionIdentifier({required this.appName, required this.windowTitle});

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'window_title': windowTitle,
    };
  }
}

class BatchClassificationRequest {
  final List<SessionIdentifier> sessions;
  final String userDefinedName;
  final bool isHelpful;
  final String goalContext;

  BatchClassificationRequest({
    required this.sessions,
    required this.userDefinedName,
    required this.isHelpful,
    required this.goalContext,
  });

  String toJson() {
    return json.encode({
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'user_defined_name': userDefinedName,
      'is_helpful': isHelpful,
      'goal_context': goalContext,
    });
  }
}