import 'dart:io';

import 'package:ZxSpectrum/Z80Snapshot.dart';

import 'ZxSpectrumRunner.dart';

void main() {
  var zxSpectrumRunner = ZxSpectrumRunner();

  var snapshot = File('assets/games/SpaceInvaders.z80').readAsBytesSync();

  var z80Sna = Z80Snapshot(snapshot);

  zxSpectrumRunner.loadRom();

  z80Sna.load(zxSpectrumRunner.zxSpectrum);

  zxSpectrumRunner.start();
}
