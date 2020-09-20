import 'dart:io';

import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:test/test.dart';

import 'package:ZxSpectrum/Z80Snapshot.dart';

void main() {
  test("", () {
    var snapshot = File('assets/games/pacman96.z80').readAsBytesSync();

    var z80Sna = Z80Snapshot(snapshot);

    var zx = ZxSpectrum();

    z80Sna.load(zx);

    print(z80Sna.version);
    print("PC: ${zx.z80.PC}");
    print("SP: ${zx.z80.SP}");
  });
}
