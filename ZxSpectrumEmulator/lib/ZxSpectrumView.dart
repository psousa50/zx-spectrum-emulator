import 'dart:async';
import 'dart:typed_data';

import 'package:ZxSpectrum/KempstonJoystick.dart';
import 'package:ZxSpectrum/KeymapJoystick.dart';
import 'package:ZxSpectrum/Logger.dart';
import 'package:ZxSpectrum/Z80Snapshot.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/JoystickPanel.dart';
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
  KempstonJoystick kempstonJoystick;
  KeymapJoystick keymapJoystick;

  final logger = Logger(true);

  double sx = 0;
  double sy = 0;
  double x = 0;
  double y = 0;
  bool movingLeft = false;
  bool movingRight = false;
  bool keyboardVisible = true;

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

  void loadRomAndStart() async {
    var s = await rootBundle.load('assets/48.rom');
    zxSpectrum.load(0, s.buffer.asUint8List());
    zxSpectrum.start();
  }

  void loadGameAndStart() async {
    var rom = await rootBundle.load('assets/48.rom');
    var s = await rootBundle.load('assets/games/ADayInTheLife.z80');
    var z80 = Z80Snapshot(s.buffer.asUint8List());
    z80.load(zxSpectrum);
    zxSpectrum.load(0, rom.buffer.asUint8List());
    // zxSpectrum.memory.poke(35899, 0);
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum =
        ZxSpectrum(onFrame: refreshScreen, onInstruction: onInstruction);

    kempstonJoystick = KempstonJoystick();
    zxSpectrum.bindPort(0x00FF, 0x001F, kempstonJoystick);

    keymapJoystick = KeymapJoystick(
      zxSpectrum.ula,
      ZxKey.K_6,
      ZxKey.K_7,
      ZxKey.K_5,
      ZxKey.K_8,
      ZxKey.K_0,
    );

    loadGameAndStart();
    sendKeys([
      // KeyToSend(1000, ZxKey.K_2),
      // KeyToSend(1000, ZxKey.K_0),
    ]);
  }

  void refreshScreen(ZxSpectrum zx, int currentFrame) {
    setState(() {
      screen = zx.ula.screen;
    });
  }

  void onInstruction(ZxSpectrum zx) {
    logger.z80State(zx, "");
  }

  void onKeyEvent(ZxKey zxKey, bool pressed) {
    pressed ? zxSpectrum.ula.keyDown(zxKey) : zxSpectrum.ula.keyUp(zxKey);
  }

  @override
  Widget build(BuildContext context) {
    // var style = TextStyle(fontSize: 20, decoration: TextDecoration.none);
    var rgb = zxSpectrum.ula.borderColor.toRgbColor();
    Color borderColor = Color.fromRGBO(rgb.r, rgb.g, rgb.b, 1);

    return Stack(children: [
      // SizedBox(height: 30),
      Display(screen, borderColor),
      JoystickPanel([kempstonJoystick, keymapJoystick]),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          keyboardVisible
              ? KeyboardPanel([zxSpectrum.ula])
              : SizedBox(height: 10),
          MaterialButton(
            height: 10,
            color: Colors.grey,
            onPressed: () => keyboardVisible = !keyboardVisible,
            child: Text(keyboardVisible ? "Hide Keyboard" : "Show Keyboard"),
          )
        ],
      ),
      // Text(toHex(zxSpectrum.z80.PC), style: style),
      // Text(toHex(zxSpectrum.z80.ports.inPort(0xF7FE)), style: style),
    ]);
  }
}
