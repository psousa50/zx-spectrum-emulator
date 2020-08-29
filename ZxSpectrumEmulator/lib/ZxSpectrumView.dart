import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Cpu/Z80Assembler.dart';
import 'Display.dart';
import 'ZxSpectrum/ZxSpectrum.dart';

class ZxSpectrumView extends StatefulWidget {
  @override
  _ZxSpectrumViewState createState() => _ZxSpectrumViewState();
}

class _ZxSpectrumViewState extends State<ZxSpectrumView> {
  ZxSpectrum zxSpectrum;
  Uint8List screen;

  void getScreen() async {
    var s = await rootBundle.load('assets/google.scr');
    zxSpectrum.load(16384, s.buffer.asUint8List());
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(refreshScreen);
    var z80a = zxSpectrum.z80a;
    z80a.registers.A = 20;
    var program = Uint8List.fromList([
      ...Z80Assembler.ldR16nn(Registers.R_HL, 22528),
      ...Z80Assembler.ldR8n(Registers.R_B, 0),
      ...Z80Assembler.decmHL(),
      ...[0x23],
      ...Z80Assembler.djnz(-4),
      ...Z80Assembler.jr(-11),
    ]);
    zxSpectrum.load(0, program);
    getScreen();
    zxSpectrum.start();
  }

  void refreshScreen() {
    setState(() {
      screen = zxSpectrum.ula.screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("build");
    if (screen == null) return SizedBox.shrink();
    return Column(children: [
      Display(screen),
      Text(zxSpectrum.z80a.PC.toString()),
      Text(zxSpectrum.z80a.registers.HL.toString()),
      Text(zxSpectrum.currentFrame.toString()),
      Text(zxSpectrum.skipedFrames.toString()),
    ]);
  }
}
