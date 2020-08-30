import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Z80a/Cpu/Z80a.dart';

import 'Memory48K.dart';
import 'Ula.dart';
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
  int skipedFrames = 0;

  ZxSpectrum({OnFrame onFrame}) {
    this.onFrame = onFrame;
    memory = Memory48K();
    ports = ZxSpectrumPorts();
    ula = Ula(memory);
    z80a = Z80a(memory, ports);
  }

  void load(int address, Uint8List bytes) {
    memory.setRange(address, bytes);
  }

  void start() {
    next(0);
  }

  void next(int timeMicroseconds) =>
      Timer(Duration(microseconds: timeMicroseconds), frame);

  void frame() {
    int tStatesTotal = 0;
    while (tStatesTotal < 69888) {
      tStatesTotal += step();
    }
    ula.refreshScreen();
    if (onFrame != null) onFrame();
    next(0);
  }

  int step() {
    var tStates = z80a.step();
    tStatesCounter += tStates;
    // print("T $tStatesCounter");
    var expectedElapsedMicroseconds = tStates * (1 / 3.5);
    var actualElapsedMicroseconds = tStates * 0.007;
    var timeToWaitMicroseconds =
        expectedElapsedMicroseconds - actualElapsedMicroseconds;
    // print("expectedElapsedMicroSeconds $expectedElapsedMicroseconds");
    // print("actualElapsedMicroSeconds $actualElapsedMicroseconds");
    // print("timeToWaitMicroseconds $timeToWaitMicroseconds");
    if (timeToWaitMicroseconds > 0) {
      sleep(Duration(microseconds: timeToWaitMicroseconds.toInt()));
    }
    return tStates;
  }
}
