import 'package:flutter/material.dart';

import 'package:ZxSpectrum/Ula.dart';
import 'ZxSpectrumKey.dart';

class Keyboard extends StatelessWidget {
  final OnKeyEvent onKeyPress;

  Keyboard(this.onKeyPress);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        ZxSpectrumKeyView("1", Keys.K_1, onKeyPress),
        ZxSpectrumKeyView("2", Keys.K_2, onKeyPress),
        ZxSpectrumKeyView("3", Keys.K_3, onKeyPress),
        ZxSpectrumKeyView("4", Keys.K_4, onKeyPress),
        ZxSpectrumKeyView("5", Keys.K_5, onKeyPress),
        ZxSpectrumKeyView("6", Keys.K_6, onKeyPress),
        ZxSpectrumKeyView("7", Keys.K_7, onKeyPress),
        ZxSpectrumKeyView("8", Keys.K_8, onKeyPress),
        ZxSpectrumKeyView("9", Keys.K_9, onKeyPress),
        ZxSpectrumKeyView("0", Keys.K_0, onKeyPress),
      ]),
      Row(
        children: [
          ZxSpectrumKeyView("Q", Keys.K_Q, onKeyPress),
          ZxSpectrumKeyView("W", Keys.K_W, onKeyPress),
          ZxSpectrumKeyView("E", Keys.K_E, onKeyPress),
          ZxSpectrumKeyView("R", Keys.K_R, onKeyPress),
          ZxSpectrumKeyView("T", Keys.K_T, onKeyPress),
          ZxSpectrumKeyView("Y", Keys.K_Y, onKeyPress),
          ZxSpectrumKeyView("U", Keys.K_U, onKeyPress),
          ZxSpectrumKeyView("I", Keys.K_I, onKeyPress),
          ZxSpectrumKeyView("O", Keys.K_O, onKeyPress),
          ZxSpectrumKeyView("P", Keys.K_P, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView("A", Keys.K_A, onKeyPress),
          ZxSpectrumKeyView("S", Keys.K_S, onKeyPress),
          ZxSpectrumKeyView("D", Keys.K_D, onKeyPress),
          ZxSpectrumKeyView("F", Keys.K_F, onKeyPress),
          ZxSpectrumKeyView("G", Keys.K_G, onKeyPress),
          ZxSpectrumKeyView("H", Keys.K_H, onKeyPress),
          ZxSpectrumKeyView("J", Keys.K_J, onKeyPress),
          ZxSpectrumKeyView("K", Keys.K_K, onKeyPress),
          ZxSpectrumKeyView("L", Keys.K_L, onKeyPress),
          ZxSpectrumKeyView("<-", Keys.K_ENTER, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView("cs", Keys.K_CAPS, onKeyPress, toggle: true),
          ZxSpectrumKeyView("Z", Keys.K_Z, onKeyPress),
          ZxSpectrumKeyView("X", Keys.K_X, onKeyPress),
          ZxSpectrumKeyView("C", Keys.K_C, onKeyPress),
          ZxSpectrumKeyView("V", Keys.K_V, onKeyPress),
          ZxSpectrumKeyView("B", Keys.K_B, onKeyPress),
          ZxSpectrumKeyView("N", Keys.K_N, onKeyPress),
          ZxSpectrumKeyView("M", Keys.K_M, onKeyPress),
          ZxSpectrumKeyView("ss", Keys.K_SYM, onKeyPress, toggle: true),
          ZxSpectrumKeyView("b", Keys.K_SPACE, onKeyPress),
        ],
      )
    ]);
  }
}
