abstract class BaseGameController {
  int get score;
  bool get isGameOver;
  bool get isLevelComplete;

  void update(double horizontalInput);
  void restart();

  void dispose() {}
}
