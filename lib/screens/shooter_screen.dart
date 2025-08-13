import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game/models/difficulty.dart';
import 'package:sensors_plus/sensors_plus.dart';


import '../controller/shooter_game_controller.dart';
import '../models/projectile.dart'; 
import '../services/audio_manager.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/game_won_overlay.dart';

class ShooterScreen extends StatefulWidget {
  final Difficulty difficulty;

  const ShooterScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<ShooterScreen> createState() => _ShooterScreenState();
}

class _ShooterScreenState extends State<ShooterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final ShooterGameController _gameController;
  late final AudioManager _audioManager;
  StreamSubscription? _sensorSubscription;

  double _horizontalInput = 0.0;

  @override
  void initState() {
    super.initState();

    _gameController = ShooterGameController(difficulty: widget.difficulty);
    _audioManager = AudioManager();
    _audioManager.playMusic('ElectricRush.mp3');

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_gameLoop)
          ..repeat();

    _sensorSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_gameController.isGameOver && !_gameController.isGameWon) {
        const double sensitivity = 0.8;
        const double deadZone = 0.1;
        final double input = event.x * -sensitivity;

        _horizontalInput = (input.abs() > deadZone) ? input : 0.0;
      }
    });
  }

  void _gameLoop() {
    _gameController.update(_horizontalInput);
    
    
    if (_gameController.boss.isActive) {
      _audioManager.playMusic('EdgeofChaos.mp3');
    }

    // if (_gameController.isGameOver || _gameController.isGameWon) {
    //   _audioManager.pauseMusic();
    // }
    
    setState(() {});
  }

  void _restartGame() {
    setState(() {
      _gameController.restart();
    });
    _audioManager.playMusic('ElectricRush.mp3');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sensorSubscription?.cancel();
    _audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          ...[0.0, 1.0].map((offset) => Transform.translate(
                offset: Offset(0, (MediaQuery.of(context).size.height) * (_gameController.backgroundOffsetY - offset)),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(image: AssetImage('assets/images/background2.png'), fit: BoxFit.cover, repeat: ImageRepeat.repeatY),
                  ),
                ),
              )),

          
          ..._gameController.enemies.map((enemy) => Align(
                alignment: Alignment(enemy.position.dx, enemy.position.dy),
                child: SizedBox(width: 80, height: 80, child: Image.asset('assets/images/alien.png')),
              )),

          
          ..._gameController.playerProjectiles.map((p) => Align(
                alignment: Alignment(p.position.dx, p.position.dy),
                child: Container(width: 10, height: 25, color: Colors.yellow),
              )),

          
          ..._gameController.enemyProjectiles.map((p) => Align(
                alignment: Alignment(p.position.dx, p.position.dy),
                child: Container(
                  width: 15, height: 15,
                  decoration: BoxDecoration(
                    color: p.type == ProjectileType.bossExploder ? Colors.amber : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )),

          
          Align(
            alignment: Alignment(_gameController.player.positionX, 0.8),
            child: SizedBox(width: 80, height: 100, child: Image.asset('assets/images/rocket.png')),
          ),

          
          if (_gameController.boss.isActive)
            Align(
              alignment: Alignment(_gameController.boss.position.dx, _gameController.boss.position.dy),
              child: SizedBox(
                width: _gameController.boss.width, height: _gameController.boss.height,
                child: Image.asset('assets/images/AlienBoss.png', fit: BoxFit.contain),
              ),
            ),
          
          
          if (_gameController.boss.isActive)
            Positioned(
              top: 60, left: 10,
              child: SizedBox(
                height: 150, width: 30,
                child: Stack(
                  children: [
                    Container(decoration: BoxDecoration(color: Colors.grey.withOpacity(0.7), borderRadius: BorderRadius.circular(5))),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 30, height: (150 * (_gameController.boss.health / _gameController.boss.maxHealth)).clamp(0.0, 150.0),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          
          Positioned(
            top: 50, right: 20,
            child: Text(
              _gameController.boss.isActive ? 'BOSS' : 'PONTOS: ${_gameController.score} / 20',
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          
          if (_gameController.isGameOver)
            GameOverOverlay(score: _gameController.score, onRestart: _restartGame),

          if (_gameController.isGameWon)
            GameWonOverlay(onRestart: _restartGame),
        ],
      ),
    );
  }
}