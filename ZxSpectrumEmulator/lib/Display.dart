import 'dart:typed_data';
import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final Uint8List screen;

  Display(this.screen);

  @override
  Widget build(BuildContext context) {
    if (screen == null) {
      return Text("No Screen!");
    }
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, offset: Offset(20, 20), blurRadius: 20),
        ],
        border: Border.all(color: Color(0)),
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
