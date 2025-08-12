

import 'dart:ui';


enum ProjectileType {
  player,
  enemyStraight,
  bossHoming,
  bossExploder, 
  bossFragment, 
}

class Projectile {
  Offset position;
  Offset velocity;
  ProjectileType type;
  int homingDuration; 

  Projectile({
    required this.position,
    this.velocity = Offset.zero,
    required this.type,
    this.homingDuration = 0,
  });
}