import 'package:flutter/material.dart';
import '../infrastructure/local/attempts_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/attempt_dto.dart';

/// Página de listagem de tentativas (Attempts).
/// Exibe tentativas de quiz armazenadas localmente com detalhes de pontuação.
class AttemptsPage extends StatefulWidget {
  static const routeName = '/attempts';

  const AttemptsPage({super.key});

  @override
  State<AttemptsPage> createState() => _AttemptsPageState();
}

class _AttemptsPageState extends State<AttemptsPage> {
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = AttemptsLocalDaoSharedPrefs();
  List<AttemptDto> _attempts = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final attempts = await _dao.listAll();
      if (!mounted) return;
      
      // Ordenar por data de início (mais recente primeiro)
      attempts.sort((a, b) {
        final dateA = DateTime.tryParse(a.startedAt) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.startedAt) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar tentativas';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tentativas de Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Tooltip(
            message: 'Recarregar',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Recarregar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              splashRadius: 24,
              onPressed: _loadAttempts,
            ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAttempts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma tentativa encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete um quiz para ver suas tentativas aqui',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAttempts,
      child: ListView.builder(
        itemCount: _attempts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final attempt = _attempts[index];
          return _AttemptListItem(
            attempt: attempt,
            isExpanded: _expandedIds.contains(attempt.id),
            onTap: () => _toggleExpand(attempt.id),
          );
        },
      ),
    );
  }
}

/// Widget para renderizar um item de tentativa na lista.
class _AttemptListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AttemptDto attempt;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AttemptListItem({
    required this.attempt,
    required this.isExpanded,
    required this.onTap,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.stars;
    if (score >= 60) return Icons.check_circle;
    return Icons.cancel;
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    
    // Formato dd/MM/yyyy HH:mm sem intl package
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    final started = DateTime.tryParse(attempt.startedAt);
    final finished = attempt.finishedAt != null 
        ? DateTime.tryParse(attempt.finishedAt!) 
        : null;
    
    if (started == null) return 'Duração desconhecida';
    if (finished == null) return 'Em andamento';
    
    final duration = finished.difference(started);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(attempt.score);
    final scoreIcon = _getScoreIcon(attempt.score);
    final isFinished = attempt.finishedAt != null;
    
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _withAlpha(scoreColor, 0.2),
              child: Icon(
                scoreIcon,
                color: scoreColor,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Quiz ${attempt.quizId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _withAlpha(scoreColor, 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${attempt.score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attempt.correctCount}/${attempt.totalCount} corretas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(attempt.startedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: _primaryBlue,
            ),
            onTap: onTap,
          ),
          if (isExpanded) _buildDetails(isFinished),
        ],
      ),
    );
  }

  Widget _buildDetails(bool isFinished) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.assignment,
            'ID da Tentativa',
            attempt.id,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.quiz,
            'ID do Quiz',
            attempt.quizId,
          ),
          if (attempt.userId != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.person,
              'Usuário',
              _maskUserId(attempt.userId!),
            ),
          ],
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.timer,
            'Duração',
            _calculateDuration(),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.calendar_today,
            'Iniciado em',
            _formatDateTime(attempt.startedAt),
          ),
          if (isFinished) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.check_circle_outline,
              'Finalizado em',
              _formatDateTime(attempt.finishedAt!),
            ),
          ],
          const SizedBox(height: 12),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final percentage = attempt.score / 100;
    final scoreColor = _getScoreColor(attempt.score);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
      ],
    );
  }

  String _maskUserId(String userId) {
    if (userId.length <= 8) return 'user-***';
    return '${userId.substring(0, 4)}***${userId.substring(userId.length - 4)}';
  }
}
