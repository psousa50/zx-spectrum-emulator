import 'package:flutter/material.dart';

import 'package:ZxSpectrum/ZxKeys.dart';

typedef void OnKeyEvent(ZxKey zxKey, bool pressed);

class ZxSpectrumKeyView extends StatefulWidget {
  final String text;
  final ZxKey zxKey;
  final OnKeyEvent onKeyEvent;

  final bool toggle;

  ZxSpectrumKeyView(this.text, this.zxKey, this.onKeyEvent,
      {this.toggle = false});

  @override
  _ZxSpectrumKeyViewState createState() => _ZxSpectrumKeyViewState();
}

class _ZxSpectrumKeyViewState extends State<ZxSpectrumKeyView> {
  bool pressed = false;

  _ZxSpectrumKeyViewState();

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
        fontSize: 20,
        decoration: TextDecoration.none,
        color: pressed ? Colors.white : Colors.red);
    return GestureDetector(
      onTapDown: (TapDownDetails _) {
        pressed = widget.toggle ? !pressed : true;
        widget.onKeyEvent(this.widget.zxKey, pressed);
      },
      onTapUp: (TapUpDetails _) {
        pressed = widget.toggle ? pressed : false;
        widget.onKeyEvent(this.widget.zxKey, pressed);
      },
      child: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Text(widget.text, style: style)),
    );
  }
}
