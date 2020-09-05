import 'dart:typed_data';

import 'package:Z80a/Memory.dart';
import 'package:color/color.dart';

const SpectrumColors = [
  '000000',
  '0000D7',
  'D70000',
  'D700D7',
  '00D700',
  '00D7D7',
  'D7D700',
  'D7D7D7',
  '000000',
  '0000FF',
  'FF0000',
  'FF00FF',
  '00FF00',
  '00FFFF',
  'FFFF00',
  'FFFFFF',
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

  void refreshScreen(int currentFrame) {
    screen = buildImage(memory.range(16384, end: 16384 + 6912), currentFrame);
  }

  Uint8List buildImage(Uint8List zxScreen, int currentFrame) {
    if (palette == null) {
      palette = Uint8List(paletteSize);
      int p = 0;
      for (var spectrumColor in SpectrumColors) {
        palette[p++] = HexColor(spectrumColor).r;
        palette[p++] = HexColor(spectrumColor).g;
        palette[p++] = HexColor(spectrumColor).b;
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

    for (int y = 0; y < 192; y++) {
      var lineAddress =
          ((y & 0x07) << 8) | ((y & 0x38) << 2) | ((y & 0xC0) << 5);

      for (var x = 0; x < 32; x++) {
        var zxByte = zxScreen[lineAddress + x];
        int c = 0x1800 + (y >> 3) * 32 + x;
        var zxColor = zxScreen[c];
        var flash = zxColor & 0x80 == 0x80;
        var brightIdx = zxColor & 0x40 == 0x40 ? 8 : 0;
        var inkColorIdx = zxColor & 0x07 + brightIdx;
        var paperColorIdx = (zxColor & 0x38) >> 3 + brightIdx;
        if (flash && (currentFrame ~/ 32) % 2 == 1) {
          var s = inkColorIdx;
          inkColorIdx = paperColorIdx;
          paperColorIdx = s;
        }

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
