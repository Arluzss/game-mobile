import 'package:flutter/material.dart';

class LevelCompleteOverlay extends StatelessWidget {
  final VoidCallback onContinue;

  final String buttonText;

  const LevelCompleteOverlay({
    super.key,
    required this.onContinue,
    this.buttonText = 'Continuar',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fundo semi-transparente
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FASE COMPLETA!',
              style: TextStyle(
                fontSize: 48,
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10.0, color: Colors.greenAccent)],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 22)),
            ),
          ],
        ),
      ),
    );
  }
}
