class ProfileModel {
  final String id;
  final String email;
  final String displayName;
  final String avatarId;
  final String gender;
  final String friendCode;
  final String role;
  final String privacyLevel;
  final int totalPoints;
  final int streakCount;

  ProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarId,
    required this.gender,
    required this.friendCode,
    required this.role,
    required this.privacyLevel,
    required this.totalPoints,
    required this.streakCount,
  });

  bool get isAdmin => role == 'admin';
  bool get isMale => gender == 'male';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? 'مستخدم',
      avatarId: json['avatar_id'] ?? (json['gender'] == 'female' ? 'f1' : 'm1'),
      gender: json['gender'] ?? 'male',
      friendCode: json['friend_code'] ?? 'ADK-0000',
      role: json['role'] ?? 'user',
      privacyLevel: json['privacy_level'] ?? 'public',
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DhikrModel {
  final String id;
  final String adminTitle;
  final String text;
  final String category;
  final int repeats;
  final String virtue;
  final String status;
  final List<dynamic> hadiths;

  DhikrModel({
    required this.id,
    required this.adminTitle,
    required this.text,
    required this.category,
    required this.repeats,
    required this.virtue,
    required this.status,
    this.hadiths = const [],
  });

  factory DhikrModel.fromJson(Map<String, dynamic> json) {
    return DhikrModel(
      id: json['id'] ?? '',
      adminTitle: json['adminTitle'] ?? json['admin_title'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? 'general',
      repeats: (json['repeats'] as num?)?.toInt() ?? 1,
      virtue: json['virtue'] ?? '',
      status: json['status'] ?? 'active',
      hadiths: json['hadiths'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'admin_title': adminTitle,
    'text': text,
    'category': category,
    'repeats': repeats,
    'virtue': virtue,
    'status': status,
    'hadiths': hadiths,
  };
}

class WorshipTaskModel {
  final String key;
  final String title;
  final String subtitle;
  final int points;
  final String category;
  final String categoryName;
  final String icon;

  const WorshipTaskModel({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.category,
    required this.categoryName,
    required this.icon,
  });
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String avatarId;
  final String gender;
  final String friendCode;
  final String role;
  final int points;
  final int streakCount;
  final int rank;
  final bool isFriend;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.gender,
    required this.friendCode,
    required this.role,
    required this.points,
    required this.streakCount,
    required this.rank,
    required this.isFriend,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarId: json['avatar_id'] ?? (json['gender'] == 'female' ? 'f1' : 'm1'),
      gender: json['gender'] ?? 'male',
      friendCode: json['friend_code'] ?? '',
      role: json['role'] ?? 'user',
      points: (json['points'] as num?)?.toInt() ?? 0,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      isFriend: json['is_friend'] == true,
    );
  }
}
