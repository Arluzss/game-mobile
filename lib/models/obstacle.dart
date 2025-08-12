

import 'dart:ui';

class Obstacle {
  Offset position;
  final Offset velocity;
  final double radius = 0.1; 
  final double gravityFieldRadius;

  
  bool canMove;
  double horizontalSpeed;
  int direction; 

  Obstacle({
    required this.position,
    required this.velocity,
    required this.gravityFieldRadius,

    
    this.canMove = false,
    this.horizontalSpeed = 0.0,
    this.direction = 1,
  });
}