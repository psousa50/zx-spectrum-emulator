import 'dart:typed_data';
import 'dart:ui';

import 'package:Z80a/Memory.dart';

const SpectrumColors = [
  0x000000,
  0x0000D7,
  0xD70000,
  0xD700D7,
  0x00D700,
  0x00D7D7,
  0xD7D700,
  0xD7D7D7,
  0x000000,
  0x0000FF,
  0xFF0000,
  0xFF00FF,
  0x00FF00,
  0x00FFFF,
  0xFFFF00,
  0xFFFFFF,
];

class Ula {
  static Uint8List palette;

  Uint8List screen;
  Memory memory;

  static const screenWidth = 256;
  static const screenHeight = 192;
  static const paletteSize = 256 * 4;
  static const bmpHeaderSize = 54;

  Ula(this.memory);

  void refreshScreen() {
    screen = buildImage(memory.range(16384, end: 16384 + 6912));
  }

  Uint8List buildImage(Uint8List zxScreen) {
    if (palette == null) {
      palette = Uint8List(paletteSize);
      int p = 0;
      for (var spectrumColor in SpectrumColors) {
        palette[p++] = Color(spectrumColor).red;
        palette[p++] = Color(spectrumColor).green;
        palette[p++] = Color(spectrumColor).blue;
        palette[p++] = 0;
      }
    }

    final fileLength = bmpHeaderSize + paletteSize + screenWidth * screenHeight;

    var bitmap = Uint8List(fileLength);

    ByteData bd = bitmap.buffer.asByteData();
    bd.setUint16(0, 0x424d); // header field: BM
    bd.setUint32(2, fileLength, Endian.little); // file length
    bd.setUint32(
        10, bmpHeaderSize + paletteSize, Endian.little); // start of the bitmap

    bd.setUint32(14, 40, Endian.little); // info header size
    bd.setUint32(18, screenWidth, Endian.little);
    bd.setUint32(22, -screenHeight, Endian.little); // top down, not bottom up
    bd.setUint16(26, 1, Endian.little); // planes
    bd.setUint32(28, 8, Endian.little); // bpp
    bd.setUint32(30, 0, Endian.little); // compression
    bd.setUint32(34, 0, Endian.little); // bitmap size

    var p = bmpHeaderSize;

    bitmap.setRange(p, p + paletteSize, palette);

    p = p + paletteSize;

    print(zxScreen.length);
    for (int y = 0; y < 192; y++) {
      var lineAddress =
          ((y & 0x07) << 8) | ((y & 0x38) << 2) | ((y & 0xC0) << 5);

      for (var x = 0; x < 32; x++) {
        var zxByte = zxScreen[lineAddress + x];
        int c = 0x1800 + (y >> 3) * 32 + x;
        var zxColor = zxScreen[c];
        var brightIdx = zxColor & 0x04 == 0x40 ? 8 : 0;
        var inkColorIdx = zxColor & 0x07 + brightIdx;
        var paperColorIdx = (zxColor & 0x38) >> 3 + brightIdx;

        for (var b = 0; b < 8; b++) {
          var bitSet = zxByte & 0x80 == 0x80;
          zxByte = zxByte << 1;
          bitmap[p++] = bitSet ? inkColorIdx : paperColorIdx;
        }
      }
    }

    return bitmap;
  }
}
