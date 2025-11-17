import 'package:flutter/material.dart';

//import 'package:shared_preferences/shared_preferences.dart';
import 'policy_viewer_page.dart';

// Definindo o tipo de callback que recebe o resultado (didRead)
typedef PolicyReadCallback = Future<void> Function(bool didRead);

class ListtilePolicyWidget extends StatelessWidget {
  final bool isPolicyRead;
  final String assetPath;
  final String policyTitle;
  
  // Agora recebe o método de SharedPreferences a ser chamado
  // O widget PAI (ConsentPage) define a lógica de persistência
  final PolicyReadCallback onPolicyRead; 

  const ListtilePolicyWidget({
    super.key,
    // Renomeado para ser mais genérico
    required this.isPolicyRead, 
    required this.assetPath,
    required this.policyTitle,
    required this.onPolicyRead, // Este callback será responsável por salvar o status
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isPolicyRead ? Icons.check_circle : Icons.cancel,
        color: isPolicyRead ? Colors.green : Colors.red,
      ),
      title: Text(policyTitle),
      trailing: TextButton(
        // Desabilita o botão se a política já foi lida
        onPressed: isPolicyRead
            ? null
            : () async {
                // 1. Navega para a PolicyViewerPage e espera o resultado (true/false)
                final value = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return PolicyViewerPage(
                        policyTitle: policyTitle,
                        assetPath: assetPath,
                      );
                    },
                  ),
                );
                
                final bool didRead = value ?? false;

                if (didRead) {
                  await onPolicyRead(didRead);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                        SnackBar(
                          content: Text('Obrigado por aceitar a $policyTitle.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                }
              },
        child: Text(isPolicyRead ? 'Lido' : 'Ler'),
      ),
    );
  }
}