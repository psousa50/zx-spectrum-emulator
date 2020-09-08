import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Z80/Cpu/Z80.dart';

import 'Memory48K.dart';
import 'Ula.dart';
import 'ZxSpectrumPorts.dart';

typedef void OnFrame(ZxSpectrum zx, int frameCounter);
typedef void OnInstruction(ZxSpectrum zx);
typedef void OnInterrupt(ZxSpectrum zx);

class ZxSpectrum {
  Memory48K memory;
  ZxSpectrumPorts ports;
  Z80 z80;
  Ula ula;

  OnFrame onFrame;
  OnInstruction onInstruction;
  OnInterrupt onInterrupt;
  bool running;

  int tStatesCounter = 0;
  int currentFrame = 0;

  ZxSpectrum({this.onFrame, this.onInstruction, this.onInterrupt}) {
    memory = Memory48K();
    ports = ZxSpectrumPorts();
    ula = Ula(memory);

    ports.bindPort(0x01, 0x00, ula);

    z80 = Z80(memory, ports);
  }

  void load(int address, Uint8List bytes) {
    memory.setRange(address, bytes);
  }

  void start() {
    running = true;
    nextFrame();
  }

  void stop() {
    running = false;
  }

  void nextFrame() => Timer(Duration(microseconds: 0), frame);

  void frame() {
    if (!running) return;

    int tStatesTotal = 0;
    while (tStatesTotal < 69888) {
      if (onInstruction != null) {
        onInstruction(this);
      }
      tStatesTotal += step();
    }
    if (onInterrupt != null) {
      onInterrupt(this);
    }
    z80.maskableInterrupt();
    currentFrame++;
    ula.refreshScreen(currentFrame);
    if (onFrame != null) {
      onFrame(this, currentFrame);
    }
    nextFrame();
  }

  int step() {
    var tStates = z80.step();
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
