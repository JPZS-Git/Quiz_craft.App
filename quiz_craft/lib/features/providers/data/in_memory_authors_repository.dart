import 'dart:async';

import '../domain/entities/author_entity.dart';
import '../domain/repositories/authors_repository.dart';

/// Simple in-memory repository for development/testing.
class InMemoryAuthorsRepository implements AuthorsRepository {
  final List<AuthorEntity> _store = [];

  @override
  Future<void> addAuthor(AuthorEntity author) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _store.add(author);
  }

  @override
  Future<void> deleteAuthor(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _store.removeWhere((a) => a.id == id);
  }

  @override
  Future<AuthorEntity?> getAuthorById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _store.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AuthorEntity>> fetchAuthors() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_store);
  }

  @override
  Future<void> updateAuthor(AuthorEntity author) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _store.indexWhere((a) => a.id == author.id);
    if (idx >= 0) {
      _store[idx] = author;
    } else {
      throw StateError('Author not found: ${author.id}');
    }
  }
}
