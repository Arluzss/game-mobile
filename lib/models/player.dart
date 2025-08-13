import 'dart:ui';

class Player {
  double positionX;

  final double radius;

  Player({this.positionX = 0.0, this.radius = 0.1});

  Offset get position => Offset(positionX, 0.8);
  
  void reset() {
    positionX = 0.0;
  }
}
