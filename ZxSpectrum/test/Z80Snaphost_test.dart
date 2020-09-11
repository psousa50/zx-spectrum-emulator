import 'dart:io';

import 'package:Z80/Util.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:test/test.dart';

import 'package:ZxSpectrum/Z80Snapshot.dart';

void main() {
  test("", () {
    var snapshot = File('assets/games/ADayInTheLife.z80').readAsBytesSync();

    var z80Sna = Z80Snapshot(snapshot);

    print(z80Sna.version);

    var zx = ZxSpectrum();
    z80Sna.load(zx);

    var z80 = zx.z80;

    print("PC ${toHex2(z80.PC)}");
    print("SP ${toHex2(z80.SP)}");

    print(z80.memory.range(z80.PC, end: z80.PC + 10).map(toHex));
  });
}
