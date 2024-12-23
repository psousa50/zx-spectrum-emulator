import 'dart:typed_data';

import 'package:Z80/Memory.dart';
import 'package:color/color.dart';

import 'Colors.dart';
import 'Keyboard/KeyboardListener.dart';
import 'Keyboard/ZxKeys.dart';
import 'Ports/PortHandler.dart';

class Ula with PortHandler, KeyboardListener {
  static Uint8List palette = Uint8List.fromList([]);

  Uint8List screen = Uint8List.fromList([]);
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
  int speakerState = 0;

  static const screenWidth = 256;
  static const screenHeight = 192;
  static const paletteSize = 256 * 4;
  static const bmpHeaderSize = 54;

  Ula(this.memory);

  void refreshScreen(int currentFrame) {
    screen = buildImage(memory.range(16384, end: 16384 + 6912), currentFrame);
  }

  Uint8List buildImage(Uint8List zxScreen, int currentFrame) {
    palette = Uint8List(paletteSize);
    int p = 0;
    for (var spectrumColor in SpectrumColors) {
      var rgb = spectrumColor.toRgbColor();
      palette[p++] = rgb.b.toInt();
      palette[p++] = rgb.g.toInt();
      palette[p++] = rgb.r.toInt();
      palette[p++] = 0;
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

    var bmhSize = bmpHeaderSize;

    bitmap.setRange(bmhSize, bmhSize + paletteSize, palette);

    bmhSize = bmhSize + paletteSize;

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
        var paperColorIdx = ((zxColor & 0x38) >> 3) + brightIdx;
        if (flash && (currentFrame ~/ 32) % 2 == 1) {
          var s = inkColorIdx;
          inkColorIdx = paperColorIdx;
          paperColorIdx = s;
        }

        for (var b = 0; b < 8; b++) {
          var bitSet = zxByte & 0x80 == 0x80;
          zxByte = zxByte << 1;
          bitmap[bmhSize++] = bitSet ? inkColorIdx : paperColorIdx;
        }
      }
    }

    return bitmap;
  }

  @override
  int read(int port) {
    if (port == 0xFE) {
      return keyStates.values.reduce((value, element) => value & element);
    }
    var value = keyStates[port];
    return value == null ? 0xFF : value;
  }

  @override
  void write(int port, int value) {
    if (port & 0xFF == 0xFE) {
      borderColor = SpectrumColors[value & 0x07];
      speakerState = (value & 0x10) == 0x10 ? 0 : 1;
    }
  }

  @override
  void keyDown(ZxKey key) {
    var k = keys[key]!;
    keyStates[k.address] = keyStates[k.address]! & (0xFF ^ k.bitMask);
  }

  @override
  void keyUp(ZxKey key) {
    var k = keys[key]!;
    keyStates[k.address] = keyStates[k.address]! | (k.bitMask);
  }
}
