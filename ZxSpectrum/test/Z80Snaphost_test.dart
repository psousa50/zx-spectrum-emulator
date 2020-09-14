import 'dart:io';

import 'package:Z80/Util.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:test/test.dart';

import 'package:ZxSpectrum/Z80Snapshot.dart';

void main() {
  test("", () {
    var snapshot = File('assets/games/pacman.z80').readAsBytesSync();

    var z80Sna = Z80Snapshot(snapshot);

    print(z80Sna.version);

    var zx = ZxSpectrum();
    z80Sna.load(zx);
  });
}
