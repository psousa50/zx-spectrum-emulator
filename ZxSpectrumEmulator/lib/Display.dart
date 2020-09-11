import 'dart:typed_data';

import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final Uint8List screen;
  final Color borderColor;

  Display(this.screen, this.borderColor);

  @override
  Widget build(BuildContext context) {
    if (screen == null) {
      return Text("No Screen!");
    }
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 60, color: borderColor),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Image.memory(
          screen,
          gaplessPlayback: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
