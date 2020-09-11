import 'dart:typed_data';

import 'package:Z80/Cpu/Z80.dart';
import 'package:ZxSpectrum/Ula.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';

import 'Util.dart';

// ignore_for_file: non_constant_identifier_names

enum Version {
  v1,
  v2,
  v3,
}

var pages = {
  0: 0x0000,
  4: 0x8000,
  5: 0xc000,
  8: 0x4000,
};

class Z80Snapshot {
  final Uint8List bytes;

  Z80Snapshot(this.bytes);

  int gb(int pos) => bytes[pos];
  int gw(int pos) => w(bytes[pos], bytes[pos + 1]);

  int get byte12 => gb(12) == 255 ? 1 : gb(12);

  int get A => gb(0);
  int get F => gb(1);
  int get BC => gw(2);
  int get HL => gw(4);
  int get PC => version == Version.v1 ? gw(6) : gw(32);
  int get SP => gw(8);
  int get I => gb(10);
  int get R => gb(11) | (byte12 & 0x80);
  int get borderColor => bit123(byte12);
  bool get compressed => bit5(byte12) != 0;
  int get DE => gw(13);
  int get BCt => gw(15);
  int get DEt => gw(17);
  int get HLt => gw(19);
  int get AFt => w(bytes[22], bytes[21]);

  int get IY => gw(23);
  int get IX => gw(25);

  bool get interruptsEnabled => gb(27) != 0;

  int get blockLength => gw(30);

  int get dataStart => 30 + 2 + blockLength;

  InterruptMode get interruptMode {
    var m = bit01(gb(29));
    return m == 0
        ? InterruptMode.im0
        : m == 1 ? InterruptMode.im1 : InterruptMode.im2;
  }

  Version get version =>
      gw(6) == 0 ? gw(30) == 23 ? Version.v2 : Version.v3 : Version.v1;

  void load(ZxSpectrum zx) {
    var z80 = zx.z80;

    z80.A = A;
    z80.F = F;
    z80.BC = BC;
    z80.HL = HL;
    z80.PC = PC;
    z80.SP = SP;
    z80.I = I;
    z80.R = R;
    z80.DE = DE;

    z80.BCt = BCt;
    z80.DEt = DEt;
    z80.HLt = HLt;
    z80.AFt = AFt;

    z80.IY = IY;
    z80.IX = IX;

    z80.interruptsEnabled = interruptsEnabled;
    switch (version) {
      case Version.v1:
        loadV1(zx);
        break;

      case Version.v2:
      case Version.v3:
        loadV2(zx);
        break;

      default:
        break;
    }
  }

  Uint8List decompress(Uint8List b) {
    var decompressed = List<int>();

    List<int> fetch(int start, int size) =>
        start + size <= b.length ? b.sublist(start, start + size).toList() : [];

    var p = 0;
    bool done = false;
    while (!done) {
      done = p >= b.length ||
          p == b.length - 4 && eq(fetch(p, 4), [0x00, 0xED, 0xED, 0x00]);
      if (!done) {
        if (eq(fetch(p, 2), [0xED, 0xED])) {
          var repeat = b[p + 2];
          var byte = b[p + 3];
          decompressed.addAll(List.filled(repeat, byte));
          p = p + 4;
        } else {
          decompressed.add(b[p]);
          p = p + 1;
        }
      }
    }

    return Uint8List.fromList(decompressed);
  }

  void loadV1(ZxSpectrum zx) {
    var b = bytes.sublist(30);
    var uncompressed = compressed ? decompress(b) : b;
    zx.load(0x4000, uncompressed);
  }

  void loadV2(ZxSpectrum zx) {
    var p = dataStart;

    while (p + 3 < bytes.length) {
      var length = gw(p);
      var pageNumber = gb(p + 2);
      var start = pages[pageNumber];
      if (start != null) {
        var data = p + 3;
        var b = bytes.sublist(data, data + length - 1);
        var uncompressed = compressed ? decompress(b) : b;
        zx.load(start, uncompressed);
      }
      p = p + 3 + length;
    }

    zx.ula.borderColor = SpectrumColors[borderColor];
  }
}
