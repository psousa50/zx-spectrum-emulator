import 'dart:async';
import 'dart:typed_data';

import 'package:ZxSpectrum/Util.dart';
import 'package:ZxSpectrum/Z80Snapshot.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/Keyboard.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';

class KeyToSend {
  int delayMs;
  ZxKey key;

  KeyToSend(this.delayMs, this.key);
}

class ZxSpectrumView extends StatefulWidget {
  @override
  _ZxSpectrumViewState createState() => _ZxSpectrumViewState();
}

class _ZxSpectrumViewState extends State<ZxSpectrumView> {
  ZxSpectrum zxSpectrum;
  Uint8List screen;

  void sendKeys(List<KeyToSend> keysToSend) {
    if (keysToSend.length > 0) {
      var keyToSend = keysToSend.first;
      Timer(Duration(milliseconds: keyToSend.delayMs), () {
        onKeyEvent(keyToSend.key, true);
        Timer(Duration(milliseconds: 50), () {
          onKeyEvent(keyToSend.key, false);
        });
        sendKeys(keysToSend.sublist(1));
      });
    }
  }

  void getScreen() async {
    var s = await rootBundle.load('assets/google.scr');
    zxSpectrum.load(16384, s.buffer.asUint8List());
  }

  void loadRomAndStart() async {
    var s = await rootBundle.load('assets/48.rom');
    zxSpectrum.load(0, s.buffer.asUint8List());
    zxSpectrum.start();
  }

  void loadGameAndStart() async {
    var s = await rootBundle.load('assets/games/JetSetWilly.z80');
    var z80 = Z80Snapshot(s.buffer.asUint8List());
    z80.load(zxSpectrum);
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(onFrame: refreshScreen);
    loadGameAndStart();
    sendKeys([
      KeyToSend(1000, ZxKey.K_1),
      KeyToSend(500, ZxKey.K_1),
      KeyToSend(500, ZxKey.K_1),
      KeyToSend(500, ZxKey.K_1),
      KeyToSend(500, ZxKey.K_ENTER),
    ]);
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
    var style = TextStyle(fontSize: 20, decoration: TextDecoration.none);
    var rgb = zxSpectrum.ula.borderColor.toRgbColor();
    Color borderColor = Color.fromRGBO(rgb.r, rgb.g, rgb.b, 1);
    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen, borderColor),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
      Text(toHex(zxSpectrum.z80.PC), style: style),
    ]);
  }
}
