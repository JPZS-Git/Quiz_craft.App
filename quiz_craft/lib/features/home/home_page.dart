import 'package:flutter/material.dart';
import 'package:quizcraft/features/onboarding/pages/consent_page.dart';
import 'package:quizcraft/features/quizzes/infrastructure/local/quizzes_local_dao_shared_prefs.dart';
import 'package:quizcraft/features/quizzes/infrastructure/dtos/quiz_dto.dart';
import 'package:quizcraft/features/quizzes/presentation/dialogs/quiz_form_dialog.dart';
import 'package:quizcraft/features/home/profile_page.dart';
import 'package:quizcraft/services/shared_preferences_services.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  String? _userName;
  String? _userEmail;
  final _quizzesDao = QuizzesLocalDaoSharedPrefs();
  List<QuizDto> _quizzes = [];
  bool _loadingQuizzes = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadQuizzes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConsent());
  }

  Future<void> _loadUser() async {
    final prefs = SharedPreferencesService();
    final name = await prefs.getUserName();
    final email = await prefs.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loadingQuizzes = true);
    try {
      final quizzes = await _quizzesDao.listAll();
      if (!mounted) return;
      
      quizzes.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.createdAt) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _quizzes = quizzes;
        _loadingQuizzes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingQuizzes = false);
    }
  }

  Future<void> _checkConsent() async {
    final prefsService = SharedPreferencesService();
    final accepted = await prefsService.isPoliciesAccepted();

    if (!accepted && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConsentPageOBPage(
            onConsentGiven: () => _checkConsent(),
          ),
        ),
      );
    }
  }

  Future<void> _handleCreateQuiz() async {
    await showQuizFormDialog(context);
    await _loadQuizzes();
  }

  Future<void> _handleEditQuiz(QuizDto quiz) async {
    await showQuizFormDialog(context, quiz: quiz);
    await _loadQuizzes();
  }

  Future<void> _handleRemoveQuiz(QuizDto quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Quiz?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título: ${quiz.title}'),
            const SizedBox(height: 8),
            Text('Questões: ${quiz.questions.length}'),
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
                      'Atenção: As ${quiz.questions.length} questões associadas também serão removidas',
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

    if (confirm != true) return;

    try {
      await _quizzesDao.removeById(quiz.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz removido com sucesso'), backgroundColor: Colors.green),
      );
      await _loadQuizzes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover quiz: $e'), backgroundColor: Colors.red),
      );
    }
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
          'QuizCraft',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Tooltip(
            message: 'Ajuda',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Ajuda',
              icon: const Icon(Icons.help_outline, color: Colors.white),
              splashRadius: 24,
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Como começar?'),
                    content: const Text(
                      'Use o menu lateral para acessar seu perfil, políticas e outras configurações.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendi'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: _primaryBlue),
              accountName: Text(_userName ?? 'Usuário não registrado'),
              accountEmail: Text(_userEmail ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName != null && _userName!.isNotEmpty
                      ? _userName!
                            .trim()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                      : '?',
                  style: const TextStyle(fontSize: 20, color: _primaryBlue),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar perfil'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
                if (result == true) {
                  _loadUser();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade & consentimentos'),
              onTap: () {
                Navigator.of(context).pop();
                _openPrivacyDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Política de Privacidade'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/policies');
              },
            ),
          ],
        ),
      ),

      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateQuiz,
        backgroundColor: _primaryBlue,
        tooltip: 'Criar novo quiz',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingQuizzes) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum quiz disponível',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione quizzes para começar',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        itemCount: _quizzes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return _QuizCard(
            quiz: quiz,
            onEdit: () => _handleEditQuiz(quiz),
            onRemove: () => _handleRemoveQuiz(quiz),
          );
        },
      ),
    );
  }

  void _openPrivacyDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacidade & Consentimentos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Deletar nome e e-mail locais'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar remoção de dados'),
                        content: const Text(
                          'Deseja realmente remover seu nome e e-mail armazenados localmente?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remover'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final prefs = SharedPreferencesService();
                      await prefs.setUserName('');
                      await prefs.setUserEmail('');
                      if (!mounted) return;
                      
                      setState(() {
                        _userName = null;
                        _userEmail = null;
                      });
                      
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Dados locais removidos.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Deletar'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Revogar consentimento'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final navigator = Navigator.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar revogação'),
                        content: const Text(
                          'Deseja realmente revogar seu consentimento? Você será redirecionado para a tela de consentimento.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Revogar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final prefsService = SharedPreferencesService();
                      await prefsService.revokeAllConsent();
                      
                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ConsentPageOBPage(
                            onConsentGiven: () => _checkConsent(),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Revogar'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuizDto quiz;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _QuizCard({required this.quiz, this.onEdit, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final questionsCount = quiz.questions.length;
    final estimatedTime = (questionsCount * 0.5).ceil();

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                quiz.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (quiz.isPublished)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PUBLICADO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.green,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: _primaryBlue, size: 20),
                onPressed: onEdit,
                tooltip: 'Editar quiz',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 4),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onRemove,
                tooltip: 'Remover quiz',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quiz.description != null && quiz.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    quiz.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                children: [
                  Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$questionsCount perguntas',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '~$estimatedTime min',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              if (quiz.topics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quiz.topics.take(3).map((t) => _chip(t)).toList(),
                ),
              ],
            ],
          ),
        ),
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
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _primaryBlue, fontWeight: FontWeight.w500),
      ),
    );
  }
}
