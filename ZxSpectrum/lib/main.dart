import 'dart:io';

import 'package:ZxSpectrum/Memory48K.dart';
import 'package:Z80a/Cpu/Z80a.dart';
import 'package:ZxSpectrum/ZxSpectrumPorts.dart';

void loadRom(Z80a z80a) async {
  var s = File('assets/48.rom').readAsBytesSync();
  z80a.memory.setRange(0, s.buffer.asUint8List());
}

void main() {
  var z80a = Z80a(Memory48K(), ZxSpectrumPorts());
  loadRom(z80a);
  int tStatesTotal = 0;
  Stopwatch sw = Stopwatch();
  sw.start();
  for (var i = 0; i < 10000000; i++) {
    // sw2.start();
    tStatesTotal += z80a.step();
    // sw2.stop();
    // print("sw2: ${sw2.elapsedMicroseconds}");
    // msTotal += sw2.elapsedMicroseconds;
    // sw2.reset();
  }

  print(tStatesTotal);
  print(sw.elapsedMilliseconds);
  print(sw.elapsedMilliseconds / tStatesTotal);
}
