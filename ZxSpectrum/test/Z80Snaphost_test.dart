import 'dart:io';
import 'package:ZxSpectrum/Loaders/Z80Snapshot.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:test/test.dart';

void main() {
  test("", () {
    var snapshot = File('assets/games/GreenBeret.z80').readAsBytesSync();

    var z80Sna = Z80Snapshot(snapshot);

    var zx = ZxSpectrum();

    z80Sna.load(zx);

    print(z80Sna.version);
    print("PC: ${zx.z80.PC}");
    print("SP: ${zx.z80.SP}");
    print("Halted: ${zx.z80.halted}");
    print("IM: ${zx.z80.interruptMode}");
    print("INT enabled: ${zx.z80.IFF1}");
  });
}
