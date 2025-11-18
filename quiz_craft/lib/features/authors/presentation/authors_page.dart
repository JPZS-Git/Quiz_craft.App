import 'package:flutter/material.dart';
import '../infrastructure/local/authors_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/author_dto.dart';

/// Página de listagem de autores (Authors).
class AuthorsPage extends StatefulWidget {
  static const routeName = '/authors';

  const AuthorsPage({super.key});

  @override
  State<AuthorsPage> createState() => _AuthorsPageState();
}

class _AuthorsPageState extends State<AuthorsPage> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = AuthorsLocalDaoSharedPrefs();
  List<AuthorDto> _authors = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authors = await _dao.listAll();
      if (!mounted) return;
      
      authors.sort((a, b) => b.rating.compareTo(a.rating));

      setState(() {
        _authors = authors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar autores';
        _loading = false;
      });
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].characters.first;
    final last = parts[parts.length - 1].characters.first;
    return (first + last).toUpperCase();
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email não informado';
    
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email;
    
    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    
    if (localPart.length <= 2) {
      return '${localPart[0]}***$domain';
    }
    
    return '${localPart[0]}***${localPart[localPart.length - 1]}$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Autores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAuthors,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAuthors,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_authors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Nenhum autor encontrado', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAuthors,
      child: ListView.builder(
        itemCount: _authors.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final author = _authors[index];
          return _AuthorCard(
            author: author,
            isExpanded: _expandedIds.contains(author.id),
            onTap: () => _toggleExpand(author.id),
            initials: _getInitials(author.name),
            maskedEmail: _maskEmail(author.email),
          );
        },
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AuthorDto author;
  final bool isExpanded;
  final VoidCallback onTap;
  final String initials;
  final String maskedEmail;

  const _AuthorCard({
    required this.author,
    required this.isExpanded,
    required this.onTap,
    required this.initials,
    required this.maskedEmail,
  });

  @override
  Widget build(BuildContext context) {
    final ratingColor = author.rating >= 4.5 ? Colors.green : (author.rating >= 3.5 ? Colors.orange : Colors.red);
    
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(author.avatarUrl!),
                    backgroundColor: _primaryBlue.withValues(alpha: 0.2),
                  )
                : CircleAvatar(
                    radius: 28,
                    backgroundColor: _primaryBlue.withValues(alpha: 0.2),
                    child: Text(initials, style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(author.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (author.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    author.isActive ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: author.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: ratingColor),
                      const SizedBox(width: 4),
                      Text(author.rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: ratingColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${author.quizzesCount} quizzes', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                  if (author.topics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: author.topics.take(3).map((t) => _chip(t)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: _primaryBlue),
            onTap: onTap,
          ),
          if (isExpanded) _details(),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _primaryBlue, fontWeight: FontWeight.w500)),
    );
  }

  Widget _details() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _row(Icons.fingerprint, 'ID', author.id),
          const SizedBox(height: 8),
          _row(Icons.email, 'Email', maskedEmail),
          if (author.bio != null && author.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(Icons.info_outline, 'Biografia', author.bio!),
          ],
          const SizedBox(height: 8),
          _row(Icons.calendar_today, 'Cadastrado', _date(author.createdAt)),
          if (author.topics.length > 3) ...[
            const SizedBox(height: 12),
            Text('Todos os tópicos', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: author.topics.map(_chip).toList()),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _date(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
