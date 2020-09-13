import 'dart:async';
import 'dart:typed_data';

import 'package:ZxSpectrum/Z80Snapshot.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:ZxSpectrumEmulator/Joystick.dart';
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
  var keyLeft = ZxKey.K_Q;
  var keyRight = ZxKey.K_W;
  var keyFire = ZxKey.K_P;

  double sx = 0;
  double sy = 0;
  double x = 0;
  double y = 0;
  bool movingLeft = false;
  bool movingRight = false;

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
    //   KeyToSend(3000, ZxKey.K_S),
    // ]);
  }

  void refreshScreen(ZxSpectrum zx, int currentFrame) {
    setState(() {
      screen = zx.ula.screen;
    });
  }

  void onKeyEvent(ZxKey zxKey, bool pressed) {
    pressed ? zxSpectrum.ula.keyDown(zxKey) : zxSpectrum.ula.keyUp(zxKey);
  }

  void onJoyStickEvent(ZxKey zxKey, JoystickState state) =>
      state == JoystickState.On
          ? zxSpectrum.ula.keyDown(zxKey)
          : zxSpectrum.ula.keyUp(zxKey);

  void left(JoystickState state) {
    zxSpectrum.kempston.left(state == JoystickState.On);
    onJoyStickEvent(keyLeft, state);
  }

  void right(JoystickState state) {
    zxSpectrum.kempston.right(state == JoystickState.On);
    onJoyStickEvent(keyRight, state);
  }

  void up(JoystickState state) {
    zxSpectrum.kempston.up(state == JoystickState.On);
    onJoyStickEvent(keyUp, state);
  }

  void down(JoystickState state) {
    zxSpectrum.kempston.down(state == JoystickState.On);
    onJoyStickEvent(keyDown, state);
  }

  void fire(JoystickState state) {
    zxSpectrum.kempston.fire(state == JoystickState.On);
    onJoyStickEvent(keyFire, state);
  }

  @override
  Widget build(BuildContext context) {
    // var style = TextStyle(fontSize: 20, decoration: TextDecoration.none);
    var rgb = zxSpectrum.ula.borderColor.toRgbColor();
    Color borderColor = Color.fromRGBO(rgb.r, rgb.g, rgb.b, 1);

    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen, borderColor),
      SizedBox(height: 30),
      Keyboard(onKeyEvent),
      Expanded(
        child: Joystick(left, right, up, down, fire),
      ),
      // Text(toHex(zxSpectrum.z80.PC), style: style),
      // Text(toHex(zxSpectrum.z80.ports.inPort(0xF7FE)), style: style),
    ]);
  }
}
