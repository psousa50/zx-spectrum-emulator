import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Z80/Cpu/Z80.dart';
import 'package:Z80/Memory.dart';

import 'Memory/Memory48K.dart';
import 'Ports/PortHandler.dart';
import 'Ports/ZxSpectrumPorts.dart';
import 'Ula.dart';

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
  OnMemoryError onMemoryError;
  bool running;

  int tStatesCounter = 0;
  int currentFrame = 0;

  ZxSpectrum(
      {this.onFrame,
      this.onInstruction,
      this.onInterrupt,
      this.onMemoryError = onMemoryErrorDefault}) {
    memory = Memory48K(onMemoryError: onMemoryError);
    ports = ZxSpectrumPorts();
    ula = Ula(memory);

    bindPort(0x0001, 0x0000, ula);

    z80 = Z80(memory, ports);
  }

  void bindPort(int bitMask, int value, PortHandler handler) {
    ports.bind(bitMask, value, handler);
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

  void nextFrame() => Timer(Duration(microseconds: 0), () {
        frame();
        nextFrame();
      });

  void frame() {
    if (!running) return;

    int tStatesTotal = 0;
    while (tStatesTotal < 69888) {
      if (onInstruction != null) {
        onInstruction(this);
      }
      tStatesTotal += step();
    }
    tStatesTotal += z80.maskableInterrupt();
    if (z80.interruptsEnabled && onInterrupt != null) {
      onInterrupt(this);
    }
    currentFrame++;
    ula.refreshScreen(currentFrame);
    if (onFrame != null) {
      onFrame(this, currentFrame);
    }
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
