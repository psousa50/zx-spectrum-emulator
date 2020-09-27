import 'dart:typed_data';
import 'package:Z80/Cpu/Registers.dart';
import 'package:Z80/Cpu/Z80.dart';
import 'package:Z80/Util.dart';

class Z80Assembler {
  static Uint8List u(List<int> bytes) => Uint8List.fromList(bytes);

  static Uint8List ldR8R8(int r1, int r2) =>
      u([Registers.r8TableBack[r1] << 3 | Registers.r8TableBack[r2]]);

  static Uint8List ldR8n(int r8, int n) =>
      u([0x06 | (Registers.r8TableBack[r8] << 3), n]);

  static Uint8List bitBR8(int bit, int r8) =>
      u([Z80.BIT_OPCODES, 0x40 | (bit << 3) | (Registers.r8TableBack[r8])]);

  static Uint8List bitBIXd(int bit, int d) => u([
        Z80.IX_PREFIX,
        d,
        0x40 | (bit << 3) | (Registers.r8TableBack[Registers.R_MHL])
      ]);

  static Uint8List incA() => u([0x3C]);
  static Uint8List jr(int n) => u([0x18, n]);
  static Uint8List djnz(int n) => u([0x10, n]);

  static Uint8List decmHL() => u([0x35]);

  static Uint8List ldR16nn(int r16, int nn) =>
      u([0x01 | (Registers.r16SPTableBack[r16] << 4), lo(nn), hi(nn)]);

  static Uint8List inAC() => u([Z80.EXTENDED_OPCODES, 0x78]);

  static Uint8List im0() => u([Z80.EXTENDED_OPCODES, 0x46]);
  static Uint8List im1() => u([Z80.EXTENDED_OPCODES, 0x56]);
  static Uint8List im2() => u([Z80.EXTENDED_OPCODES, 0x5E]);
  static Uint8List ldAI() => u([Z80.EXTENDED_OPCODES, 0x57]);
  static Uint8List ldAR() => u([Z80.EXTENDED_OPCODES, 0x5F]);

  static Uint8List ldIXnn(int nn) => u([Z80.IX_PREFIX, 0x21, lo(nn), hi(nn)]);

  static Uint8List halt() => u([0x76]);
  static Uint8List di() => u([0xF3]);
  static Uint8List ei() => u([0xFB]);
}
