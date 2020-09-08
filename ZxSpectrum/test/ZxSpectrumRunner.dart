import 'dart:io';

import 'package:Z80/Util.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';

class ZxSpectrumRunner {
  ZxSpectrum zxSpectrum;
  var printBuffer = List<String>();

  int currentFrame = 0;
  int instructionCount = 0;
  int keyCount = 0;

  ZxSpectrumRunner() {
    zxSpectrum = ZxSpectrum(
      onFrame: onFrame,
      onInstruction: onInstruction,
      onInterrupt: onInterrupt,
    );
  }

  void log(String s) {
    var z80 = zxSpectrum.z80;

    var state = "#${toHex2(z80.PC)} " +
        " A:${toHex(z80.registers.A)}" +
        " BC:${toHex2(z80.registers.BC)}" +
        " DE:${toHex2(z80.registers.DE)}" +
        " HL:${toHex2(z80.registers.HL)}" +
        " ${z80.registers.signFlag ? "S" : " "}" +
        " ${z80.registers.zeroFlag ? "Z" : " "}" +
        " ${z80.registers.halfCarryFlag ? "H" : " "}" +
        " ${z80.registers.parityOverflowFlag ? "P" : " "}" +
        " ${z80.registers.addSubtractFlag ? "N" : " "}" +
        " ${z80.registers.carryFlag ? "C" : " "}" +
        " K0:${toHex(zxSpectrum.ports.inPort(0xFBFE))}" +
        " K1:${toHex(zxSpectrum.ports.inPort(0xBFFE))}" +
        " ${toHex(z80.memory.peek(z80.registers.IY))}" +
        " ${toHex(z80.memory.peek(z80.registers.IY + 1))}";

    printBuffer.add("$state       $s");

    if (printBuffer.length > 1000) {
      print("\n${printBuffer.join("\n")}");
      printBuffer.clear();
    }
  }

  void clearKeys() {
    ZxKey.values.forEach((k) {
      zxSpectrum.ula.keyUp(k);
    });
  }

  void onFrame(ZxSpectrum zx, int f) {
    currentFrame = f;
  }

  void onInterrupt(ZxSpectrum zx) {
    log("Interrupt ${zx.z80.interruptsEnabled}");
  }

  void onInstruction(ZxSpectrum zx) {
    instructionCount++;

    var i = zx.z80.getInstruction();
    // if (zx.z80.PC >= 0x0F2C && zx.z80.PC < 0x11B7) {
    if (i != null) {
      log("${i.name}");
    } else {
      log("Invalid Instruction");
    }
    // }

    if (zx.z80.PC == 0x0F38) {
      log("KeyCount: $keyCount");
      switch (keyCount) {
        case 0:
          clearKeys();
          log("PRESSED E (REM)");
          zx.ula.keyDown(ZxKey.K_E);
          keyCount++;
          break;

        case 1:
          clearKeys();
          log("PRESSED ENTER");
          zx.ula.keyDown(ZxKey.K_ENTER);
          keyCount++;
          break;

        case 2:
          clearKeys();
          keyCount++;
          break;
      }
    }
  }

  void loadRom() async {
    var rom = File('assets/48.rom').readAsBytesSync();
    zxSpectrum.load(0, rom);
  }

  void start() {
    loadRom();
    zxSpectrum.start();
  }
}
