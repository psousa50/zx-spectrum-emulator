import 'dart:typed_data';

import 'package:ZxSpectrum/Ula.dart';
import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final Uint8List screen;
  final borderColor;

  Display(this.screen, this.borderColor);

  @override
  Widget build(BuildContext context) {
    if (screen == null) {
      return Text("No Screen!");
    }
    var bc = SpectrumColors[borderColor];
    var bc1 = Color.fromRGBO(bc.r, bc.g, bc.b, 0);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, offset: Offset(20, 20), blurRadius: 20),
        ],
        border: Border.all(color: bc1),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Image.memory(
        screen,
        width: 256,
        height: 192,
        gaplessPlayback: true,
      ),
    );
  }
}
