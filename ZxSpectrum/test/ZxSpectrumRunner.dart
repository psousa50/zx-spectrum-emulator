import 'dart:async';
import 'dart:io';

import 'package:ZxSpectrum/Logger.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';

class KeyToSend {
  int delayMs;
  ZxKey key;

  KeyToSend(this.delayMs, this.key);
}

class ZxSpectrumRunner {
  ZxSpectrum zxSpectrum;
  Logger logger;

  int currentFrame = 0;
  int instructionCount = 0;
  int keyCount = 0;

  ZxSpectrumRunner() {
    zxSpectrum = ZxSpectrum(
        onFrame: onFrame,
        onInstruction: onInstruction,
        onInterrupt: onInterrupt,
        onMemoryError: onMemoryError);
    logger = Logger();
  }

  void sendKeys(List<KeyToSend> keysToSend) {
    if (keysToSend.length > 0) {
      var keyToSend = keysToSend.first;
      Timer(Duration(milliseconds: keyToSend.delayMs), () {
        log("KEY ${keyToSend.key}");
        sendKeyEvent(keyToSend.key, true);
        Timer(Duration(milliseconds: 500), () {
          sendKeyEvent(keyToSend.key, false);
        });
        sendKeys(keysToSend.sublist(1));
      });
    }
  }

  void sendKeyEvent(ZxKey key, bool pressed) {
    pressed ? zxSpectrum.ula.keyDown(key) : zxSpectrum.ula.keyUp(key);
  }

  void logState([String s = ""]) => logger.z80State(zxSpectrum, s);

  void log([String s = ""]) => logger.log(s);

  void clearKeys() {
    ZxKey.values.forEach((k) {
      zxSpectrum.ula.keyUp(k);
    });
  }

  void onFrame(ZxSpectrum zx, int f) {
    currentFrame = f;
  }

  void onInterrupt(ZxSpectrum zx) {
    log("Interrupt ${zx.z80.IFF1}");
  }

  void onInstruction(ZxSpectrum zx) {
    instructionCount++;

    logState();
  }

  void onMemoryError(int address) {
    log("Memory error $address");
  }

  void loadRom() async {
    var rom = File('assets/48.rom').readAsBytesSync();
    zxSpectrum.load(0, rom);
  }

  void start() {
    sendKeys([
      KeyToSend(2000, ZxKey.K_ENTER),
    ]);
    zxSpectrum.start();
  }
}
