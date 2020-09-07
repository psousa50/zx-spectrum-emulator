import 'dart:typed_data';

import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/Keyboard.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';

class ZxSpectrumView extends StatefulWidget {
  @override
  _ZxSpectrumViewState createState() => _ZxSpectrumViewState();
}

class _ZxSpectrumViewState extends State<ZxSpectrumView> {
  ZxSpectrum zxSpectrum;
  Uint8List screen;

  void getScreen() async {
    var s = await rootBundle.load('assets/google.scr');
    zxSpectrum.load(16384, s.buffer.asUint8List());
  }

  void loadRomAndStart() async {
    var s = await rootBundle.load('assets/48.rom');
    zxSpectrum.load(0, s.buffer.asUint8List());
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(onFrame: refreshScreen);
    loadRomAndStart();
  }

  void refreshScreen(ZxSpectrum zx, int currentFrame) {
    setState(() {
      screen = zx.ula.screen;
    });
  }

  void onKeyEvent(ZxKey zxKey, bool pressed) =>
      pressed ? zxSpectrum.ula.keyDown(zxKey) : zxSpectrum.ula.keyUp(zxKey);

  @override
  Widget build(BuildContext context) {
    var rgb = zxSpectrum.ula.borderColor.toRgbColor();
    Color borderColor = Color.fromRGBO(rgb.r, rgb.g, rgb.b, 1);
    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen, borderColor),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
    ]);
  }
}
