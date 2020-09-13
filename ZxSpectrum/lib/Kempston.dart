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
    return state;
  }

  @override
  void write(int port, int value) {}

  void update(bool active, int bit) {
    state = active ? state | bit : state & (0xFF ^ bit);
  }

  void up(bool active) {
    update(active, K_UP);
    if (active) update(!active, K_DOWN);
  }

  void down(bool active) {
    update(active, K_DOWN);
    if (active) update(!active, K_UP);
  }

  void left(bool active) {
    update(active, K_LEFT);
    if (active) update(!active, K_RIGHT);
  }

  void right(bool active) {
    update(active, K_RIGHT);
    if (active) update(!active, K_LEFT);
  }

  void fire(bool active) {
    update(active, K_FIRE);
  }
}
