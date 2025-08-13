import 'package:flutter/material.dart';

class GameWonOverlay extends StatelessWidget {
  final VoidCallback onRestart;

  const GameWonOverlay({
    super.key,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'VOCÊ VENCEU!',
              style: TextStyle(
                fontSize: 48,
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10.0, color: Colors.greenAccent)],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Jogar Novamente',
                style: TextStyle(fontSize: 22),
              ),
            )
          ],
        ),
      ),
    );
  }
}