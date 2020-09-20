import 'package:ZxSpectrum/JoystickListener.dart';
import 'package:ZxSpectrum/KeyboardListener.dart';
import 'package:ZxSpectrum/ZxKeys.dart';

class KeymapJoystick with JoystickListener {
  final KeyboardListener keyboardOperator;
  final ZxKey left;
  final ZxKey right;
  final ZxKey up;
  final ZxKey down;
  final ZxKey fire;

  KeymapJoystick(this.keyboardOperator, this.left, this.right, this.up,
      this.down, this.fire);

  void onAction(ZxKey key, bool active) {
    active ? keyboardOperator.keyDown(key) : keyboardOperator.keyUp(key);
  }

  @override
  void onJoystickAction(JoystickAction action, bool active) {
    switch (action) {
      case JoystickAction.left:
        onAction(left, active);
        break;
      case JoystickAction.right:
        onAction(right, active);
        break;
      case JoystickAction.up:
        onAction(up, active);
        break;
      case JoystickAction.down:
        onAction(down, active);
        break;
      case JoystickAction.fire:
        onAction(fire, active);
        break;
    }
  }
}
