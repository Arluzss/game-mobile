import 'dart:ui'; 

class JumperPlayer {
  
  Offset position;
  Offset velocity;
  double rotationAngle;
  final double radius;
  
  JumperPlayer({
    this.position = const Offset(0.0, 0.5), 
    this.velocity = Offset.zero, 
    this.rotationAngle = 0.0,    
    this.radius = 0.05,          
  });
}