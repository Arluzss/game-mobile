import 'dart:ui';

class Boss {
  Offset position;
  Offset targetPosition;
  double health;
  final double maxHealth;

  bool isActive;
  bool isInvincible;

  final double width;
  final double height;

  Boss({required this.maxHealth})
    : health = maxHealth,
      position = const Offset(0.0, -1.3),
      targetPosition = const Offset(0.0, -0.9),
      isActive = false,
      isInvincible = false,
      width = 120.0,
      height = 120.0;

  void reset() {
    health = maxHealth;
    position = const Offset(0.0, -1.3);
    targetPosition = const Offset(0.0, -0.9);
    isActive = false;
    isInvincible = false;
  }
}
