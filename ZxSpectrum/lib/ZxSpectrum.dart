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
typedef void OnSoundSample(int value);
typedef void OnInterrupt(ZxSpectrum zx);

const VideoFrequency = 50.08;

class ZxSpectrum {
  Memory48K memory;
  ZxSpectrumPorts ports;
  Z80 z80;
  Ula ula;

  final OnFrame onFrame;
  final OnInstruction onInstruction;
  final OnSoundSample onSoundSample;
  final OnInterrupt onInterrupt;
  final OnMemoryError onMemoryError;
  final int frequency;
  final int soundSampleRate;

  int videoFrameTStates;
  int soundFrameTStates;

  bool running;
  int currentVideoFrame = 0;
  int currentSOundFrame = 0;

  int soundFramesCounter = 0;

  ZxSpectrum(
      {this.onFrame,
      this.onInstruction,
      this.onInterrupt,
      this.onSoundSample,
      this.onMemoryError = onMemoryErrorDefault,
      this.frequency = 3500000,
      this.soundSampleRate = 48000}) {
    memory = Memory48K(onMemoryError: onMemoryError);
    ports = ZxSpectrumPorts();
    ula = Ula(memory);

    videoFrameTStates = (frequency / VideoFrequency).round();
    soundFrameTStates = (frequency / soundSampleRate).round();

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
    while (tStatesTotal < videoFrameTStates) {
      if (onInstruction != null) {
        onInstruction(this);
      }
      tStatesTotal += step();

      soundFramesCounter++;
      if (soundFramesCounter >= soundFrameTStates) {
        soundFramesCounter = 0;
        onSoundSample(ula.speakerState);
      }
    }
    tStatesTotal += z80.maskableInterrupt();
    if (z80.interruptsEnabled && onInterrupt != null) {
      onInterrupt(this);
    }
    currentVideoFrame++;
    ula.refreshScreen(currentVideoFrame);
    if (onFrame != null) {
      onFrame(this, currentVideoFrame);
    }
  }

  int step() {
    var tStates = z80.step();
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
