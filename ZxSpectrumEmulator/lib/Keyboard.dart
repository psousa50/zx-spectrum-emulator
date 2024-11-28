import 'package:ZxSpectrum/Keyboard/ZxKeys.dart';
import 'package:flutter/material.dart';

import 'ZxKey.dart';
import 'package:ZxSpectrum/Keyboard/KeyboardListener.dart' as ZXSpectrum;

class KeyboardPanel extends StatelessWidget {
  final List<ZXSpectrum.KeyboardListener> listeners;

  KeyboardPanel(this.listeners);

  void onKeyPress(ZxKey key, bool pressed) {
    listeners.forEach((l) {
      pressed ? l.keyDown(key) : l.keyUp(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Spacer(),
        ZxKeyView("1", ZxKey.K_1, onKeyPress),
        ZxKeyView("2", ZxKey.K_2, onKeyPress),
        ZxKeyView("3", ZxKey.K_3, onKeyPress),
        ZxKeyView("4", ZxKey.K_4, onKeyPress),
        ZxKeyView("5", ZxKey.K_5, onKeyPress),
        ZxKeyView("6", ZxKey.K_6, onKeyPress),
        ZxKeyView("7", ZxKey.K_7, onKeyPress),
        ZxKeyView("8", ZxKey.K_8, onKeyPress),
        ZxKeyView("9", ZxKey.K_9, onKeyPress),
        ZxKeyView("0", ZxKey.K_0, onKeyPress),
        Spacer(),
      ]),
      Row(
        children: [
          Spacer(),
          ZxKeyView("Q", ZxKey.K_Q, onKeyPress),
          ZxKeyView("W", ZxKey.K_W, onKeyPress),
          ZxKeyView("E", ZxKey.K_E, onKeyPress),
          ZxKeyView("R", ZxKey.K_R, onKeyPress),
          ZxKeyView("T", ZxKey.K_T, onKeyPress),
          ZxKeyView("Y", ZxKey.K_Y, onKeyPress),
          ZxKeyView("U", ZxKey.K_U, onKeyPress),
          ZxKeyView("I", ZxKey.K_I, onKeyPress),
          ZxKeyView("O", ZxKey.K_O, onKeyPress),
          ZxKeyView("P", ZxKey.K_P, onKeyPress),
          Spacer(),
        ],
      ),
      Row(
        children: [
          Spacer(),
          ZxKeyView("A", ZxKey.K_A, onKeyPress),
          ZxKeyView("S", ZxKey.K_S, onKeyPress),
          ZxKeyView("D", ZxKey.K_D, onKeyPress),
          ZxKeyView("F", ZxKey.K_F, onKeyPress),
          ZxKeyView("G", ZxKey.K_G, onKeyPress),
          ZxKeyView("H", ZxKey.K_H, onKeyPress),
          ZxKeyView("J", ZxKey.K_J, onKeyPress),
          ZxKeyView("K", ZxKey.K_K, onKeyPress),
          ZxKeyView("L", ZxKey.K_L, onKeyPress),
          ZxKeyView("<-", ZxKey.K_ENTER, onKeyPress),
          Spacer(),
        ],
      ),
      Row(
        children: [
          Spacer(),
          ZxKeyView("cs", ZxKey.K_CAPS, onKeyPress, toggle: true),
          ZxKeyView("Z", ZxKey.K_Z, onKeyPress),
          ZxKeyView("X", ZxKey.K_X, onKeyPress),
          ZxKeyView("C", ZxKey.K_C, onKeyPress),
          ZxKeyView("V", ZxKey.K_V, onKeyPress),
          ZxKeyView("B", ZxKey.K_B, onKeyPress),
          ZxKeyView("N", ZxKey.K_N, onKeyPress),
          ZxKeyView("M", ZxKey.K_M, onKeyPress),
          ZxKeyView("ss", ZxKey.K_SYM, onKeyPress, toggle: true),
          ZxKeyView("b", ZxKey.K_SPACE, onKeyPress),
          Spacer(),
        ],
      )
    ]);
  }
}
