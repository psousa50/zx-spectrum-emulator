import 'dart:async';
import 'dart:typed_data';

import 'package:ZxSpectrum/Joystick/KempstonJoystick.dart';
import 'package:ZxSpectrum/Joystick/KempstonJoystickAutoUp.dart';
import 'package:ZxSpectrum/Joystick/KeymapJoystick.dart';
import 'package:ZxSpectrum/Keyboard/ZxKeys.dart';
import 'package:ZxSpectrum/Loaders/Z80Snapshot.dart';
import 'package:ZxSpectrum/Logger.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/JoystickPanel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';
import 'Keyboard.dart';

KeyMap chuckieEggKeyMap = KeyMap(
    left: ZxKey.K_9,
    right: ZxKey.K_0,
    up: ZxKey.K_2,
    down: ZxKey.K_W,
    fire: ZxKey.K_M);

KeyMap spaceInvadersKeyMap =
    KeyMap(left: ZxKey.K_Z, right: ZxKey.K_X, fire: ZxKey.K_SPACE);

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

  final logger = Logger(disabled: true, bufferlength: 100000);

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
    var s = await rootBundle.load('assets/games/ManicMiner.z80');
    var loader = Z80Snapshot(s.buffer.asUint8List());
    // var loader = SNASnapshot(s.buffer.asUint8List());
    loader.load(zxSpectrum);
    zxSpectrum.load(0, rom.buffer.asUint8List());
    // zxSpectrum.memory.poke(35899, 0);
    // zxSpectrum.memory.poke(47183, 0);
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(
        onFrame: refreshScreen,
        onInstruction: onInstruction,
        onInterrupt: onInterrupt);

    kempstonJoystick = KempstonJoystickAutoUp();
    zxSpectrum.bindPort(0x00FF, 0x001F, kempstonJoystick);

    keymapJoystick = KeymapJoystick(
      zxSpectrum.ula,
      spaceInvadersKeyMap,
    );

    loadGameAndStart();
    sendKeys([
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_6),
      // KeyToSend(1000, ZxKey.K_ENTER),
      // KeyToSend(1000, ZxKey.K_7),
    ]);
  }

  void refreshScreen(ZxSpectrum zx, int currentFrame) {
    logger.log("FRAME");
    setState(() {
      screen = zx.ula.screen;
    });
  }

  void onInstruction(ZxSpectrum zx) {
    logger.z80State(zx, "");
  }

  void onInterrupt(ZxSpectrum zx) {
    logger.log("Interrupt ${zx.z80.IFF1} ${zx.z80.interruptMode} ${zx.z80.I}");
  }

  void onKeyEvent(ZxKey zxKey, bool pressed) {
    pressed ? zxSpectrum.ula.keyDown(zxKey) : zxSpectrum.ula.keyUp(zxKey);
  }

  @override
  Widget build(BuildContext context) {
    var rgb = zxSpectrum.ula.borderColor.toRgbColor();
    Color borderColor = Color.fromRGBO(rgb.r, rgb.g, rgb.b, 1);

    return Stack(children: [
      Display(screen, borderColor),
      JoystickPanel([kempstonJoystick, keymapJoystick]),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          keyboardVisible
              ? KeyboardPanel([zxSpectrum.ula])
              : SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                height: 10,
                color: Colors.grey,
                onPressed: () => keyboardVisible = !keyboardVisible,
                child:
                    Text(keyboardVisible ? "Hide Keyboard" : "Show Keyboard"),
              ),
              MaterialButton(
                height: 10,
                color: Colors.grey,
                onPressed: () => logger.setActive(!logger.isActive()),
                child: Text(logger.isActive() ? "No Log" : "Log"),
              ),
            ],
          ),
        ],
      ),
    ]);
  }
}
