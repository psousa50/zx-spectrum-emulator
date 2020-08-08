import 'package:flutter_test/flutter_test.dart';

import '../lib/Z80a.dart';
import '../lib/Memory.dart';

void main() {
  test('NOP', () {
    var program = [0];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.start(0);

    expect(z80a.PC, 1);
  });

  test('LD [BC DE HL SP], nn', () {
    const opcodes = {
      0x01: Z80a.R_BC,
      0x11: Z80a.R_DE,
      0x21: Z80a.R_HL,
      0x31: Z80a.R_SP,
    };
    opcodes.forEach((opcode, r) {
      var program = [opcode, 4, 2];
      final z80a = Z80a(Memory.withBytes(program));
      z80a.start(0);

      expect(z80a.getReg2(r), 2 * 256 + 4);
      expect(z80a.PC, 3);
    });
  });

  group('ADD HL, [BC DE SP]', () {
    test('normal', () {
      const opcodes = {
        0x09: Z80a.R_BC,
        0x19: Z80a.R_DE,
        0x39: Z80a.R_SP,
      };
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.HL = 4;
        z80a.setReg2(r, 10);
        z80a.start(0);

        expect(z80a.HL, 14);
        expect(z80a.carryFlag, false);
        expect(z80a.PC, 1);
      });
    });

    test('carry', () {
      const opcodes = {
        0x09: Z80a.R_BC,
        0x19: Z80a.R_DE,
        0x39: Z80a.R_SP,
      };
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.HL = 65530;
        z80a.setReg2(r, 10);
        z80a.start(0);

        expect(z80a.HL, 4);
        expect(z80a.carryFlag, true);
        expect(z80a.PC, 1);
      });
    });
  });

  test('ADD HL, HL', () {
    var program = [0x29];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.HL = 65530;
    z80a.start(0);

    expect(z80a.HL, 65524);
    expect(z80a.PC, 1);
  });

  group('INC [BC DE HL SP]', () {
    const opcodes = {
      0x03: Z80a.R_BC,
      0x13: Z80a.R_DE,
      0x23: Z80a.R_HL,
      0x33: Z80a.R_SP,
    };

    test('increase', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg2(r, 1234);
        z80a.start(0);

        expect(z80a.getReg2(r), 1235);
        expect(z80a.PC, 1);
      });
    });
  });

  group('DEC [BC DE HL SP]', () {
    const opcodes = {
      0x0B: Z80a.R_BC,
      0x1B: Z80a.R_DE,
      0x2B: Z80a.R_HL,
      0x3B: Z80a.R_SP,
    };

    test('decrease', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg2(r, 1234);
        z80a.start(0);

        expect(z80a.getReg2(r), 1233);
        expect(z80a.PC, 1);
      });
    });

    test('decrease with wrap', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg2(r, 0);
        z80a.start(0);

        expect(z80a.getReg2(r), 65535);
        expect(z80a.PC, 1);
      });
    });
  });

  group('INC [B C D E H L A]', () {
    const opcodes = {
      0x04: Z80a.R_B,
      0x0C: Z80a.R_C,
      0x14: Z80a.R_D,
      0x1C: Z80a.R_E,
      0x24: Z80a.R_H,
      0x2C: Z80a.R_L,
      0x3C: Z80a.R_A,
    };

    test('increase', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg(r, 127);
        z80a.start(0);

        expect(z80a.getReg(r), 128);
        expect(z80a.signFlag, true);
        expect(z80a.PC, 1);
      });
    });

    test('increase with wrap', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg(r, 255);
        z80a.signFlag = true;
        z80a.start(0);

        expect(z80a.getReg(r), 0);
        expect(z80a.zeroFlag, true);
        expect(z80a.signFlag, false);
        expect(z80a.PC, 1);
      });
    });
  });

  group('INC (HL)', () {
    test('increase', () {
      var program = [0x34, 127];
      final z80a = Z80a(Memory.withBytes(program));
      z80a.HL = 1;
      z80a.signFlag = true;
      z80a.start(0);

      expect(z80a.memory.peek(1), 128);
      expect(z80a.signFlag, true);
      expect(z80a.PC, 1);
    });

    test('increase with wrap', () {
      var program = [0x34, 255];
      final z80a = Z80a(Memory.withBytes(program));
      z80a.HL = 1;
      z80a.start(0);

      expect(z80a.memory.peek(1), 0);
      expect(z80a.zeroFlag, true);
      expect(z80a.signFlag, false);
      expect(z80a.PC, 1);
    });
  });

  group('DEC [B C D E H L A]', () {
    const opcodes = {
      0x05: Z80a.R_B,
      0x0D: Z80a.R_C,
      0x15: Z80a.R_D,
      0x1D: Z80a.R_E,
      0x25: Z80a.R_H,
      0x2D: Z80a.R_L,
      0x3D: Z80a.R_A,
    };

    test('decrease', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg(r, 123);
        z80a.start(0);

        expect(z80a.getReg(r), 122);
        expect(z80a.PC, 1);
      });
    });

    test('decrease with wrap', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(Memory.withBytes(program));
        z80a.setReg(r, 0);
        z80a.start(0);

        expect(z80a.getReg(r), 255);
        expect(z80a.PC, 1);
      });
    });
  });

  group('DEC (HL)', () {
    test('decrease', () {
      var program = [0x35, 7];
      final z80a = Z80a(Memory.withBytes(program));
      z80a.HL = 1;
      z80a.start(0);

      expect(z80a.memory.peek(1), 6);
      expect(z80a.PC, 1);
    });

    test('decrease with wrap', () {
      var program = [0x35, 0];
      final z80a = Z80a(Memory.withBytes(program));
      z80a.HL = 1;
      z80a.start(0);

      expect(z80a.memory.peek(1), 255);
      expect(z80a.PC, 1);
    });
  });

  test('EX AF, AF"', () {
    var program = [0x08];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.AF = 1234;
    z80a.AF_L = 5678;
    z80a.start(0);

    expect(z80a.AF, 5678);
    expect(z80a.AF_L, 1234);
    expect(z80a.PC, 1);
  });

  test('LD (BC), A', () {
    var program = [0x02, 0, 100];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.A = 123;
    z80a.BC = 1;
    z80a.start(0);

    expect(z80a.memory.peek(1), 123);
    expect(z80a.memory.peek(2), 100);
    expect(z80a.PC, 1);
  });

  test('LD (DE), A', () {
    var program = [0x12, 0, 100];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.A = 123;
    z80a.DE = 1;
    z80a.start(0);

    expect(z80a.memory.peek(1), 123);
    expect(z80a.memory.peek(2), 100);
    expect(z80a.PC, 1);
  });

  test('LD A, (BC)', () {
    var program = [0x0A, 123];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.BC = 1;
    z80a.start(0);

    expect(z80a.A, 123);
    expect(z80a.PC, 1);
  });

  test('LD A, (DE)', () {
    var program = [0x1A, 123];
    final z80a = Z80a(Memory.withBytes(program));
    z80a.DE = 1;
    z80a.start(0);

    expect(z80a.A, 123);
    expect(z80a.PC, 1);
  });
}
