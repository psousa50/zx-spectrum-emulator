import 'dart:typed_data';
import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Cpu/Z80a.dart';

class Z80Assembler {
  static Uint8List u(List<int> bytes) => Uint8List.fromList(bytes);

  static Uint8List ldR8R8(int r1, int r2) =>
      u([Registers.r8TableBack[r1] << 3 | Registers.r8TableBack[r2]]);

  static Uint8List incA() => u([0x3C]);
  static Uint8List jr(int n) => u([0x18, n]);

  static Uint8List im0() => u([Z80a.EXTENDED_OPCODES, 0x46]);
  static Uint8List im1() => u([Z80a.EXTENDED_OPCODES, 0x56]);
  static Uint8List im2() => u([Z80a.EXTENDED_OPCODES, 0x5E]);
}
