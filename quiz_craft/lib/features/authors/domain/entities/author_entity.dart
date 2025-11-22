class AuthorEntity {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final List<String> topics;
  final int quizzesCount;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AuthorEntity({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.topics = const [],
    this.quizzesCount = 0,
    this.rating = 0.0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  AuthorEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    List<String>? topics,
    int? quizzesCount,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthorEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      topics: topics ?? this.topics,
      quizzesCount: quizzesCount ?? this.quizzesCount,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AuthorEntity.fromJson(Map<String, dynamic> json) {
    final topicsRaw = json['topics'];
    final topicsList = <String>[];
    if (topicsRaw is List) {
      topicsList.addAll(topicsRaw.whereType<String>());
    } else if (topicsRaw is String) {
      topicsList.addAll(topicsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }

    return AuthorEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      topics: topicsList,
      quizzesCount: (json['quizzes_count'] is int)
          ? json['quizzes_count'] as int
          : (json['quizzes_count'] is num ? (json['quizzes_count'] as num).toInt() : 0),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'topics': topics,
      'quizzes_count': quizzesCount,
      'rating': rating,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'AuthorEntity(id: $id, name: $name, quizzes: $quizzesCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.quizzesCount == quizzesCount &&
        other.rating == rating &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _listEquals(other.topics, topics);
  }

  @override
  int get hashCode => Object.hash(id, name, email, avatarUrl, bio, Object.hashAll(topics), quizzesCount, rating, isActive, createdAt, updatedAt);

  static bool _listEquals(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
