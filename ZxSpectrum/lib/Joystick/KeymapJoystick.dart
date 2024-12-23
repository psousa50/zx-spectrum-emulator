import 'JoystickListener.dart';
import '../Keyboard/KeyboardListener.dart';
import '../Keyboard/ZxKeys.dart';

class KeyMap {
  final ZxKey left;
  final ZxKey right;
  final ZxKey up;
  final ZxKey down;
  final ZxKey fire;

  KeyMap(
      {this.left = ZxKey.K_0,
      this.right = ZxKey.K_0,
      this.up = ZxKey.K_0,
      this.down = ZxKey.K_0,
      this.fire = ZxKey.K_0});
}

class KeymapJoystick with JoystickListener {
  final KeyboardListener keyboardOperator;
  final KeyMap keyMap;

  KeymapJoystick(this.keyboardOperator, this.keyMap);

  void onAction(ZxKey key, bool active) {
    active ? keyboardOperator.keyDown(key) : keyboardOperator.keyUp(key);
  }

  @override
  void onJoystickAction(JoystickAction action, bool active) {
    switch (action) {
      case JoystickAction.left:
        onAction(keyMap.left, active);
        break;
      case JoystickAction.right:
        onAction(keyMap.right, active);
        break;
      case JoystickAction.up:
        onAction(keyMap.up, active);
        break;
      case JoystickAction.down:
        onAction(keyMap.down, active);
        break;
      case JoystickAction.fire:
        onAction(keyMap.fire, active);
        break;
    }
  }
}
