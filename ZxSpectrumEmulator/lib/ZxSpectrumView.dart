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

  void refreshScreen(int currentFrame) {
    setState(() {
      screen = zxSpectrum.ula.screen;
    });
  }

  void onKeyEvent(ZxSpectrumKey key, KeyEvent event) {
    print(key.text);
    print(event);
    int port = key.port * 256 + 0xFE;
    int v0 = zxSpectrum.z80a.ports.inPort(port);
    int v1 =
        event == KeyEvent.Down ? v0 & (0xFF ^ key.bitMask) : v0 | key.bitMask;
    print(port);
    print(v1);
    zxSpectrum.z80a.ports.writeInPort(port, v1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
    ]);
  }
}
