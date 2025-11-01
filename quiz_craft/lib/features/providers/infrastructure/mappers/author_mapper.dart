import '../../domain/entities/author_entity.dart';
import '../dtos/author_dto.dart';

class AuthorMapper {
  AuthorMapper._();

  static AuthorEntity toEntity(AuthorDto d) {
    return AuthorEntity(
      id: d.id,
      name: d.name,
      email: d.email,
      avatarUrl: d.avatarUrl,
      bio: d.bio,
      topics: List<String>.from(d.topics),
      quizzesCount: d.quizzesCount,
      rating: d.rating,
      isActive: d.isActive,
      createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
    );
  }

  static AuthorDto toDto(AuthorEntity e) {
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
    );
  }
}
