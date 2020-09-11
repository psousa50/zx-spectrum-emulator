import 'dart:async';
import 'dart:typed_data';

import 'package:ZxSpectrum/Z80Snapshot.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';
import 'Keyboard.dart';

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

  var keyDown = ZxKey.K_8;
  var keyUp = ZxKey.K_9;
  var keyLeft = ZxKey.K_1;
  var keyRight = ZxKey.K_0;
  var keyFire = ZxKey.K_M;

  bool movingLeft = false;
  bool movingRight = false;
  bool movingUp = false;
  bool movingDown = false;

  void sendKeys(List<KeyToSend> keysToSend) {
    if (keysToSend.length > 0) {
      var keyToSend = keysToSend.first;
      Timer(Duration(milliseconds: keyToSend.delayMs), () {
        onKeyEvent(keyToSend.key, true);
        Timer(Duration(milliseconds: 500), () {
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
    var rom = await rootBundle.load('assets/48.rom');
    var s = await rootBundle.load('assets/games/3DDeathChase.z80');
    var z80 = Z80Snapshot(s.buffer.asUint8List());
    z80.load(zxSpectrum);
    zxSpectrum.load(0, rom.buffer.asUint8List());
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(onFrame: refreshScreen);
    loadGameAndStart();
    // sendKeys([
    //   KeyToSend(1000, ZxKey.K_0),
    //   KeyToSend(2000, ZxKey.K_ENTER),
    // ]);
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

    if (movingLeft) {
      zxSpectrum.ula.keyDown(keyLeft);
    }
    if (movingRight) {
      zxSpectrum.ula.keyDown(keyRight);
    }
    if (movingUp) {
      zxSpectrum.ula.keyDown(keyUp);
    }
    if (movingDown) {
      zxSpectrum.ula.keyDown(keyDown);
    }

    if (!movingLeft) {
      zxSpectrum.ula.keyUp(keyLeft);
    }
    if (!movingRight) {
      zxSpectrum.ula.keyUp(keyRight);
    }
    if (!movingUp) {
      zxSpectrum.ula.keyUp(keyUp);
    }
    if (!movingDown) {
      zxSpectrum.ula.keyUp(keyDown);
    }

    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen, borderColor),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
      // Text(toHex(zxSpectrum.z80.PC), style: style),
      // Text(toHex(zxSpectrum.z80.ports.inPort(0xF7FE)), style: style),
      // Text(dy.toString(), style: style),

      Row(children: [
        Spacer(),
        GestureDetector(
          onTapDown: (_) {
            zxSpectrum.ula.keyDown(keyFire);
          },
          onTapUp: (_) {
            zxSpectrum.ula.keyUp(keyFire);
          },
          child: Container(
            padding: EdgeInsets.all(50.0),
            decoration: BoxDecoration(
              color: Colors.grey,
            ),
          ),
        ),
        Spacer(),
        GestureDetector(
          // When the child is tapped, show a snackbar.
          onPanEnd: (_) {
            movingRight = false;
            movingLeft = false;
          },
          onPanUpdate: (d) {
            if (d.delta.dx > 1) {
              movingLeft = false;
              movingRight = true;
            }
            if (d.delta.dx < -1) {
              movingLeft = true;
              movingRight = false;
            }
            if (d.delta.dy > 1) {
              movingDown = true;
              movingUp = false;
            }
            if (d.delta.dy < -1) {
              movingDown = false;
              movingUp = true;
            }
          },
          child: Container(
            padding: EdgeInsets.fromLTRB(100, 50, 100, 50),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
            ),
          ),
        ),
        Spacer(),
      ]),
    ]);
  }
}
