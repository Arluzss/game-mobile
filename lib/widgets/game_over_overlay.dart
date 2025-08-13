// lib/widgets/game_over_overlay.dart
import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(128),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('FIM DE JOGO', style: TextStyle(/*...*/)),
            const SizedBox(height: 20),
            Text('SUA PONTUAÇÃO: $score', style: TextStyle(/*...*/)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRestart,
              child: const Text('Jogar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}