import 'package:flutter_test/flutter_test.dart';

import '../lib/Z80a.dart';
import '../lib/Memory.dart';

class TestMemory implements Memory {
  var bytes;

  TestMemory.withBytes(this.bytes);

  TestMemory({int size = 10}) {
    this.bytes = List<int>(size);
  }

  @override
  peek(int address) => bytes[address];

  @override
  peek2(int address) => bytes[address] + 256 * bytes[address + 1];

  @override
  poke(int address, int b) {
    this.bytes[address] = b;
  }

  @override
  poke2(int address, int b) {
    this.bytes[address] = b % 256;
    this.bytes[address + 1] = b ~/ 256;
  }
}

void main() {
  test('NOP', () {
    var program = [0];
    final z80a = Z80a(TestMemory.withBytes(program));
    z80a.start(0);

    expect(z80a.PC, 1);
  });

  test('LD BC, nn', () {
    var program = [1, 4, 2];
    final z80a = Z80a(TestMemory.withBytes(program));
    z80a.start(0);

    expect(z80a.BC, 2 * 256 + 4);
    expect(z80a.PC, 3);
  });

  group('INC BC, DE, HL, SP', () {
    const opcodes = {
      0x03: Z80a.R_BC,
      0x13: Z80a.R_DE,
      0x23: Z80a.R_HL,
      0x33: Z80a.R_SP,
    };

    test('normal', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(TestMemory.withBytes(program));
        z80a.setReg2(r, 1234);
        z80a.start(0);

        expect(z80a.getReg2(r), 1235);
      });
    });

    test('with wrap', () {
      opcodes.forEach((opcode, r) {
        var program = [opcode];
        final z80a = Z80a(TestMemory.withBytes(program));
        z80a.setReg2(r, 65535);
        z80a.start(0);

        expect(z80a.getReg2(r), 0);
      });
    });
  });

  group('INC B', () {
    Z80a setup(int v) {
      var program = [4];
      final z80a = Z80a(TestMemory.withBytes(program));
      z80a.B = v;
      z80a.start(0);
      return z80a;
    }

    test('normal', () {
      final z80a = setup(200);

      expect(z80a.B, 201);
      expect(z80a.PC, 1);
    });

    test('with wrap', () {
      final z80a = setup(255);

      expect(z80a.B, 0);
      expect(z80a.PC, 1);
    });
  });

  test('EX AF, AF' '', () {
    var program = [8];
    final z80a = Z80a(TestMemory.withBytes(program));
    z80a.AF = 1234;
    z80a.AF_L = 5678;
    z80a.start(0);

    expect(z80a.AF, 5678);
    expect(z80a.AF_L, 1234);
  });

  test('LD (BC), A', () {
    var program = [2, 0, 100];
    final z80a = Z80a(TestMemory.withBytes(program));
    z80a.A = 123;
    z80a.BC = 1;
    z80a.start(0);

    expect(z80a.memory.peek(1), 123);
    expect(z80a.memory.peek(2), 100);
    expect(z80a.PC, 1);
  });

  test('LD (DE), A', () {
    var program = [12, 0, 100];
    final z80a = Z80a(TestMemory.withBytes(program));
    z80a.A = 123;
    z80a.DE = 1;
    z80a.start(0);

    expect(z80a.memory.peek(1), 123);
    expect(z80a.memory.peek(2), 100);
    expect(z80a.PC, 1);
  });

  test('sets an 8bit register value', () {
    final z80a = Z80a(TestMemory());
    z80a.H = 3;
    z80a.L = 4;

    expect(z80a.HL, 772);
    expect(z80a.H, 3);
    expect(z80a.L, 4);
  });

  test('sets a 16bit register value', () {
    final z80a = Z80a(TestMemory());
    z80a.HL = 258;

    expect(z80a.HL, 258);
    expect(z80a.H, 1);
    expect(z80a.L, 2);
  });
}
