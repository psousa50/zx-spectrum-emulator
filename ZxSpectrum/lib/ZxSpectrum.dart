import 'dart:async';
import 'dart:typed_data';

import 'package:Z80a/Cpu/Z80a.dart';

import 'Memory48K.dart';
import 'Ula.dart';
import 'Util.dart';
import 'ZxSpectrumPorts.dart';

typedef void OnFrame();

class ZxSpectrum {
  Memory48K memory;
  ZxSpectrumPorts ports;
  Z80a z80a;
  Ula ula;

  OnFrame onFrame;

  int tStatesCounter = 0;
  int currentFrame = 0;

  ZxSpectrum({OnFrame onFrame}) {
    this.onFrame = onFrame;
    memory = Memory48K();
    ports = ZxSpectrumPorts();
    // ports.writeInPort(0xFEFE, 0xFF);
    // ports.writeInPort(0xFDFE, 0xFF);
    // ports.writeInPort(0xFBFE, 0xFF);
    // ports.writeInPort(0xF7FE, 0xFF);
    // ports.writeInPort(0xEFFE, 0xFF);
    // ports.writeInPort(0xDFFE, 0xFF);
    // ports.writeInPort(0xBFFE, 0xFF);
    // ports.writeInPort(0x7FFE, 0xFF);
    ula = Ula(memory);
    z80a = Z80a(memory, ports);
  }

  void load(int address, Uint8List bytes) {
    memory.setRange(address, bytes);
  }

  void start() {
    // next(0);
    while (true) {
      frame();
    }
  }

  void next(int timeMicroseconds) =>
      Timer(Duration(microseconds: timeMicroseconds), frame);

  var printBuffer = List<String>();
  void printAdd(String s) {
    printBuffer.add("${DateTime.now()} $s");

    if (printBuffer.length > 10) {
      print("\n${printBuffer.join("\n")}");
      printBuffer.clear();
    }
  }

  void frame() {
    printAdd("start frame");

    int tStatesTotal = 0;
    while (tStatesTotal < 69888) {
      var d0 = z80a.memory.peek(z80a.PC);
      var d1 = z80a.memory.peek(z80a.PC + 1);
      var d2 = z80a.memory.peek(z80a.PC + 2);
      var i = z80a.getInstruction();
      if (i != null) {
        printAdd(
            "${toHex(z80a.PC)} -- ${i.name}           T: $tStatesTotal Opcodes: $d0 $d1 $d2");
      }
      tStatesTotal += step();
    }
    printAdd("maskableInterrupt ${z80a.interruptsEnabled} ${toHex(z80a.PC)}");
    z80a.maskableInterrupt();
    ula.refreshScreen();
    currentFrame++;
    if (onFrame != null) {
      onFrame();
    }
    printAdd("end frame 0");
    // next(0);
    printAdd("end frame 1");
  }

  int step() {
    var tStates = z80a.step();
    tStatesCounter += tStates;
    // var expectedElapsedMicroseconds = tStates * (1 / 3.5);
    // var actualElapsedMicroseconds = tStates * 0.007;
    // var timeToWaitMicroseconds =
    //     expectedElapsedMicroseconds - actualElapsedMicroseconds;
    // if (timeToWaitMicroseconds > 0) {
    //   sleep(Duration(microseconds: timeToWaitMicroseconds.toInt()));
    // }
    return tStates;
  }
}
