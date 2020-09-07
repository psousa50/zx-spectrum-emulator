import 'package:flutter/material.dart';

import 'package:ZxSpectrum/ZxKeys.dart';

import 'ZxSpectrumKey.dart';

class Keyboard extends StatelessWidget {
  final OnKeyEvent onKeyPress;

  Keyboard(this.onKeyPress);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        ZxSpectrumKeyView("1", ZxKey.K_1, onKeyPress),
        ZxSpectrumKeyView("2", ZxKey.K_2, onKeyPress),
        ZxSpectrumKeyView("3", ZxKey.K_3, onKeyPress),
        ZxSpectrumKeyView("4", ZxKey.K_4, onKeyPress),
        ZxSpectrumKeyView("5", ZxKey.K_5, onKeyPress),
        ZxSpectrumKeyView("6", ZxKey.K_6, onKeyPress),
        ZxSpectrumKeyView("7", ZxKey.K_7, onKeyPress),
        ZxSpectrumKeyView("8", ZxKey.K_8, onKeyPress),
        ZxSpectrumKeyView("9", ZxKey.K_9, onKeyPress),
        ZxSpectrumKeyView("0", ZxKey.K_0, onKeyPress),
      ]),
      Row(
        children: [
          ZxSpectrumKeyView("Q", ZxKey.K_Q, onKeyPress),
          ZxSpectrumKeyView("W", ZxKey.K_W, onKeyPress),
          ZxSpectrumKeyView("E", ZxKey.K_E, onKeyPress),
          ZxSpectrumKeyView("R", ZxKey.K_R, onKeyPress),
          ZxSpectrumKeyView("T", ZxKey.K_T, onKeyPress),
          ZxSpectrumKeyView("Y", ZxKey.K_Y, onKeyPress),
          ZxSpectrumKeyView("U", ZxKey.K_U, onKeyPress),
          ZxSpectrumKeyView("I", ZxKey.K_I, onKeyPress),
          ZxSpectrumKeyView("O", ZxKey.K_O, onKeyPress),
          ZxSpectrumKeyView("P", ZxKey.K_P, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView("A", ZxKey.K_A, onKeyPress),
          ZxSpectrumKeyView("S", ZxKey.K_S, onKeyPress),
          ZxSpectrumKeyView("D", ZxKey.K_D, onKeyPress),
          ZxSpectrumKeyView("F", ZxKey.K_F, onKeyPress),
          ZxSpectrumKeyView("G", ZxKey.K_G, onKeyPress),
          ZxSpectrumKeyView("H", ZxKey.K_H, onKeyPress),
          ZxSpectrumKeyView("J", ZxKey.K_J, onKeyPress),
          ZxSpectrumKeyView("K", ZxKey.K_K, onKeyPress),
          ZxSpectrumKeyView("L", ZxKey.K_L, onKeyPress),
          ZxSpectrumKeyView("<-", ZxKey.K_ENTER, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView("cs", ZxKey.K_CAPS, onKeyPress, toggle: true),
          ZxSpectrumKeyView("Z", ZxKey.K_Z, onKeyPress),
          ZxSpectrumKeyView("X", ZxKey.K_X, onKeyPress),
          ZxSpectrumKeyView("C", ZxKey.K_C, onKeyPress),
          ZxSpectrumKeyView("V", ZxKey.K_V, onKeyPress),
          ZxSpectrumKeyView("B", ZxKey.K_B, onKeyPress),
          ZxSpectrumKeyView("N", ZxKey.K_N, onKeyPress),
          ZxSpectrumKeyView("M", ZxKey.K_M, onKeyPress),
          ZxSpectrumKeyView("ss", ZxKey.K_SYM, onKeyPress, toggle: true),
          ZxSpectrumKeyView("b", ZxKey.K_SPACE, onKeyPress),
        ],
      )
    ]);
  }
}
