class ActivitySession {
  final String appName;
  final String windowTitle;
  final int duration; // in seconds

  ActivitySession({
    required this.appName,
    required this.windowTitle,
    required this.duration,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      appName: json['app_name'] ?? 'Unknown App',
      windowTitle: json['window_title'] ?? 'No Title',
      duration: (json['duration_seconds'] ?? 0).toInt(),
    );
  }
}