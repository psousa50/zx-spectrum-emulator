import 'package:flutter/material.dart';

enum KeyEvent {
  Up,
  Down,
}
typedef void OnKeyEvent(ZxSpectrumKey key, KeyEvent event);

class ZxSpectrumKey extends StatelessWidget {
  final String text;
  final int port;
  final int bitMask;
  final OnKeyEvent onKeyEvent;

  final style = TextStyle(fontSize: 20, decoration: TextDecoration.none);

  ZxSpectrumKey(this.text, this.port, this.bitMask, this.onKeyEvent);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails _) => onKeyEvent(this, KeyEvent.Down),
      onTapUp: (TapUpDetails _) => onKeyEvent(this, KeyEvent.Up),
      child: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Text(text, style: style)),
    );
  }
}
