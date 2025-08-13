import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:game/models/difficulty.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../controller/jump_game_controller.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/game_over_overlay.dart';
import 'shooter_screen.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final Difficulty difficulty;

  const GameScreen({super.key, required this.level, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final JumperGameController _gameController;
  StreamSubscription? _sensorSubscription;

  double _horizontalInput = 0.0;
  late String _backgroundImage;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    _gameController = JumperGameController(
      difficulty: widget.difficulty,
      level: widget.level,
    );

    _setupAudio();
    _setupBackgroundImage();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_gameLoop)
          ..repeat();

    _sensorSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!_gameController.isGameOver) {
        const double sensitivity = 10.0;
        _horizontalInput =
            (_gameController.player.position.dx - (event.x / sensitivity))
                .clamp(-1.0, 1.0);
      }
    });
  }

  void _setupAudio() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('music/WhispersWonder.mp3')).catchError((e) {
      print("Erro ao tocar a música: $e");
    });
  }

  void _setupBackgroundImage() {
    switch (widget.level) {
      case 1:
        _backgroundImage = 'assets/images/background2.png';
        break;
      case 2:
        _backgroundImage = 'assets/images/background3.png';
        break;
      default:
        _backgroundImage = 'assets/images/background2.png';
    }
  }

  void _gameLoop() {
    _gameController.update(_horizontalInput);
    setState(() {});
  }

  void _jump() {
    setState(() {
      _gameController.jump();
    });
  }

  void _restartGame() {
    setState(() {
      _gameController.restart();
    });
    _audioPlayer.resume();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sensorSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            ...[0.0, 1.0].map(
              (offset) => Transform.translate(
                offset: Offset(
                  0,
                  (MediaQuery.of(context).size.height) *
                      (_gameController.backgroundOffsetY - offset),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_backgroundImage),
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeatY,
                    ),
                  ),
                ),
              ),
            ),

            ..._gameController.obstacles.map(
              (obstacle) => Align(
                alignment: Alignment(
                  obstacle.position.dx,
                  obstacle.position.dy,
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.asset('assets/images/alien.png'),
                ),
              ),
            ),

            Align(
              alignment: Alignment(
                _gameController.player.position.dx,
                _gameController.player.position.dy,
              ),
              child: Transform.rotate(
                angle: _gameController.player.rotationAngle,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset('assets/images/Astronauta1.png'),
                ),
              ),
            ),

            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'PONTOS: ${_gameController.score}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            if (_gameController.isGameOver)
              GameOverOverlay(
                score: _gameController.score,
                onRestart: _restartGame,
              ),

            if (_gameController.isLevelComplete)
              LevelCompleteOverlay(
                buttonText: 'Próxima Fase',
                onContinue: () {
                  if (widget.level == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ShooterScreen(difficulty: widget.difficulty),
                      ),
                    );
                  } else {}
                },
              ),
          ],
        ),
      ),
    );
  }
}
