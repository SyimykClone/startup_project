class AchievementProgress {
  final String code;
  final String title;
  final bool unlocked;

  AchievementProgress({
    required this.code,
    required this.title,
    required this.unlocked,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      unlocked: json['unlocked'] == true,
    );
  }
}

class GamificationProgress {
  final int level;
  final int xp;
  final int currentLevelXp;
  final int? nextLevelXp;
  final double xpProgressPercent;
  final int routesBuilt;
  final int newPlacesVisited;
  final List<AchievementProgress> achievements;

  GamificationProgress({
    required this.level,
    required this.xp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.xpProgressPercent,
    required this.routesBuilt,
    required this.newPlacesVisited,
    required this.achievements,
  });

  factory GamificationProgress.fromJson(Map<String, dynamic> json) {
    final achievementsRaw = json['achievements'];
    final achievements = achievementsRaw is List
        ? achievementsRaw
              .whereType<Map>()
              .map((e) => AchievementProgress.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <AchievementProgress>[];

    return GamificationProgress(
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      currentLevelXp: (json['current_level_xp'] as num?)?.toInt() ?? 0,
      nextLevelXp: (json['next_level_xp'] as num?)?.toInt(),
      xpProgressPercent: (json['xp_progress_percent'] as num?)?.toDouble() ?? 0,
      routesBuilt: (json['routes_built'] as num?)?.toInt() ?? 0,
      newPlacesVisited: (json['new_places_visited'] as num?)?.toInt() ?? 0,
      achievements: achievements,
    );
  }
}
