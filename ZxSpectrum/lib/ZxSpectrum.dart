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
typedef void OnSoundSample(ZxSpectrum zx, int value);
typedef void OnInterrupt(ZxSpectrum zx);

const VideoFrequency = 50.08;

class ZxSpectrum {
  late Memory48K memory;
  late ZxSpectrumPorts ports;
  late Z80 z80;
  late Ula ula;

  late final OnFrame? onFrame;
  late final OnInstruction? onInstruction;
  late final OnSoundSample? onSoundSample;
  late final OnInterrupt? onInterrupt;
  late final OnMemoryError? onMemoryError;

  final int frequency;
  final int soundSampleRate;

  int videoFrameTStates = 0;
  int soundFrameTStates = 0;

  bool running = false;
  int currentVideoFrame = 0;
  int currentSOundFrame = 0;

  int soundFramesCounter = 0;

  int tStatesTotalCounter = 0;

  ZxSpectrum(
      {this.onFrame,
      this.onInstruction,
      this.onInterrupt,
      this.onSoundSample,
      this.onMemoryError = onMemoryErrorDefault,
      this.frequency = 3500000,
      this.soundSampleRate = 48000}) {
    memory = Memory48K(onMemoryError: onMemoryError ?? onMemoryErrorDefault);
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

    int tStatesCounter = 0;
    while (tStatesCounter < videoFrameTStates) {
      onInstruction?.call(this);
      var tStates = step();
      tStatesCounter += tStates;
      tStatesTotalCounter += tStates;
      soundFramesCounter += tStates;
      if (soundFramesCounter >= soundFrameTStates) {
        soundFramesCounter = 0;
        onSoundSample?.call(this, ula.speakerState);
      }
    }

    var tStates = z80.maskableInterrupt();
    tStatesCounter += tStates;
    tStatesTotalCounter += tStates;
    if (z80.interruptsEnabled) {
      onInterrupt?.call(this);
    }

    currentVideoFrame++;
    ula.refreshScreen(currentVideoFrame);
    onFrame?.call(this, currentVideoFrame);
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
