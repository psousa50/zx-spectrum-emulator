import "dart:io";

import "package:ZxSpectrum/Z80Snapshot.dart";

import "ZxSpectrumRunner.dart";

void main() {
  var zxSpectrumRunner = ZxSpectrumRunner();

  var snapshot = File("assets/games/CyrusIsChess.z80").readAsBytesSync();

  var z80Sna = Z80Snapshot(snapshot);

  zxSpectrumRunner.loadRom();

  z80Sna.load(zxSpectrumRunner.zxSpectrum);

  // var memory = [
  //   ...zxSpectrumRunner.zxSpectrum.memory.range(0x0000),
  //   ...zxSpectrumRunner.zxSpectrum.memory.range(0x4000)
  // ];
  // File("./tmp/CyrusIsChess.bin").writeAsBytesSync(memory);

  // zxSpectrumRunner.zxSpectrum.ula.refreshScreen(32);
  // File("./tmp/CyrusIsChess.bmp")
  //     .writeAsBytesSync(zxSpectrumRunner.zxSpectrum.ula.screen);

  zxSpectrumRunner.start();
}
