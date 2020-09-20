import 'ZxKeys.dart';

abstract class KeyboardListener {
  void keyDown(ZxKey key);
  void keyUp(ZxKey key);
}
