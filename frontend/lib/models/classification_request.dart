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