class SkillProgress {
  final String userDefinedName;
  final int level;
  final int currentXp;
  final int xpForNextLevel;
  final int totalXp;

  SkillProgress({
    required this.userDefinedName,
    required this.level,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.totalXp,
  });

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      userDefinedName: json['user_defined_name'],
      level: json['level'],
      currentXp: json['current_xp'],
      xpForNextLevel: json['xp_for_next_level'],
      totalXp: json['total_xp'],
    );
  }
} 