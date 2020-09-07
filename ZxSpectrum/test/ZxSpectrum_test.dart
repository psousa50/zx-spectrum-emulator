import 'dart:typed_data';

import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Cpu/Z80Assembler.dart';
import 'package:Z80a/Util.dart';
import 'package:ZxSpectrum/ZxKeys.dart';
import 'package:ZxSpectrum/ZxSpectrum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Reading from port 0xFE should returning key state", () {
    var zx = ZxSpectrum();
    var z80 = zx.z80a;
    var ula = zx.ula;

    ula.keyDown(ZxKey.K_W);
    var program = Uint8List.fromList([
      ...Z80Assembler.ldR16nn(Registers.R_BC, 0xFBFE),
      ...Z80Assembler.inAC(),
    ]);
    zx.load(0, program);
    z80.step();
    z80.step();

    expect(z80.registers.A, binary("11111101"));
  });
}
