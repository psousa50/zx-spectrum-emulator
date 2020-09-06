import 'dart:io';

import 'package:Z80a/Util.dart';
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
    var z80a = zxSpectrum.z80a;

    var state = "#${toHex2(z80a.PC)} " +
        " A:${toHex(z80a.registers.A)}" +
        " BC:${toHex2(z80a.registers.BC)}" +
        " DE:${toHex2(z80a.registers.DE)}" +
        " HL:${toHex2(z80a.registers.HL)}" +
        " ${z80a.registers.signFlag ? "S" : " "}" +
        " ${z80a.registers.zeroFlag ? "Z" : " "}" +
        " ${z80a.registers.halfCarryFlag ? "H" : " "}" +
        " ${z80a.registers.parityOverflowFlag ? "P" : " "}" +
        " ${z80a.registers.addSubtractFlag ? "N" : " "}" +
        " ${z80a.registers.carryFlag ? "C" : " "}" +
        " K0:${toHex(zxSpectrum.ports.inPort(0xFBFE))}" +
        " K1:${toHex(zxSpectrum.ports.inPort(0xBFFE))}" +
        " ${toHex(z80a.memory.peek(z80a.registers.IY))}" +
        " ${toHex(z80a.memory.peek(z80a.registers.IY + 1))}";

    printBuffer.add("$state       $s");

    if (printBuffer.length > 1000) {
      print("\n${printBuffer.join("\n")}");
      printBuffer.clear();
    }
  }

  void clearKeys() {
    zxSpectrum.z80a.ports.writeInPort(0xFEFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xFDFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xFBFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xF7FE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xEFFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xDFFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0xBFFE, 0xFF);
    zxSpectrum.z80a.ports.writeInPort(0x7FFE, 0xFF);
  }

  void onFrame(ZxSpectrum zx, int f) {
    currentFrame = f;
  }

  void onInterrupt(ZxSpectrum zx) {
    log("Interrupt ${zx.z80a.interruptsEnabled}");
  }

  void onInstruction(ZxSpectrum zx) {
    instructionCount++;

    var i = zx.z80a.getInstruction();
    // if (zx.z80a.PC >= 0x0F2C && zx.z80a.PC < 0x11B7) {
    if (i != null) {
      log("${i.name}");
    } else {
      log("Invalid Instruction");
    }
    // }

    if (zx.z80a.PC == 0x0F38) {
      log("KeyCount: $keyCount");
      switch (keyCount) {
        case 0:
          clearKeys();
          log("PRESSED E (REM)");
          zx.z80a.ports.writeInPort(0xFBFE, 0xFB);
          keyCount++;
          break;

        case 1:
          clearKeys();
          log("PRESSED ENTER");
          zx.z80a.ports.writeInPort(0xBFFE, 0xFE);
          keyCount++;
          break;

        case 2:
          clearKeys();
          keyCount++;
          break;
      }

      // if (instructionCount > 1000000) {
      //   zx.stop();
      // }
    }

    // if (keyCount < 3 && (keyCount % 2 == 1) && currentFrame - keyFrame > 1) {
    //   keyCount++;
    //   zx.z80a.ports.writeInPort(0xFEFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xFDFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xFBFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xF7FE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xEFFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xDFFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0xBFFE, 0xFF);
    //   zx.z80a.ports.writeInPort(0x7FFE, 0xFF);
    // }
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
