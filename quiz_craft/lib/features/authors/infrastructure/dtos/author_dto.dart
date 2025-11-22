import '../../domain/entities/author_entity.dart';

class AuthorDto {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final List<String> topics;
  final int quizzesCount;
  final double rating;
  final bool isActive;
  final String createdAt; // ISO
  final String updatedAt; // ISO

  AuthorDto({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.topics = const [],
    this.quizzesCount = 0,
    this.rating = 0.0,
    this.isActive = true,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory AuthorDto.fromMap(Map<String, dynamic> map) {
    final rawTopics = map['topics'];
    List<String> topicsList = <String>[];
    if (rawTopics is List) {
      topicsList = rawTopics.whereType<String>().toList();
    } else if (rawTopics is String) {
      topicsList = rawTopics.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return AuthorDto(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      topics: topicsList,
      quizzesCount: (map['quizzes_count'] is int)
          ? map['quizzes_count'] as int
          : (map['quizzes_count'] is num ? (map['quizzes_count'] as num).toInt() : 0),
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : (double.tryParse(map['rating']?.toString() ?? '') ?? 0.0),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  AuthorEntity toEntity() {
    return AuthorEntity(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      topics: topics,
      quizzesCount: quizzesCount,
      rating: rating,
      isActive: isActive,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory AuthorDto.fromEntity(AuthorEntity e) {
    return AuthorDto(
      id: e.id,
      name: e.name,
      email: e.email,
      avatarUrl: e.avatarUrl,
      bio: e.bio,
      topics: e.topics,
      quizzesCount: e.quizzesCount,
      rating: e.rating,
      isActive: e.isActive,
      createdAt: e.createdAt.toIso8601String(),
      updatedAt: e.updatedAt.toIso8601String(),
    );
  }
}
