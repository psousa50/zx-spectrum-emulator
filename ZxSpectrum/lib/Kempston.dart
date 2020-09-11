import 'package:ZxSpectrum/PortHandler.dart';

class Kempston with PortHandler {
  static const K_FIRE = 0x0010;
  static const K_UP = 0x0008;
  static const K_DOWN = 0x0004;
  static const K_LEFT = 0x0002;
  static const K_RIGHT = 0x0001;

  int state = 0x00;

  @override
  int read(int port) {
    // print(state);
    return state;
  }

  @override
  void write(int port, int value) {}

  void up() {
    state = state | K_UP;
    state = state & (0xFF - K_DOWN);
  }

  void down() {
    state = state | K_DOWN;
    state = state & (0xFF - K_UP);
  }

  void left() {
    state = state | K_LEFT;
    state = state & (0xFF - K_RIGHT);
  }

  void right() {
    state = state | K_RIGHT;
    state = state & (0xFF - K_LEFT);
  }

  void fire() {
    state = state | K_FIRE;
  }

  void stopHorizontal() {
    state = state & (0xFF - K_LEFT) & (0xFF - K_RIGHT);
  }

  void stopVertical() {
    state = state & (0xFF - K_UP) & (0xFF - K_DOWN);
  }

  void stopFire() {
    state = state & (0xFF - K_FIRE);
  }
}
