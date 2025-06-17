class TodaySummaryItem {
  final String userDefinedName;
  final int totalDuration; // in seconds

  TodaySummaryItem({
    required this.userDefinedName,
    required this.totalDuration,
  });

  factory TodaySummaryItem.fromJson(Map<String, dynamic> json) {
    return TodaySummaryItem(
      userDefinedName: json['user_defined_name'],
      totalDuration: json['total_duration_seconds'],
    );
  }
}