import 'package:flutter/material.dart';

typedef void OnKeyEvent(ZxSpectrumKeyState keyState);

class ZxSpectrumKeyState {
  final String text;
  final int port;
  final int bitMask;
  final bool toggle;

  bool pressed = false;

  ZxSpectrumKeyState(this.text, this.port, this.bitMask, {this.toggle = false});
}

class ZxSpectrumKeyView extends StatefulWidget {
  final ZxSpectrumKeyState keyState;
  final OnKeyEvent onKeyEvent;

  ZxSpectrumKeyView(this.keyState, this.onKeyEvent);

  @override
  _ZxSpectrumKeyViewState createState() => _ZxSpectrumKeyViewState(keyState);
}

class _ZxSpectrumKeyViewState extends State<ZxSpectrumKeyView> {
  ZxSpectrumKeyState keyState;

  _ZxSpectrumKeyViewState(this.keyState);

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
        fontSize: 20,
        decoration: TextDecoration.none,
        color: keyState.pressed ? Colors.white : Colors.red);
    return GestureDetector(
      onTapDown: (TapDownDetails _) {
        keyState.pressed = keyState.toggle ? !keyState.pressed : true;
        widget.onKeyEvent(this.keyState);
      },
      onTapUp: (TapUpDetails _) {
        keyState.pressed = keyState.toggle ? keyState.pressed : false;
        widget.onKeyEvent(this.keyState);
      },
      child: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Text(widget.keyState.text, style: style)),
    );
  }
}
