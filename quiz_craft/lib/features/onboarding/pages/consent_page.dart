import 'package:flutter/material.dart';
import 'package:quizcraft/services/shared_preferences_services.dart';
import '../../policies/policy_viewer_page.dart';

class ConsentPageOBPage extends StatefulWidget {
  final VoidCallback onConsentGiven;
  const ConsentPageOBPage({super.key, required this.onConsentGiven});

  @override
  State<ConsentPageOBPage> createState() => _ConsentPageOBPageState();
}

class _ConsentPageOBPageState extends State<ConsentPageOBPage> {
  // 🎨 Paleta de cores com contraste aprimorado
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _surfaceGray = Color(0xFF334155);
  static const Color _textGray = Color(0xFF475569);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF1F5F9);
  static const Color _dividerColor = Color(0xFFE2E8F0);

  bool _policiesAccepted = false;
  bool _privacyRead = false;
  bool _termsRead = false;

  Future<void> _openPolicy(
    String title,
    String path,
    ValueChanged<bool> onResult,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyViewerPage(
          policyTitle: title,
          assetPath: path,
        ),
      ),
    );
    if (result == true) onResult(true);
  }

  void _accept() async {
  final service = SharedPreferencesService();
  await service.completeInitialFlow(version: 1.0);

  if (!mounted) return;
  Navigator.of(context).pushReplacementNamed('/home');
}

  @override
  Widget build(BuildContext context) {
    final allRead = _privacyRead && _termsRead;

    return Scaffold(
  backgroundColor: _background,
  appBar: AppBar(
    backgroundColor: _primaryBlue,
    elevation: 6,
    shadowColor: Colors.black38,
    title: const Text(
      'Consentimento',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(16),
      ),
    ),
  ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antes de continuar, leia e aceite nossos termos:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _surfaceGray,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 28),

            // 🧾 Política de Privacidade
            _buildPolicyCard(
              title: 'Política de Privacidade',
              read: _privacyRead,
              onPressed: () => _openPolicy(
                'Política de Privacidade',
                'assets/policies/privacy_policy.md',
                (val) => setState(() => _privacyRead = val),
              ),
            ),
            const SizedBox(height: 16),

            // 📜 Termos de Uso
            _buildPolicyCard(
              title: 'Termos de Uso',
              read: _termsRead,
              onPressed: () => _openPolicy(
                'Termos de Uso',
                'assets/policies/terms_of_use.md',
                (val) => setState(() => _termsRead = val),
              ),
            ),

            const SizedBox(height: 32),
            Divider(color: _dividerColor, thickness: 1),
            const SizedBox(height: 16),

            // ✅ Checkbox final
            Card(
  elevation: 4, // adiciona sombra
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12), // cantos arredondados
  ),
  shadowColor: Colors.black45,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        // Checkbox arredondado
        Checkbox(
          value: _policiesAccepted,
          onChanged: allRead ? (val) => setState(() => _policiesAccepted = val!) : null,
          activeColor: _primaryBlue,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // cantos do checkbox
          ),
        ),
        const SizedBox(width: 8),
        // Texto
        Expanded(
          child: Text(
            'Declaro que li e aceito os documentos acima',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _textGray,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  ),
),
            const Spacer(),

            // 🔘 Botão principal
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _policiesAccepted ? _accept : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: _dividerColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 Card para cada política
  Widget _buildPolicyCard({
    required String title,
    required bool read,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: read ? _primaryBlue.withOpacity(0.4) : _dividerColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          title,
          style: TextStyle(
            color: _surfaceGray,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          read ? 'Lido e aceito ✅' : 'Não lido',
          style: TextStyle(
            color: read ? _primaryBlue : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: read ? _accentAmber : _primaryBlue,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          child: const Text('Ler'),
        ),
      ),
    );
  }
}

