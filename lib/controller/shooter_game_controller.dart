import 'dart:math';
import 'dart:ui';

import '../models/boss.dart';
import '../models/difficulty.dart';
import '../models/obstacle.dart';
import '../models/player.dart';
import '../models/projectile.dart';
import 'base_game_controller.dart';

class ShooterGameController extends BaseGameController {
  late final Player player;
  late final Boss boss;
  final List<Obstacle> enemies = [];
  final List<Projectile> playerProjectiles = [];
  final List<Projectile> enemyProjectiles = [];

  @override
  int score = 0;

  @override
  bool isGameOver = false;

  bool isGameWon = false;
  @override
  bool get isLevelComplete => isGameWon;

  int _frameCounter = 0;
  double backgroundOffsetY = 0.0;
  final _random = Random();

  final Difficulty difficulty;
  final int _winScore = 20;
  final double _backgroundScrollSpeed = 0.002;

  ShooterGameController({required this.difficulty}) {
    player = Player();

    boss = Boss(maxHealth: _getBossMaxHealth());
  }

  double _getBossMaxHealth() {
    switch (difficulty) {
      case Difficulty.facil:
        return 20;
      case Difficulty.medio:
        return 35;
      case Difficulty.dificil:
        return 50;
    }
  }

  @override
  void update(double horizontalInput) {
    if (isGameOver || isGameWon) return;

    _frameCounter++;
    backgroundOffsetY = (backgroundOffsetY + _backgroundScrollSpeed) % 1;

    _updatePlayerPosition(horizontalInput);
    _handleSpawningAndShooting();
    _updateGameObjects();
    _handleCollisions();
    _cleanupOffscreenObjects();
  }

  @override
  void restart() {
    isGameOver = false;
    isGameWon = false;
    score = 0;
    player.reset();
    boss.reset();
    enemies.clear();
    playerProjectiles.clear();
    enemyProjectiles.clear();
    _frameCounter = 0;
    backgroundOffsetY = 0.0;
  }

  void _updatePlayerPosition(double horizontalInput) {
    const double smoothingFactor = 0.05;
    player.positionX = lerpDouble(
      player.positionX,
      horizontalInput,
      smoothingFactor,
    )!;
    player.positionX = player.positionX.clamp(-1.0, 1.0);
  }

  void _handleSpawningAndShooting() {
    if (!boss.isActive && score >= _winScore) {
      boss.isActive = true;
      boss.isInvincible = true;
      enemies.clear();
    }

    if (_frameCounter % 20 == 0) _playerShoot();

    if (boss.isActive && !boss.isInvincible && _frameCounter % 90 == 0) {
      _bossShoot();
    }

    bool canSpawnEnemies = !boss.isActive || difficulty != Difficulty.facil;
    if (canSpawnEnemies) {
      final int enemySpawnRate = boss.isActive ? 120 : 45;
      if (_frameCounter % enemySpawnRate == 0) _spawnEnemy();
    }

    bool canEnemiesShoot =
        (!boss.isActive && difficulty != Difficulty.facil) ||
        (boss.isActive && difficulty == Difficulty.dificil);
    if (canEnemiesShoot) {
      for (var enemy in enemies) {
        if (_random.nextDouble() < 0.008) _enemyShoot(enemy.position);
      }
    }
  }

  void _updateGameObjects() {
    for (var p in playerProjectiles) p.position += p.velocity;

    for (var e in enemies) e.position += e.velocity;

    _updateEnemyProjectiles();

    if (boss.isActive) _updateBossPosition();
  }

