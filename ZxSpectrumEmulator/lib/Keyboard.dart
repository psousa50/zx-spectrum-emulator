import 'package:flutter/material.dart';

import 'ZxSpectrumKey.dart';

class Keyboard extends StatelessWidget {
  final OnKeyEvent onKeyPress;

  Keyboard(this.onKeyPress);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        ZxSpectrumKey("1", 0xF7, 0x01, onKeyPress),
        ZxSpectrumKey("2", 0xF7, 0x02, onKeyPress),
        ZxSpectrumKey("3", 0xF7, 0x04, onKeyPress),
        ZxSpectrumKey("4", 0xF7, 0x08, onKeyPress),
        ZxSpectrumKey("5", 0xF7, 0x10, onKeyPress),
        ZxSpectrumKey("6", 0xEF, 0x10, onKeyPress),
        ZxSpectrumKey("7", 0xEF, 0x08, onKeyPress),
        ZxSpectrumKey("8", 0xEF, 0x04, onKeyPress),
        ZxSpectrumKey("9", 0xEF, 0x02, onKeyPress),
        ZxSpectrumKey("0", 0xEF, 0x01, onKeyPress),
      ]),
      Row(
        children: [
          ZxSpectrumKey("Q", 0xFB, 0x01, onKeyPress),
          ZxSpectrumKey("W", 0xFB, 0x02, onKeyPress),
          ZxSpectrumKey("E", 0xFB, 0x04, onKeyPress),
          ZxSpectrumKey("R", 0xFB, 0x08, onKeyPress),
          ZxSpectrumKey("T", 0xFB, 0x10, onKeyPress),
          ZxSpectrumKey("Y", 0xDF, 0x10, onKeyPress),
          ZxSpectrumKey("U", 0xDF, 0x08, onKeyPress),
          ZxSpectrumKey("I", 0xDF, 0x04, onKeyPress),
          ZxSpectrumKey("O", 0xDF, 0x02, onKeyPress),
          ZxSpectrumKey("P", 0xDF, 0x01, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKey("A", 0xFD, 0x01, onKeyPress),
          ZxSpectrumKey("S", 0xFD, 0x02, onKeyPress),
          ZxSpectrumKey("D", 0xFD, 0x04, onKeyPress),
          ZxSpectrumKey("F", 0xFD, 0x08, onKeyPress),
          ZxSpectrumKey("G", 0xFD, 0x10, onKeyPress),
          ZxSpectrumKey("H", 0xBF, 0x10, onKeyPress),
          ZxSpectrumKey("J", 0xBF, 0x08, onKeyPress),
          ZxSpectrumKey("K", 0xBF, 0x04, onKeyPress),
          ZxSpectrumKey("L", 0xBF, 0x02, onKeyPress),
          ZxSpectrumKey("<-", 0xBF, 0x01, onKeyPress),
        ],
      ),
      Row(
        children: [
          ZxSpectrumKey("cs", 0xFE, 0x01, onKeyPress),
          ZxSpectrumKey("Z", 0xFE, 0x02, onKeyPress),
          ZxSpectrumKey("X", 0xFE, 0x04, onKeyPress),
          ZxSpectrumKey("C", 0xFE, 0x08, onKeyPress),
          ZxSpectrumKey("V", 0xFE, 0x10, onKeyPress),
          ZxSpectrumKey("B", 0x7F, 0x10, onKeyPress),
          ZxSpectrumKey("N", 0x7F, 0x08, onKeyPress),
          ZxSpectrumKey("M", 0x7F, 0x04, onKeyPress),
          ZxSpectrumKey("ss", 0x7F, 0x02, onKeyPress),
          ZxSpectrumKey("b", 0x7F, 0x01, onKeyPress),
        ],
      )
    ]);
  }
}
