import 'dart:async';
import 'dart:typed_data';
import 'package:Z80a/Util.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Display.dart';

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

  void loadRom() async {
    var s = await rootBundle.load('assets/48.rom');
    zxSpectrum.load(0, s.buffer.asUint8List());
    zxSpectrum.start();
  }

  @override
  void initState() {
    super.initState();
    zxSpectrum = ZxSpectrum(onFrame: refreshScreen);
    // var z80a = zxSpectrum.z80a;
    // z80a.registers.A = 20;
    // var program = Uint8List.fromList([
    //   ...Z80Assembler.ldR16nn(Registers.R_HL, 22528),
    //   ...Z80Assembler.ldR8n(Registers.R_B, 0),
    //   ...Z80Assembler.decmHL(),
    //   ...[0x23],
    //   ...Z80Assembler.djnz(-4),
    //   ...Z80Assembler.jr(-11),
    // ]);
    // zxSpectrum.load(0, program);
    loadRom();
  }

  void refreshScreen() {
    setState(() {
      screen = zxSpectrum.ula.screen;
    });
  }

  void pressP() {
    zxSpectrum.z80a.ports.writeInPort(0xDFFE, 0xFE);
    Timer(Duration(milliseconds: 10),
        () => zxSpectrum.z80a.ports.writeInPort(0xDFFE, 0xFF));
  }

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(fontSize: 20, decoration: TextDecoration.none);
    return Column(children: [
      SizedBox(height: 30),
      if (screen != null) Display(screen),
      Text(toHex(zxSpectrum.z80a.PC), style: style),
      Text(toHex(zxSpectrum.z80a.ports.inPort(0xDFFE)), style: style),
      // Text(toHex(zxSpectrum.memory.peek(0)), style: style),
      // Text("A: ${toHex(zxSpectrum.z80a.registers.A)}", style: style),
      // Text("B: ${toHex(zxSpectrum.z80a.registers.B)}", style: style),
      // Text("C: ${toHex(zxSpectrum.z80a.registers.C)}", style: style),
      // Text("D: ${toHex(zxSpectrum.z80a.registers.D)}", style: style),
      // Text("E: ${toHex(zxSpectrum.z80a.registers.E)}", style: style),
      // Text("H: ${toHex(zxSpectrum.z80a.registers.H)}", style: style),
      // Text("L: ${toHex(zxSpectrum.z80a.registers.L)}", style: style),
      // Text("BC: ${toHex(zxSpectrum.z80a.registers.BC)}", style: style),
      // Text("DE: ${toHex(zxSpectrum.z80a.registers.DE)}", style: style),
      // Text("HL: ${toHex(zxSpectrum.z80a.registers.HL)}", style: style),
      // Text("IX: ${toHex(zxSpectrum.z80a.registers.IX)}", style: style),
      // Text("IY: ${toHex(zxSpectrum.z80a.registers.IY)}", style: style),
      // Text("SP: ${toHex(zxSpectrum.z80a.registers.SP)}", style: style),
      // Text(zxSpectrum.currentFrame.toString()),
      // Text(zxSpectrum.skipedFrames.toString()),
      RaisedButton(
        onPressed: pressP,
        child: Text(
          "P",
        ),
      ),
    ]);
  }
}
