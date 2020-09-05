import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Z80a/Cpu/Z80a.dart';

import 'Memory48K.dart';
import 'Ula.dart';
import 'Util.dart';
import 'ZxSpectrumPorts.dart';

typedef void OnFrame(ZxSpectrum zx, int frameCounter);

class ZxSpectrum {
  Memory48K memory;
  ZxSpectrumPorts ports;
  Z80a z80a;
  Ula ula;

  OnFrame onFrame;

  int tStatesCounter = 0;
  int currentFrame = 0;

  var log;

  ZxSpectrum({OnFrame onFrame}) {
    this.onFrame = onFrame;
    memory = Memory48K();
    ports = ZxSpectrumPorts();
    ports.writeInPort(0xFEFE, 0xFF);
    ports.writeInPort(0xFDFE, 0xFF);
    ports.writeInPort(0xFBFE, 0xFF);
    ports.writeInPort(0xF7FE, 0xFF);
    ports.writeInPort(0xEFFE, 0xFF);
    ports.writeInPort(0xDFFE, 0xFF);
    ports.writeInPort(0xBFFE, 0xFF);
    ports.writeInPort(0x7FFE, 0xFF);
    ula = Ula(memory);
    z80a = Z80a(memory, ports);

    log = this.logNull;
  }

  void startLog() {
    log = logScreen;
  }

  var printBuffer = List<String>();
  void logNull(String _) {}
  void logScreen(String s) {
    var state = "#${toHex2(z80a.PC)} " +
        "A:${toHex(z80a.registers.A)} " +
        "BC:${toHex2(z80a.registers.BC)} " +
        "DE:${toHex2(z80a.registers.DE)} " +
        "HL:${toHex2(z80a.registers.HL)}" +
        " ${z80a.registers.signFlag ? "S" : " "}" +
        " ${z80a.registers.zeroFlag ? "Z" : " "}" +
        " ${z80a.registers.halfCarryFlag ? "H" : " "}" +
        " ${z80a.registers.parityOverflowFlag ? "P" : " "}" +
        " ${z80a.registers.addSubtractFlag ? "N" : " "}" +
        " ${z80a.registers.carryFlag ? "C" : " "}";
    printBuffer.add("${DateTime.now()} $state       $s");

    if (printBuffer.length > 10) {
      print("\n${printBuffer.join("\n")}");
      printBuffer.clear();
    }
  }

  void load(int address, Uint8List bytes) {
    memory.setRange(address, bytes);
  }

  void start() {
    nextFrame();
  }

  void nextFrame() => Timer(Duration(microseconds: 0), frame);

  void frame() {
    int tStatesTotal = 0;
    while (tStatesTotal < 69888) {
      tStatesTotal += step();
      var i = z80a.getInstruction();
      if (i != null) {
        log("${i.name}");
      } else {
        log("Invalid Instruction");
      }
    }
    log("maskableInterrupt ${z80a.interruptsEnabled}");
    z80a.maskableInterrupt();
    currentFrame++;
    ula.refreshScreen(currentFrame);
    if (onFrame != null) {
      onFrame(this, currentFrame);
    }
    nextFrame();
  }

  int step() {
    var tStates = z80a.step();
    tStatesCounter += tStates;
    var expectedElapsedMicroseconds = tStates * (1 / 3.5);
    var actualElapsedMicroseconds = tStates * 0.007;
    var timeToWaitMicroseconds =
        expectedElapsedMicroseconds - actualElapsedMicroseconds;
    if (timeToWaitMicroseconds > 0) {
      sleep(Duration(microseconds: timeToWaitMicroseconds.toInt()));
    }
    return tStates;
  }
}
