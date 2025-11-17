import '../entities/author_entity.dart';

abstract class AuthorsRepository {
  /// Returns list of authors.
  Future<List<AuthorEntity>> fetchAuthors();

  /// Returns author by id or null.
  Future<AuthorEntity?> getAuthorById(String id);

  Future<void> addAuthor(AuthorEntity author);

  Future<void> updateAuthor(AuthorEntity author);

  Future<void> deleteAuthor(String id);
}
