import 'package:ZxSpectrum/Ports/PortHandler.dart';
import 'JoystickListener.dart';

class KempstonJoystick with PortHandler, JoystickListener {
  static const K_FIRE = 0x0010;
  static const K_UP = 0x0008;
  static const K_DOWN = 0x0004;
  static const K_LEFT = 0x0002;
  static const K_RIGHT = 0x0001;

  int state = 0x00;

  @override
  int read(int port) => state;

  @override
  void write(int port, int value) {}

  void update(int bit, bool active) {
    state = active ? state | bit : state & (0xFF ^ bit);
  }

  void up(bool active) {
    update(K_UP, active);
    if (active) update(K_DOWN, !active);
  }

  void down(bool active) {
    update(K_DOWN, active);
    if (active) update(K_UP, !active);
  }

  void left(bool active) {
    update(K_LEFT, active);
    if (active) update(K_RIGHT, !active);
  }

  void right(bool active) {
    update(K_RIGHT, active);
    if (active) update(K_LEFT, !active);
  }

  void fire(bool active) {
    update(K_FIRE, active);
  }

  @override
  void onJoystickAction(JoystickAction action, bool active) {
    switch (action) {
      case JoystickAction.left:
        left(active);
        break;
      case JoystickAction.right:
        right(active);
        break;
      case JoystickAction.up:
        up(active);
        break;
      case JoystickAction.down:
        down(active);
        break;
      case JoystickAction.fire:
        fire(active);
        break;
    }
  }
}
