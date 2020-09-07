import 'dart:typed_data';
import 'package:color/color.dart';

import 'package:Z80a/Memory.dart';

const SpectrumColors = [
  Color.rgb(0x00, 0x00, 0x00),
  Color.rgb(0x00, 0x00, 0xD7),
  Color.rgb(0xD7, 0x00, 0x00),
  Color.rgb(0xD7, 0x00, 0xD7),
  Color.rgb(0x00, 0xD7, 0x00),
  Color.rgb(0x00, 0xD7, 0xD7),
  Color.rgb(0xD7, 0xD7, 0x00),
  Color.rgb(0xD7, 0xD7, 0xD7),
  Color.rgb(0x00, 0x00, 0x00),
  Color.rgb(0x00, 0x00, 0xFF),
  Color.rgb(0xFF, 0x00, 0x00),
  Color.rgb(0xFF, 0x00, 0xFF),
  Color.rgb(0x00, 0xFF, 0x00),
  Color.rgb(0x00, 0xFF, 0xFF),
  Color.rgb(0xFF, 0xFF, 0x00),
  Color.rgb(0xFF, 0xFF, 0xFF),
];

class KeyInfo {
  final int address;
  final int bitMask;

  KeyInfo(this.address, this.bitMask);
}

enum Keys {
  K_1,
  K_2,
  K_3,
  K_4,
  K_5,
  K_6,
  K_7,
  K_8,
  K_9,
  K_0,

  K_Q,
  K_W,
  K_E,
  K_R,
  K_T,
  K_Y,
  K_U,
  K_I,
  K_O,
  K_P,

  K_A,
  K_S,
  K_D,
  K_F,
  K_G,
  K_H,
  K_J,
  K_K,
  K_L,
  K_ENTER,

  K_CAPS,
  K_Z,
  K_X,
  K_C,
  K_V,
  K_B,
  K_N,
  K_M,
  K_SYM,
  K_SPACE,
}

var keys = {
  Keys.K_1: KeyInfo(0xF7FE, 0x01),
  Keys.K_2: KeyInfo(0xF7FE, 0x02),
  Keys.K_3: KeyInfo(0xF7FE, 0x04),
  Keys.K_4: KeyInfo(0xF7FE, 0x08),
  Keys.K_5: KeyInfo(0xF7FE, 0x10),
  Keys.K_6: KeyInfo(0xEFFE, 0x10),
  Keys.K_7: KeyInfo(0xEFFE, 0x08),
  Keys.K_8: KeyInfo(0xEFFE, 0x04),
  Keys.K_9: KeyInfo(0xEFFE, 0x02),
  Keys.K_0: KeyInfo(0xEFFE, 0x01),
  Keys.K_Q: KeyInfo(0xFBFE, 0x01),
  Keys.K_W: KeyInfo(0xFBFE, 0x02),
  Keys.K_E: KeyInfo(0xFBFE, 0x04),
  Keys.K_R: KeyInfo(0xFBFE, 0x08),
  Keys.K_T: KeyInfo(0xFBFE, 0x10),
  Keys.K_Y: KeyInfo(0xDFFE, 0x10),
  Keys.K_U: KeyInfo(0xDFFE, 0x08),
  Keys.K_I: KeyInfo(0xDFFE, 0x04),
  Keys.K_O: KeyInfo(0xDFFE, 0x02),
  Keys.K_P: KeyInfo(0xDFFE, 0x01),
  Keys.K_A: KeyInfo(0xFDFE, 0x01),
  Keys.K_S: KeyInfo(0xFDFE, 0x02),
  Keys.K_D: KeyInfo(0xFDFE, 0x04),
  Keys.K_F: KeyInfo(0xFDFE, 0x08),
  Keys.K_G: KeyInfo(0xFDFE, 0x10),
  Keys.K_H: KeyInfo(0xBFFE, 0x10),
  Keys.K_J: KeyInfo(0xBFFE, 0x08),
  Keys.K_K: KeyInfo(0xBFFE, 0x04),
  Keys.K_L: KeyInfo(0xBFFE, 0x02),
  Keys.K_ENTER: KeyInfo(0xBFFE, 0x01),
  Keys.K_CAPS: KeyInfo(0xFEFE, 0x01),
  Keys.K_Z: KeyInfo(0xFEFE, 0x02),
  Keys.K_X: KeyInfo(0xFEFE, 0x04),
  Keys.K_C: KeyInfo(0xFEFE, 0x08),
  Keys.K_V: KeyInfo(0xFEFE, 0x10),
  Keys.K_B: KeyInfo(0x7FFE, 0x10),
  Keys.K_N: KeyInfo(0x7FFE, 0x08),
  Keys.K_M: KeyInfo(0x7FFE, 0x04),
  Keys.K_SYM: KeyInfo(0x7FFE, 0x02),
  Keys.K_SPACE: KeyInfo(0x7FFE, 0x01),
};

class Ula {
  static Uint8List palette;

  Uint8List screen;
  Memory memory;

  var keyStates = {
    0xF7FE: 0xFF,
    0xEFFE: 0xFF,
    0xFBFE: 0xFF,
    0xDFFE: 0xFF,
    0xFDFE: 0xFF,
    0xBFFE: 0xFF,
    0xFEFE: 0xFF,
    0x7FFE: 0xFF,
  };

  Color borderColor = Color.rgb(0, 0, 0);

  static const screenWidth = 256;
  static const screenHeight = 192;
  static const paletteSize = 256 * 4;
  static const bmpHeaderSize = 54;

  Ula(this.memory);

  void refreshScreen(int currentFrame) {
    screen = buildImage(memory.range(16384, end: 16384 + 6912), currentFrame);
  }

  void keyDown(Keys key) {
    var k = keys[key];
    keyStates[k.address] = keyStates[k.address] & (0xFF ^ k.bitMask);
  }

  void keyUp(Keys key) {
    var k = keys[key];
    keyStates[k.address] = keyStates[k.address] | (k.bitMask);
  }

  int inPort(int address) {
    var value = keyStates[address];
    return value == null ? 0 : value;
  }

  Uint8List buildImage(Uint8List zxScreen, int currentFrame) {
    if (palette == null) {
      palette = Uint8List(paletteSize);
      int p = 0;
      for (var spectrumColor in SpectrumColors) {
        var rgb = spectrumColor.toRgbColor();
        palette[p++] = rgb.r;
        palette[p++] = rgb.g;
        palette[p++] = rgb.b;
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
