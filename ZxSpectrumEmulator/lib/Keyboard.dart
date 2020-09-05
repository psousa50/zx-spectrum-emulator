import 'package:flutter/material.dart';

import 'ZxSpectrumKey.dart';

class Keyboard extends StatelessWidget {
  final OnKeyEvent onKeyPress;

  Keyboard(this.onKeyPress);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        ZxSpectrumKeyView(ZxSpectrumKeyState("1", 0xF7, 0x01), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("2", 0xF7, 0x02), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("3", 0xF7, 0x04), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("4", 0xF7, 0x08), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("5", 0xF7, 0x10), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("6", 0xEF, 0x10), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("7", 0xEF, 0x08), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("8", 0xEF, 0x04), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("9", 0xEF, 0x02), onKeyPress),
        ZxSpectrumKeyView(ZxSpectrumKeyState("0", 0xEF, 0x01), onKeyPress),
      ]),
      Row(
        children: [
          ZxSpectrumKeyView(ZxSpectrumKeyState("Q", 0xFB, 0x01), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("W", 0xFB, 0x02), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("E", 0xFB, 0x04), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("R", 0xFB, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("T", 0xFB, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("Y", 0xDF, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("U", 0xDF, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("I", 0xDF, 0x04), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("O", 0xDF, 0x02), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("P", 0xDF, 0x01), onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView(ZxSpectrumKeyState("A", 0xFD, 0x01), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("S", 0xFD, 0x02), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("D", 0xFD, 0x04), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("F", 0xFD, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("G", 0xFD, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("H", 0xBF, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("J", 0xBF, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("K", 0xBF, 0x04), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("L", 0xBF, 0x02), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("<-", 0xBF, 0x01), onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKeyView(
              ZxSpectrumKeyState("cs", 0xFE, 0x01, toggle: true), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("Z", 0xFE, 0x02), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("X", 0xFE, 0x04), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("C", 0xFE, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("V", 0xFE, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("B", 0x7F, 0x10), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("N", 0x7F, 0x08), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("M", 0x7F, 0x04), onKeyPress),
          ZxSpectrumKeyView(
              ZxSpectrumKeyState("ss", 0x7F, 0x02, toggle: true), onKeyPress),
          ZxSpectrumKeyView(ZxSpectrumKeyState("b", 0x7F, 0x01), onKeyPress),
        ],
      )
    ]);
  }
}