  void _handleCollisions() {
    final List<Projectile> projectilesToRemove = [];
    final List<Obstacle> enemiesToRemove = [];

    for (var p in playerProjectiles) {
      for (var e in enemies) {
        if ((p.position - e.position).distance < 0.15) {
          projectilesToRemove.add(p);
          enemiesToRemove.add(e);
          if (!boss.isActive) score++;
        }
      }

      if (boss.isActive && !boss.isInvincible) {
        final bossRect = Rect.fromCenter(
          center: boss.position,
          width: 0.3,
          height: 0.3,
        );
        if (bossRect.contains(p.position)) {
          projectilesToRemove.add(p);
          boss.health--;
          if (boss.health <= 0) isGameWon = true;
        }
      }
    }

    for (var p in enemyProjectiles) {
      if ((p.position - player.position).distance < player.radius) {
        projectilesToRemove.add(p);
        isGameOver = true;
      }
    }

    for (var e in enemies) {
      if ((e.position - player.position).distance < 0.18) {
        enemiesToRemove.add(e);
        isGameOver = true;
      }
    }

    playerProjectiles.removeWhere((p) => projectilesToRemove.contains(p));
    enemyProjectiles.removeWhere((p) => projectilesToRemove.contains(p));
    enemies.removeWhere((e) => enemiesToRemove.contains(e));
  }

  void _cleanupOffscreenObjects() {
    playerProjectiles.removeWhere((p) => p.position.dy < -1.2);
    enemyProjectiles.removeWhere(
      (p) => p.position.dy > 1.2 || p.position.dy < -1.2,
    );
    enemies.removeWhere((e) => e.position.dy > 1.2);
  }

  void _spawnEnemy() {
    enemies.add(Obstacle(
      position: Offset(_random.nextDouble() * 2 - 1, -1.2),
      velocity: const Offset(0, 0.01),
      gravityFieldRadius: 0,
    ));
  }

  void _playerShoot() {
    playerProjectiles.add(
      Projectile(
        position: player.position.translate(0, -0.05),
        velocity: const Offset(0, -0.05),
        type: ProjectileType.player,
      ),
    );
  }

  void _enemyShoot(Offset position) {
    enemyProjectiles.add(
      Projectile(
        position: position,
        velocity: const Offset(0, 0.03),
        type: ProjectileType.enemyStraight,
      ),
    );
  }

  void _bossShoot() {
    if (_random.nextBool()) {
      enemyProjectiles.add(
        Projectile(
          position: boss.position,
          type: ProjectileType.bossHoming,
          homingDuration: 45,
        ),
      );
    } else {
      enemyProjectiles.add(
        Projectile(
          position: boss.position,
          velocity: const Offset(0, 0.02),
          type: ProjectileType.bossExploder,
        ),
      );
    }
  }

  void _updateEnemyProjectiles() {
    final newProjectiles = <Projectile>[];
    final projectilesToRemove = <Projectile>[];

    for (var p in enemyProjectiles) {
      switch (p.type) {
        case ProjectileType.bossHoming:
          if (p.homingDuration > 0) {
            final distanceVector = player.position - p.position;
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
              newProjectiles.add(
                Projectile(
                  position: p.position,
                  velocity: Offset(sin(radians), cos(radians).abs()) * 0.03,
                  type: ProjectileType.bossFragment,
                ),
              );
            }
          }
          break;
        default:
          break;
      }
      p.position += p.velocity;
    }

    enemyProjectiles.addAll(newProjectiles);
    enemyProjectiles.removeWhere((p) => projectilesToRemove.contains(p));
  }

  void _updateBossPosition() {
    const double bossEntrySpeed = 0.005;

    if (boss.position.dy < boss.targetPosition.dy) {
      boss.position = Offset(
        boss.position.dx,
        boss.position.dy + bossEntrySpeed,
      );
    } else if (boss.isInvincible) {
      boss.isInvincible = false;
    }

    final double distanceToTargetX = (boss.position.dx - boss.targetPosition.dx)
        .abs();
    if (distanceToTargetX < 0.1) {
      boss.targetPosition = Offset(
        _random.nextDouble() * 1.6 - 0.8,
        boss.targetPosition.dy,
      );
    }
    boss.position = Offset(
      lerpDouble(boss.position.dx, boss.targetPosition.dx, 0.02)!,
      boss.position.dy,
    );
  }
}
