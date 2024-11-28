import "dart:io";
import 'dart:typed_data';

import 'package:ZxSpectrum/Loaders/Z80Snapshot.dart';

import "ZxSpectrumRunner.dart";

void main() {
  var zxSpectrumRunner = ZxSpectrumRunner();

  var snapshot = File("assets/games/CyrusIsChess.z80").readAsBytesSync();

  var z80Sna = Z80Snapshot(snapshot);

  zxSpectrumRunner.loadRom();

  var program = Uint8List.fromList(
      [0x11, 0x05, 0x01, 0x21, 0x6A, 0x06, 0xCD, 0xB5, 0x03, 0x18, 0xFE]);
  zxSpectrumRunner.zxSpectrum.memory.setRange(30000, program);
  zxSpectrumRunner.zxSpectrum.z80.PC = 30000;

  z80Sna.load(zxSpectrumRunner.zxSpectrum);

  // var memory = [
  //   ...zxSpectrumRunner.zxSpectrum.memory.range(0x0000),
  //   ...zxSpectrumRunner.zxSpectrum.memory.range(0x4000)
  // ];
  // File("./tmp/CyrusIsChess.bin").writeAsBytesSync(memory);

  // zxSpectrumRunner.zxSpectrum.ula.refreshScreen(32);
  // File("./tmp/CyrusIsChess.bmp")
  //     .writeAsBytesSync(zxSpectrumRunner.zxSpectrum.ula.screen);

  // zxSpectrumRunner.start();

  var ws = File("tmp/log.txt").readAsBytesSync();
  var c = 2 * ws.where((element) => [48, 49].contains(element)).length;

  var w = Uint8List(c);
  var i = 0;
  ws.forEach((element) {
    if (element == 48) {
      w[i++] = 0;
      w[i++] = 0;
    }
    if (element == 49) {
      w[i++] = 255;
      w[i++] = 127;
    }
  });

  File("tmp/wave.pcm").writeAsBytesSync(w);
}
