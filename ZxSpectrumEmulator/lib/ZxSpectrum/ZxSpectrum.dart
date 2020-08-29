import 'dart:async';
import 'dart:typed_data';

import 'package:Z80a/Cpu/Z80a.dart';
import 'package:ZxSpectrumEmulator/ZxSpectrum/Memory48K.dart';

import 'Ula.dart';
import 'ZxSpectrumPorts.dart';

typedef void OnScreenRefresh();

class ZxSpectrum {
  Memory48K memory;
  ZxSpectrumPorts ports;
  Z80a z80a;
  Ula ula;

  OnScreenRefresh onScreenRefresh;

  double startTimeMs = 0;
  double timeMs = 0;
  int currentFrame = 0;
  int skipedFrames = 0;

  ZxSpectrum(this.onScreenRefresh) {
    memory = Memory48K();
    ports = ZxSpectrumPorts();
    ula = Ula(memory);
    z80a = Z80a(memory, ports);
  }

  void load(int address, Uint8List bytes) {
    memory.setRange(address, bytes);
  }

  void start() {
    startTimeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    timeMs = startTimeMs;
    next(0);
  }

  void next(int timeMs) => Timer(Duration(milliseconds: timeMs), tick);

  void tick() {
    var tStates = z80a.step();
    var elapsedMs = tStates * (1 / 13.5);
    var nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    var waitUntil = ((timeMs + elapsedMs) - nowMs).toInt();
    var thisFrame = (nowMs - startTimeMs) ~/ 20;
    if (thisFrame > currentFrame) {
      skipedFrames = thisFrame - currentFrame;
      timeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
      currentFrame = thisFrame;
      ula.refreshScreen();
      onScreenRefresh();
    }

    if (waitUntil < 0) waitUntil = 0;
    next(waitUntil.toInt());
  }
}
