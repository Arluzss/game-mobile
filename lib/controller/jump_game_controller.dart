import 'dart:math';
import 'dart:ui';

import 'base_game_controller.dart';
import '../models/difficulty.dart';
import '../models/jumper_player.dart';
import '../models/obstacle.dart';

class JumperGameController extends BaseGameController {
  JumperPlayer player = JumperPlayer();

  final List<Obstacle> obstacles = [];

  @override
  bool isGameOver = false;

  @override
  bool isLevelComplete = false;

  @override
  int score = 0;

  double backgroundOffsetY = 0.0;

  final Difficulty difficulty;
  final int level;
  final double _gravity = 0.003;
  final double _jumpStrength = 0.07;
  final int _winScore = 20;
  final double _backgroundScrollSpeed = 0.002;
  double _autoScrollSpeed = 0.0;
  final _random = Random();

  JumperGameController({required this.difficulty, required this.level}) {
    _setupDifficulty();
    _generateInitialObstacles();
  }

  void _setupDifficulty() {
    switch (difficulty) {
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
  }

  void _generateInitialObstacles() {
    final bool shouldMove =
        difficulty == Difficulty.medio || difficulty == Difficulty.dificil;

    for (int i = 0; i < 10; i++) {
      bool canThisObstacleMove = false;
      double speed = 0;

      if (shouldMove && _random.nextBool()) {
        canThisObstacleMove = true;
        speed = 0.005 + _random.nextDouble() * 0.005;
      }

      obstacles.add(
        Obstacle(
          position: Offset(_random.nextDouble() * 2 - 1, -1.5 - (i * 1.5)),
          canMove: canThisObstacleMove,
          horizontalSpeed: speed,
          direction: _random.nextBool() ? 1 : -1,
          gravityFieldRadius: 3,
          velocity: Offset.zero,
        ),
      );
    }
  }

  @override
  void update(double horizontalInput) {
    if (isGameOver || isLevelComplete) return;

    _updatePlayerPosition(horizontalInput);
    _applyGamePhysics();
    _updateObstacles();
    _handleCollisions();
    _recycleAndGenerateObstacles();
    _checkWinCondition();

    backgroundOffsetY = (backgroundOffsetY + _backgroundScrollSpeed) % 1;
  }

  @override
  void restart() {
    isGameOver = false;
    isLevelComplete = false;
    score = 0;
    player = JumperPlayer();
    obstacles.clear();
    _generateInitialObstacles();
  }

  void jump() {
    if (!isGameOver) {
      player.velocity = Offset(player.velocity.dx, -_jumpStrength);
      player.rotationAngle = -0.2;
    }
  }

  void _updatePlayerPosition(double horizontalInput) {
    const double smoothingFactor = 0.1;
    final newX = lerpDouble(
      player.position.dx,
      horizontalInput,
      smoothingFactor,
    )!;
    player.position = Offset(newX, player.position.dy);
  }

  void _applyGamePhysics() {
    player.velocity = Offset(player.velocity.dx, player.velocity.dy + _gravity);

    if (difficulty == Difficulty.dificil) {
      _applyObstacleGravity();
    }

    player.position += player.velocity;

    if (player.position.dy < 0 && player.velocity.dy < 0) {
      for (var obstacle in obstacles) {
        obstacle.position = Offset(
          obstacle.position.dx,
          obstacle.position.dy - player.velocity.dy,
        );
      }
      player.position = Offset(
        player.position.dx,
        player.position.dy - player.velocity.dy,
      );
    }

    if (_autoScrollSpeed > 0) {
      player.position = Offset(
        player.position.dx,
        player.position.dy + _autoScrollSpeed,
      );
      for (var obstacle in obstacles) {
        obstacle.position = Offset(
          obstacle.position.dx,
          obstacle.position.dy + _autoScrollSpeed,
        );
      }
    }

    if (player.position.dy > 1.0) {
      player.position = Offset(player.position.dx, 1.0);
      player.velocity = Offset(player.velocity.dx * 0.9, 0);
    }

    if (player.velocity.dy > 0) {
      player.rotationAngle = 0.3;
    }
  }

  void _updateObstacles() {
    if (difficulty == Difficulty.medio || difficulty == Difficulty.dificil) {
      for (var obstacle in obstacles) {
        if (obstacle.canMove) {
          obstacle.position += Offset(
            obstacle.horizontalSpeed * obstacle.direction,
            0,
          );
          if (obstacle.position.dx.abs() > 1.0) {
            obstacle.direction *= -1;
          }
        }
      }
    }
  }

  void _applyObstacleGravity() {
    Offset totalGravityForce = Offset.zero;
    for (var obstacle in obstacles) {
      final distanceVector = obstacle.position - player.position;
      final distance = distanceVector.distance;
      const double attractionRadius = 1.5;

      if (distance < attractionRadius && distance > 0.02) {
        final double pullStrength = 1 / distance;
        final direction = distanceVector / distance;
        totalGravityForce += direction * pullStrength;
      }
    }
    const double attractionFactor = 0.002;
    player.velocity += totalGravityForce * attractionFactor;
    player.velocity = Offset(
      player.velocity.dx.clamp(-0.1, 0.1),
      player.velocity.dy.clamp(-0.15, 0.15),
    );
  }

  void _handleCollisions() {
    for (var obstacle in obstacles) {
      final distance = (player.position - obstacle.position).distance;
      if (distance < player.radius + obstacle.radius) {
        isGameOver = true;
      }
    }
  }

  void _recycleAndGenerateObstacles() {
    final List<Obstacle> obstaclesToRemove = [];
    int newObstaclesCount = 0;

    for (final obstacle in obstacles) {
      if (obstacle.position.dy > 1.2) {
        score++;
        newObstaclesCount++;
        obstaclesToRemove.add(obstacle);
      }
    }

    obstacles.removeWhere((obstacle) => obstaclesToRemove.contains(obstacle));

    for (int i = 0; i < newObstaclesCount; i++) {
      _generateSingleObstacleAtTop();
    }
  }

  void _generateSingleObstacleAtTop() {
    final bool shouldMove =
        difficulty == Difficulty.medio || difficulty == Difficulty.dificil;
    bool canThisObstacleMove = false;
    double speed = 0;

    if (shouldMove && _random.nextBool()) {
      canThisObstacleMove = true;
      speed = 0.005 + _random.nextDouble() * 0.005;
    }

    final double newYPosition = obstacles.isNotEmpty
        ? obstacles.last.position.dy - 1.5
        : -1.5;

    obstacles.add(
      Obstacle(
        position: Offset(_random.nextDouble() * 2 - 1, newYPosition),
        canMove: canThisObstacleMove,
        horizontalSpeed: speed,
        direction: _random.nextBool() ? 1 : -1,
        gravityFieldRadius: 3,
        velocity: Offset.zero,
      ),
    );
  }

  void _checkWinCondition() {
    if (level == 1 && score >= _winScore) {
      isLevelComplete = true;
    }
  }
}
