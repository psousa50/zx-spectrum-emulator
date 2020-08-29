import 'dart:async';
import 'dart:typed_data';

import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Cpu/Z80Assembler.dart';
import 'package:Z80a/Cpu/Z80a.dart';
import 'package:ZxSpectrumEmulator/Memory48K.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';
import 'Ula.dart';
import 'ZxSpectrumPorts.dart';

class ZxSpectrum extends StatefulWidget {
  @override
  _ZxSpectrumState createState() => _ZxSpectrumState();
}

class _ZxSpectrumState extends State<ZxSpectrum> {
  Z80a z80a;
  Uint8List screen;
  double startTimeMs = 0;
  double timeMs = 0;
  int currentFrame = 0;
  int skipedFrames = 0;

  void getScreen() async {
    var s = await rootBundle.load('assets/google.scr');
    z80a.memory.setRange(16384, s.buffer.asUint8List());
  }

  @override
  void initState() {
    super.initState();
    z80a = Z80a(Memory48K(), ZxSpectrumPorts());
    z80a.registers.A = 20;
    var program = Uint8List.fromList([
      ...Z80Assembler.ldR16nn(Registers.R_HL, 22528),
      ...Z80Assembler.ldR8n(Registers.R_B, 0),
      ...Z80Assembler.decmHL(),
      ...[0x23],
      ...Z80Assembler.djnz(-4),
      ...Z80Assembler.jr(-11),
    ]);
    z80a.memory.setRange(0, program);
    getScreen();
    startTimeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    timeMs = startTimeMs;
    next(0);
  }

  // 0 1 2 ld hl, 16384
  // 3 4 ld b, 0
  // 5 dec(hl)
  // 6 inc hl
  // 7 8 djnz -4
  // 9 10 jr -11

  void next(int timeMs) => Timer(Duration(milliseconds: timeMs), tick);

  void tick() {
    var tStates = z80a.step();
    var elapsedMs = tStates * (1 / 13.5);
    var nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    var waitUntil = ((timeMs + elapsedMs) - nowMs).toInt();
    var thisFrame = (nowMs - startTimeMs) ~/ 20;
    if (thisFrame > currentFrame) {
      skipedFrames = thisFrame - currentFrame;
      setState(() {
        timeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
        currentFrame = thisFrame;
        screen = Ula.buildImage(z80a.memory.range(16384, end: 16384 + 6912));
      });
    }

    if (waitUntil < 0) waitUntil = 0;
    next(waitUntil.toInt());
  }

  @override
  Widget build(BuildContext context) {
    print("build");
    if (z80a == null) return SizedBox.shrink();
    return Column(children: [
      Display(screen),
      Text(z80a.PC.toString()),
      Text(z80a.registers.HL.toString()),
      Text(currentFrame.toString()),
      Text(skipedFrames.toString()),
    ]);
  }
}
