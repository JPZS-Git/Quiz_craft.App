import 'package:flutter/material.dart';
import '../domain/entities/author_entity.dart';
import '../services/author_sync_service.dart';
import 'dialogs/author_actions_dialog.dart';
import 'dialogs/author_form_dialog.dart';
import 'widgets/author_list_item.dart';

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

  late final AuthorSyncService _syncService;
  List<AuthorEntity> _authors = [];
  bool _loading = true;
  //bool _syncing = false;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _syncService = AuthorSyncService.create();
    _syncService.addListener(_onSyncUpdate);
    _loadAuthors();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    _syncService.dispose();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {
        //_syncing = _syncService.isSyncing;
        if (!_syncService.isSyncing) {
          _authors = _syncService.cachedAuthors;
        }
      });
    }
  }

  Future<void> _loadAuthors() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Carrega cache local imediatamente (UI não trava)
      final cached = await _syncService.loadCacheOnly();
      
      if (!mounted) return;
      
      setState(() {
        _authors = cached;
        _loading = false;
      });

      // 2. Sincroniza com Supabase em background (silencioso)
      _syncService.syncAuthors().then((_) {
        debugPrint('✅ Sync de authors concluído em background');
      }).catchError((e) {
        debugPrint('⚠️ Erro no sync background: $e');
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

  /// Abre o diálogo de ações para o autor selecionado.
  void _showActionsDialog(AuthorEntity author) {
    showAuthorActionsDialog(
      context,
      author,
      onEdit: () => _handleEdit(author),
      onRemove: () => _handleRemove(author),
    );
  }

  /// Handler para editar um autor.
  Future<void> _handleEdit(AuthorEntity author) async {
    await showAuthorFormDialog(context, author: author);
    await _loadAuthors();
  }

  /// Handler para remover um autor após confirmação.
  Future<bool> _confirmRemove(AuthorEntity author) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Autor?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nome', author.name),
            const SizedBox(height: 8),
            _buildInfoRow('Email', _maskEmail(author.email)),
            const SizedBox(height: 8),
            _buildInfoRow('Quizzes criados', '${author.quizzesCount}'),
            const SizedBox(height: 8),
            _buildInfoRow('Status', author.isActive ? 'ATIVO' : 'INATIVO'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: Os ${author.quizzesCount} quizzes associados também serão removidos',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    try {
      await _syncService.deleteAuthor(author.id);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autor removido com sucesso'), backgroundColor: Colors.green),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover autor: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<void> _handleRemove(AuthorEntity author) async {
    await _confirmRemove(author);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
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
          return Dismissible(
            key: Key(author.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            confirmDismiss: (direction) => _confirmRemove(author),
            onDismissed: (direction) {
              // Removal is already handled in confirmDismiss
            },
            child: AuthorListItem(
              author: author,
              isExpanded: _expandedIds.contains(author.id),
              onTap: () => _toggleExpand(author.id),
              onLongPress: () => _showActionsDialog(author),
              onEdit: () => _handleEdit(author),
              initials: _getInitials(author.name),
              maskedEmail: _maskEmail(author.email),
            ),
          );
        },
      ),
    );
  }
}
