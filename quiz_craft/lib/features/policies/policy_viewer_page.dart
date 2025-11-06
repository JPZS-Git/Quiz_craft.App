import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class PolicyViewerPage extends StatefulWidget {
  static const routeName = '/policy-viewer';
  final String policyTitle;
  final String assetPath;

  const PolicyViewerPage({
    super.key,
    required this.policyTitle,
    required this.assetPath,
  });

  @override
  State<PolicyViewerPage> createState() => _PolicyViewerPageState();
}

class _PolicyViewerPageState extends State<PolicyViewerPage> {
  // 🎨 Paleta de cores conforme PRD (padrão QuizCraft)
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _surfaceGray = Color(0xFF475569);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _divider = Color(0xFFE2E8F0);

  final ScrollController _scrollController = ScrollController();
  String _policyContentFromMarkdown = '';
  double _scrollProgress = 0.0;
  bool _reachedEndOfDocument = false;

  @override
  void initState() {
    super.initState();
    _loadPolicyContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicyContent() async {
    try {
      final data = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _policyContentFromMarkdown = data;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          setState(() {
            _reachedEndOfDocument = true;
            _scrollProgress = 1.0;
          });
        }
      });
    } catch (e) {
      setState(() {
        _policyContentFromMarkdown =
            '❌ Erro ao carregar o documento.\nVerifique o caminho e o pubspec.yaml.\n\nDetalhes: $e';
        _reachedEndOfDocument = true;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    if (pos.maxScrollExtent <= 0) return;

    final newProgress =
        (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);

    if ((newProgress - _scrollProgress).abs() >= 0.01) {
      setState(() {
        _scrollProgress = newProgress;
        _reachedEndOfDocument = pos.atEdge && pos.pixels > 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _surfaceGray),
        title: Text(
          widget.policyTitle,
          style: const TextStyle(
            color: _surfaceGray,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: _divider,
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
          ),
        ),
      ),
      body: _policyContentFromMarkdown.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SelectionArea(
                          child: GptMarkdown(
                            _policyContentFromMarkdown,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _divider)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _reachedEndOfDocument
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      disabledBackgroundColor: Color.fromRGBO(71, 85, 105, 0.2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: Icon(
                      _reachedEndOfDocument
                          ? Icons.check_circle_outline
                          : Icons.lock_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      _reachedEndOfDocument
                          ? 'Concordo com os Termos'
                          : 'Role até o final para habilitar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
