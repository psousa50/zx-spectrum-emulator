import 'dart:typed_data';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/Keyboard.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';
import 'ZxSpectrumKey.dart';

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

  void onKeyEvent(ZxSpectrumKeyState keyState) {
    print("${keyState.text} ${keyState.pressed ? 'PRESSED' : 'NOT PRESSED'}");
    int port = keyState.port * 256 + 0xFE;
    int portValue = zxSpectrum.z80a.ports.inPort(port);
    int finalPortValue = keyState.pressed
        ? portValue & (0xFF ^ keyState.bitMask)
        : portValue | keyState.bitMask;
    zxSpectrum.z80a.ports.writeInPort(port, finalPortValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
      RaisedButton(
        onPressed: () {
          zxSpectrum.startLog();
        },
        child: Text(
          "Log",
        ),
      )
    ]);
  }
}
