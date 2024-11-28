enum JoystickAction {
  left,
  right,
  up,
  down,
  fire,
}

mixin JoystickListener {
  void onJoystickAction(JoystickAction action, bool active);
}
