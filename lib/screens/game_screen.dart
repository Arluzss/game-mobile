import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:game/models/difficulty.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/obstacle.dart';
import 'shooter_screen.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final Difficulty difficulty;

  const GameScreen({
    super.key,
    required this.level,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription? _sensorSubscription;

  double _autoScrollSpeed = 0.0;

  bool _isGameOver = false;
  bool _isLevelComplete = false;
  int _score = 0;
  double _horizontalInput = 0.0;
  double _ballPositionX = 0.0;
  double _ballPositionY = 0.5;
  double _ballVelocityY = 0;
  double _ballVelocityX = 0.0;
  late String _backgroundImage;
  final List<Obstacle> _obstacles = [];

  final double _jumpStrength = 0.07;
  final double _gravity = 0.003;
  final double _ballRadius = 0.05;
  final double _platformHeight = 20.0;

  double _rotationAngle = 0.0;

  late final AudioPlayer _audioPlayer;

  double _backgroundOffsetY = 0.0;
  final double _backgroundScrollSpeed = 0.002;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _playBackgroundMusic();

    switch (widget.difficulty) {
      case Difficulty.facil:
        _autoScrollSpeed = 0.0;
        break;
      case Difficulty.medio:
        _autoScrollSpeed = 0.008;
        break;
      case Difficulty.dificil:
        _autoScrollSpeed = 0.010;
        break;
    }

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

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_gameLoop)
          ..repeat();

    _sensorSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!_isGameOver) {
        const double sensitivity = 10.0;
        _horizontalInput = (_ballPositionX - (event.x / sensitivity)).clamp(
          -1.0,
          1.0,
        );
      }
    });

    _generateInitialObstacles();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _audioPlayer.play(AssetSource('music/WhispersWonder.mp3'));
    } catch (e) {
      print("Erro ao carregar ou tocar a música: $e");
    }
  }

  void _generateInitialObstacles() {
    final random = Random();
    
    final bool shouldMove = widget.difficulty == Difficulty.medio || widget.difficulty == Difficulty.dificil;

    for (int i = 0; i < 10; i++) {
      bool canThisObstacleMove = false;
      double speed = 0;

      
      if (shouldMove && random.nextBool()) {
        canThisObstacleMove = true;
        
        speed = 0.005 + random.nextDouble() * 0.005;
      }

      _obstacles.add(
        Obstacle(
            position: Offset(random.nextDouble() * 2 - 1, -1.5 - (i * 1.5)),
            velocity: Offset.zero,
            gravityFieldRadius: 3,
            
            canMove: canThisObstacleMove,
            horizontalSpeed: speed,
            direction: random.nextBool() ? 1 : -1 
            ),
      );
    }
  }

  void _gameLoop() {
    if (_isGameOver || _isLevelComplete) return;

    
    const double smoothingFactor = 0.1;
    _ballPositionX = lerpDouble(
      _ballPositionX,
      _horizontalInput,
      smoothingFactor,
    )!;

    
    _ballPositionX += _ballVelocityX;
    
    _ballVelocityY += _gravity;

    

    
    if (widget.difficulty == Difficulty.medio ||
        widget.difficulty == Difficulty.dificil) {
      for (var obstacle in _obstacles) {
        if (obstacle.canMove) {
          
          obstacle.position = Offset(
            obstacle.position.dx + (obstacle.horizontalSpeed * obstacle.direction),
            obstacle.position.dy,
          );

          
          if (obstacle.position.dx > 1.0 || obstacle.position.dx < -1.0) {
            obstacle.direction *= -1;
          }
        }
      }
    }

    if (widget.difficulty == Difficulty.dificil) {
      Offset totalGravityForce = Offset.zero;
      for (var obstacle in _obstacles) {
        final distanceVector =
            obstacle.position - Offset(_ballPositionX, _ballPositionY);
        final distance = distanceVector.distance;
        
        const double attractionRadius = 1.5; 

        
        if (distance < attractionRadius && distance > 0.02) {
          
          final double pullStrength = 1 / distance;
          
          final direction = distanceVector / distance;
          
          totalGravityForce += direction * pullStrength;
        }
      }

      const double attractionFactor = 0.002;

      _ballVelocityY += totalGravityForce.dy * attractionFactor;
      _ballVelocityX += totalGravityForce.dx * attractionFactor;

      _ballVelocityY = _ballVelocityY.clamp(-0.15, 0.15);
      _ballVelocityX = _ballVelocityX.clamp(-0.1, 0.1);
    }
    
    _ballPositionY += _ballVelocityY;

    if (_autoScrollSpeed > 0) {
      _ballPositionY += _autoScrollSpeed;
      for (var obstacle in _obstacles) {
        obstacle.position =
            Offset(obstacle.position.dx, obstacle.position.dy + _autoScrollSpeed);
      }
    }

    
    if (_ballPositionY < 0 && _ballVelocityY < 0) {
      for (var obstacle in _obstacles) {
        obstacle.position = Offset(
          obstacle.position.dx,
          obstacle.position.dy - _ballVelocityY,
        );
      }
      _ballPositionY -= _ballVelocityY;
    }

    
    if (_ballPositionY > 1.0) {
      _ballPositionY = 1.0;
      _ballVelocityY = 0;
      _ballVelocityX *= 0.9; 
    }

    
    if (_ballVelocityY > 0) {
      _rotationAngle = 0.3;
    }

    
    for (var obstacle in _obstacles) {
      final distance =
          (Offset(_ballPositionX, _ballPositionY) - obstacle.position).distance;
      if (distance < _ballRadius + obstacle.radius) {
        setState(() => _isGameOver = true);
      }
    }

    
    final List<Obstacle> newObstacles = [];
    _obstacles.removeWhere((obstacle) {
      if (obstacle.position.dy > 1.2) {
        final random = Random();
        _score++;

        final bool shouldMove = widget.difficulty == Difficulty.medio || widget.difficulty == Difficulty.dificil;
        bool canThisObstacleMove = false;
        double speed = 0;

        if (shouldMove && random.nextBool()) {
          canThisObstacleMove = true;
          speed = 0.005 + random.nextDouble() * 0.005;
        }

        newObstacles.add(
          Obstacle(
              position: Offset(
                random.nextDouble() * 2 - 1,
                _obstacles.last.position.dy - 1.5,
              ),
              velocity: Offset.zero,
              gravityFieldRadius: 3,
              canMove: canThisObstacleMove,
              horizontalSpeed: speed,
              direction: random.nextBool() ? 1 : -1),
        );

        if (widget.level == 1 && _score >= 4) {
          _isLevelComplete = true;
        }
        return true;
      }
      return false;
    });
    _obstacles.addAll(newObstacles);

    
    setState(() {
      _backgroundOffsetY += _backgroundScrollSpeed;
      if (_backgroundOffsetY > 1) {
        _backgroundOffsetY -= 1;
      }
    });
  }
  void _jump() {
    if (!_isGameOver) {
      setState(() {
        _ballVelocityY = -_jumpStrength;
        _rotationAngle = -0.2;
      });
    }
  }

  void _restartGame() {
    setState(() {
      _isGameOver = false;
      _isLevelComplete = false;
      _score = 0;
      _ballPositionX = 0.0;
      _ballPositionY = 0.5;
      _ballVelocityY = 0;
      _ballVelocityX = 0;
      _horizontalInput = 0.0;
      _obstacles.clear();
      _generateInitialObstacles();
      _audioPlayer.resume();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
          children: [
            Transform.translate(
              offset: Offset(0, MediaQuery.of(context).size.height * _backgroundOffsetY),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Transform.translate(
              offset: Offset(0, MediaQuery.of(context).size.height * (_backgroundOffsetY - 1)),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            ..._obstacles.map((obstacle) => Align(
                  alignment:
                      Alignment(obstacle.position.dx, obstacle.position.dy),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Image.asset('assets/images/alien.png'),
                  ),
                )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: _platformHeight, color: Colors.green),
            ),
            Align(
              alignment: Alignment(_ballPositionX, _ballPositionY),
              child: Transform.rotate(
                angle: _rotationAngle,
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
                'PONTOS: $_score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (_isGameOver)
              Container(
                color: Colors.black.withAlpha(128),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'FIM DE JOGO',
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SUA PONTUAÇÃO: $_score',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _restartGame,
                        child: const Text(
                          'Jogar Novamente',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLevelComplete)
              Container(
                color: Colors.black.withAlpha(128),
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.level == 1) {
                             Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => ShooterScreen(difficulty: widget.difficulty)),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                    level: widget.level + 1,
                                    difficulty: widget.difficulty),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.level == 1 ? 'Continuar' : 'Próxima Fase',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}