import 'KempstonJoystick.dart';
import '../Ports/PortHandler.dart';

import 'JoystickListener.dart';

class KempstonJoystickAutoUp extends KempstonJoystick
    with PortHandler, JoystickListener {
  static const K_FIRE = 0x0010;
  static const K_UP = 0x0008;
  static const K_DOWN = 0x0004;
  static const K_LEFT = 0x0002;
  static const K_RIGHT = 0x0001;

  @override
  int read(int port) => state & K_DOWN == K_DOWN ? state : state | K_UP;

  void up(bool active) {}

  void down(bool active) {}

  void fire(bool active) {
    update(K_DOWN, active);
  }
}
