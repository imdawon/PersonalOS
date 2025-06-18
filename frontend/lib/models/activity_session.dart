class ActivitySession {
  final int? id;
  final String appName;
  final String windowTitle;
  final int duration; // in seconds
  final DateTime? startTime;
  final DateTime? endTime;

  ActivitySession({
    this.id,
    required this.appName,
    required this.windowTitle,
    required this.duration,
    this.startTime,
    this.endTime,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'],
      appName: json['app_name'] ?? 'Unknown App',
      windowTitle: json['window_title'] ?? 'No Title',
      duration: (json['duration_seconds'] ?? 0).toInt(),
      startTime: json['start_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['start_time'] * 1000)
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time'] * 1000)
          : null,
    );
  }
}