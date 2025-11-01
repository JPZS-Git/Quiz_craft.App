import 'package:flutter/foundation.dart';

import 'domain/entities/author_entity.dart';
import 'domain/repositories/authors_repository.dart';

class AuthorsProvider extends ChangeNotifier {
  final AuthorsRepository repository;

  AuthorsProvider({required this.repository});

  List<AuthorEntity> _authors = [];
  bool _loading = false;
  String? _error;

  List<AuthorEntity> get authors => List.unmodifiable(_authors);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAuthors() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await repository.fetchAuthors();
      _authors = list;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('Failed loading authors: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  AuthorEntity? getById(String id) {
    try {
      return _authors.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addAuthor(AuthorEntity author) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.addAuthor(author);
      _authors = [..._authors, author];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateAuthor(AuthorEntity author) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.updateAuthor(author);
      _authors = _authors.map((p) => p.id == author.id ? author : p).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAuthor(String id) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.deleteAuthor(id);
      _authors = _authors.where((p) => p.id != id).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
