import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:game/models/difficulty.dart'; 
import 'package:sensors_plus/sensors_plus.dart';

import '../models/obstacle.dart';
import '../models/projectile.dart';

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
  late final AnimationController _controller;
  StreamSubscription? _sensorSubscription;

  double _shipPositionX = 0.0;
  double _horizontalInput = 0.0;
  final List<Obstacle> _enemies = [];
  final List<Projectile> _playerProjectiles = [];
  final List<Projectile> _enemyProjectiles = [];

  final _random = Random();

  bool _isGameOver = false;
  bool _isGameWon = false;
  int _score = 0;
  final int _winScore = 4;
  int _frameCounter = 0;

  
  bool _isBossActive = false;
  bool _isBossInvincible = false;
  double _bossPositionY = -1.3;
  double _bossTargetPositionY = -0.9;
  double _bossPositionX = 0.0;
  double _bossTargetX = 0.0;
  final double _bossWidth = 120.0;
  final double _bossHeight = 120.0;

  double _bossEntrySpeed = 0.005;
  
  double _bossHealth = 30;
  double _maxBossHealth = 30;

  
  late final AudioPlayer _audioPlayer; 
  String _currentTrack = '';

  double _backgroundOffsetY = 0.0;
  final double _backgroundScrollSpeed = 0.002;

  @override
  void initState() {
    super.initState();
    _setupDifficulty(); 

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_gameLoop)
          ..repeat();

    _sensorSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_isGameOver && !_isGameWon) {
        const double sensitivity = 0.8; 
        const double deadZone = 0.1; 
        final double input = event.x * -sensitivity;

        
        if (input.abs() > deadZone) {
          _horizontalInput = input;
        } else {
          _horizontalInput = 0.0;
        }
      }
    });

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _playMusic('ElectricRush.mp3');
  }

  void _setupDifficulty() {
    switch (widget.difficulty) {
      case Difficulty.facil:
        _maxBossHealth = 20; 
        break;
      case Difficulty.medio:
        _maxBossHealth = 35; 
        break;
      case Difficulty.dificil:
        _maxBossHealth = 50; 
        break;
    }
    _bossHealth = _maxBossHealth; 
  }

  Future<void> _playMusic(String trackName) async {
    if (_currentTrack == trackName) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('music/$trackName'));
      _currentTrack = trackName;
    } catch (e) {
      print("Erro ao tocar a música '$trackName': $e");
    }
  }

  void _spawnEnemy() {
    _enemies.add(Obstacle(
        position: Offset(_random.nextDouble() * 2 - 1, -1.2),
        velocity: const Offset(0, 0.01),
        gravityFieldRadius: 0));
  }

  void _playerShoot() {
    _playerProjectiles.add(Projectile(
      position: Offset(_shipPositionX, 0.75),
      velocity: const Offset(0, -0.05),
      type: ProjectileType.player,
    ));
  }

  void _bossShoot() {
    if (_random.nextBool()) {
      _enemyProjectiles.add(Projectile(
        position: Offset(_bossPositionX, _bossPositionY),
        type: ProjectileType.bossHoming,
        homingDuration: 45,
      ));
    } else {
      _enemyProjectiles.add(Projectile(
        position: Offset(_bossPositionX, _bossPositionY),
        velocity: const Offset(0, 0.02),
        type: ProjectileType.bossExploder,
      ));
    }
  }

  void _enemyShoot(Offset position) {
    _enemyProjectiles.add(Projectile(
      position: position,
      velocity: const Offset(0, 0.03),
      type: ProjectileType.enemyStraight,
    ));
  }

  void _restartGame() {
    setState(() {
      _isGameOver = false;
      _isGameWon = false;
      _score = 0;
      _shipPositionX = 0.0;
      _horizontalInput = 0.0;
      _enemies.clear();
      _playerProjectiles.clear();
      _enemyProjectiles.clear();
      _frameCounter = 0;
      _isBossActive = false;
      _bossPositionY = -1.3;
      _bossPositionX = 0.0;
      _bossTargetX = 0.0;
      _bossHealth = _maxBossHealth; 
      _isBossInvincible = false;
      _backgroundOffsetY = 0.0;
      _playMusic('ElectricRush.mp3');
    });
  }

  void _gameLoop() {
    if (_isGameOver || _isGameWon) {
      if (_audioPlayer.state == PlayerState.playing) _audioPlayer.pause();
      return;
    }

    _frameCounter++;
    setState(() {
      _backgroundOffsetY = (_backgroundOffsetY + _backgroundScrollSpeed) % 1;
    });

    const double smoothingFactor = 0.05; 
    _shipPositionX =
        lerpDouble(_shipPositionX, _horizontalInput, smoothingFactor)!;
    _shipPositionX = _shipPositionX.clamp(-1.0, 1.0);

    if (!_isBossActive && _score >= _winScore) {
      setState(() {
        _enemies.clear();
        _isBossActive = true;
        _isBossInvincible = true;
        _playMusic('EdgeofChaos.mp3');
      });
    }

    if (_frameCounter % 20 == 0) _playerShoot();

    
    bool canEnemiesShoot = false;
    if (!_isBossActive && widget.difficulty != Difficulty.facil) {
      canEnemiesShoot = true;
    } else if (_isBossActive && widget.difficulty == Difficulty.dificil) {
      canEnemiesShoot = true;
    }

    if (canEnemiesShoot) {
      for (var enemy in _enemies) {
        if (_random.nextDouble() < 0.008) {
          _enemyShoot(enemy.position);
        }
      }
    }
    

    if (_isBossActive && !_isBossInvincible && _frameCounter % 90 == 0) {
      _bossShoot();
    }

    
    bool canSpawnEnemies = true;
    if (_isBossActive && widget.difficulty == Difficulty.facil) {
      canSpawnEnemies = false;
    }

    if (canSpawnEnemies) {
      final int enemySpawnRate = _isBossActive ? 120 : 45;
      if (_frameCounter % enemySpawnRate == 0) _spawnEnemy();
    }
    

    final playerPosition = Offset(_shipPositionX, 0.8);
    final newProjectiles = <Projectile>[];
    final projectilesToRemove = <Projectile>[];

    for (var p in _playerProjectiles) {
      p.position += p.velocity;
    }

    for (var p in _enemyProjectiles) {
      switch (p.type) {
        case ProjectileType.bossHoming:
          if (p.homingDuration > 0) {
            final distanceVector = playerPosition - p.position;
            if (distanceVector.distance > 0) {
              p.velocity = (distanceVector / distanceVector.distance) * 0.02;
            }
            p.homingDuration--;
          }
          break;
        case ProjectileType.bossExploder:
          if (p.position.dy > -0.2) {
            projectilesToRemove.add(p);
            final angles = [-70, -30, 0, 30, 70];
            for (var angle in angles) {
              final radians = angle * (pi / 180);
              newProjectiles.add(Projectile(
                position: p.position,
                velocity: Offset(sin(radians), cos(radians).abs()) * 0.03,
                type: ProjectileType.bossFragment,
              ));
            }
          }
          break;
        default:
          break;
      }
      p.position += p.velocity;
    }
    _enemyProjectiles.addAll(newProjectiles);

    for (var e in _enemies) {
      e.position += e.velocity;
    }

    if (_isBossActive) {
      if (_bossPositionY < _bossTargetPositionY) {
        _bossPositionY += _bossEntrySpeed;
      } else if (_isBossInvincible) {
        setState(() => _isBossInvincible = false);
      }

      final double distanceToTarget = (_bossPositionX - _bossTargetX).abs();
      if (distanceToTarget < 0.1) {
        _bossTargetX = _random.nextDouble() * 1.6 - 0.8;
      }
      _bossPositionX = lerpDouble(_bossPositionX, _bossTargetX, 0.02)!;
    }

    final playerProjectilesToRemove = <Projectile>[];
    final enemiesToRemove = <Obstacle>[];

    for (var p in _playerProjectiles) {
      for (var e in _enemies) {
        if ((p.position - e.position).distance < 0.15) {
          playerProjectilesToRemove.add(p);
          enemiesToRemove.add(e);
          if (!_isBossActive) _score++;
        }
      }

      if (_isBossActive && !_isBossInvincible) {
        final bossRect = Rect.fromCenter(
          center: Offset(_bossPositionX, _bossPositionY),
          width: 0.3,
          height: 0.3,
        );
        if (bossRect.contains(p.position)) {
          playerProjectilesToRemove.add(p);
          setState(() {
            _bossHealth--;
            if (_bossHealth <= 0) _isGameWon = true;
          });
        }
      }
    }

    for (var p in _enemyProjectiles) {
      if ((p.position - playerPosition).distance < 0.1) {
        projectilesToRemove.add(p);
        setState(() => _isGameOver = true);
      }
    }

    for (var e in _enemies) {
      if ((e.position - playerPosition).distance < 0.18) {
        enemiesToRemove.add(e);
        setState(() => _isGameOver = true);
      }
    }

    _playerProjectiles.removeWhere(
        (p) => playerProjectilesToRemove.contains(p) || p.position.dy < -1.2);
    _enemyProjectiles.removeWhere((p) =>
        projectilesToRemove.contains(p) ||
        p.position.dy > 1.2 ||
        p.position.dy < -1.2);
    _enemies
        .removeWhere((e) => enemiesToRemove.contains(e) || e.position.dy > 1.2);

    setState(() {});
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...[0.0, 1.0].map((offset) => Transform.translate(
                offset: Offset(
                    0,
                    (MediaQuery.of(context).size.height) *
                        (_backgroundOffsetY - offset)),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background2.png'),
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeatY,
                    ),
                  ),
                ),
              )),
          ..._enemies.map((enemy) => Align(
                alignment: Alignment(enemy.position.dx, enemy.position.dy),
                child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset('assets/images/alien.png')),
              )),
          ..._playerProjectiles.map((p) => Align(
                alignment: Alignment(p.position.dx, p.position.dy),
                child: Container(width: 10, height: 25, color: Colors.yellow),
              )),
          ..._enemyProjectiles.map((p) => Align(
                alignment: Alignment(p.position.dx, p.position.dy),
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: p.type == ProjectileType.bossExploder
                        ? Colors.amber
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )),
          Align(
            alignment: Alignment(_shipPositionX, 0.8),
            child: SizedBox(
                width: 80,
                height: 100,
                child: Image.asset('assets/images/rocket.png')),
          ),

          if (_isBossActive)
            Align(
              alignment: Alignment(_bossPositionX, _bossPositionY),
              child: SizedBox(
                width: _bossWidth,
                height: _bossHeight,
                child: Image.asset(
                  'assets/images/AlienBoss.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          if (_isBossActive)
            Positioned(
              top: 60,
              left: 10,
              child: SizedBox(
                height: 150,
                width: 30,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 30,
                        height: (150 * (_bossHealth / _maxBossHealth))
                            .clamp(0.0, 150.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 50,
            right: 20,
            child: Text(
              _isBossActive ? 'BOSS' : 'PONTOS: $_score / $_winScore',
              style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (_isGameOver)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('FIM DE JOGO',
                        style: TextStyle(
                            fontSize: 48,
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _restartGame,
                      child: const Text('Tentar Novamente',
                          style: TextStyle(fontSize: 20)),
                    )
                  ],
                ),
              ),
            ),
          if (_isGameWon)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('VOCÊ VENCEU!',
                        style: TextStyle(
                            fontSize: 48,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _restartGame,
                      child: const Text('Jogar Novamente',
                          style: TextStyle(fontSize: 20)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}