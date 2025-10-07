import 'package:flutter/material.dart';

class DotsIndicator extends StatelessWidget {
  final int totalDots;
  final int currentIndex;

  const DotsIndicator({
    super.key,
    required this.currentIndex,
    required this.totalDots,
  });
  
  // Cores do QuizCraft (Hardcoded no arquivo, para evitar imports)
  static const Color _primaryBlue = Color(0xFF2563EB); // Blue
  static const Color _surfaceGray = Color(0xFF475569); // Gray

  @override
  Widget build(BuildContext context) {
    // Usamos o colorScheme, mas priorizamos as cores hardcoded para maior controle visual
    //final color = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          // RNF-105: Certificamos que os pontos são visíveis e responsivos (10dp como base é seguro)
          width: isSelected ? 16.0 : 10.0, 
          height: isSelected ? 16.0 : 10.0,
          decoration: BoxDecoration(
            // Cor do ponto selecionado: Azul (Primary Blue)
            // Cor do ponto não selecionado: Cinza (Surface Gray), com leve opacidade
            color: isSelected ? _primaryBlue : _surfaceGray,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}