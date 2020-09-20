enum JoystickAction {
  left,
  right,
  up,
  down,
  fire,
}

abstract class JoystickListener {
  void onJoystickAction(JoystickAction action, bool active);
}
