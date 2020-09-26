import 'dart:typed_data';

import 'package:Z80/Cpu/Z80.dart';

import 'Ula.dart';
import 'Util.dart';
import 'ZxSpectrum.dart';

class SNASnapshot {
  final Uint8List bytes;

  SNASnapshot(this.bytes);

  int gb(int pos) => bytes[pos];
  int gw(int pos) => w(bytes[pos], bytes[pos + 1]);

  int get I => gb(0x00);
  int get HLt => gw(0x01);
  int get BCt => gw(0x03);
  int get DEt => gw(0x05);
  int get AFt => gw(0x07);
  int get HL => gw(0x09);
  int get DE => gw(0x0B);
  int get BC => gw(0x0D);
  int get IX => gw(0x0F);
  int get IY => gw(0x11);
  int get IFF2 => gb(0x13);
  int get R => gb(0x14);
  int get AF => gw(0x15);
  int get SP => gw(0x17);
  int get interruptMode => gb(0x19);
  int get borderColor => gb(0x1A);

  void load(ZxSpectrum zx) {
    var z80 = zx.z80;

    z80.AF = AF;
    z80.BC = BC;
    z80.DE = DE;
    z80.HL = HL;
    z80.AFt = AFt;
    z80.BCt = BCt;
    z80.DEt = DEt;
    z80.HLt = HLt;
    z80.IX = IX;
    z80.IY = IY;
    z80.R = R;
    z80.I = I;
    z80.SP = SP;

    print(interruptMode);
    z80.interruptMode = Z80.interruptModes[interruptMode];
    z80.interruptsEnabled = (IFF2 & 0x04) == 0x04;

    zx.ula.borderColor = SpectrumColors[borderColor];

    zx.load(0x4000, bytes.sublist(0x1B));

    z80.PC = z80.pop2();
  }
}
