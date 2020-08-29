import 'package:Z80a/Cpu/Z80Instruction.dart';
import 'package:Z80a/Util.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Cpu/Z80a.dart';
import 'MemoryTest.dart';
import 'PortsTest.dart';

void main() {
  test('All opcodes should be processed', () {
    for (var opcode = 0; opcode < 256; opcode++) {
      var z80a = Z80a(MemoryTest(size: 20), PortsTest());
      if (![
        Z80a.IX_PREFIX,
        Z80a.IY_PREFIX,
        Z80a.EXTENDED_OPCODES,
      ].contains(opcode)) {
        z80a.memory.poke(0, opcode);
        z80a.memory.poke(1, 0);
        z80a.memory.poke(2, 0);
        z80a.memory.poke(3, 0);
        z80a.PC = 0;
        z80a.registers.SP = 9;
        if (z80a.step() == 0) {
          print('Opcode ${toHex(opcode)} not processed');
        }
      }
    }

    for (var opcode = 0; opcode < 256; opcode++) {
      var z80a = Z80a(MemoryTest(size: 20), PortsTest());
      if (opcode < 0x30 && opcode > 0x37) {
        z80a.memory.poke(0, Z80a.BIT_OPCODES);
        z80a.memory.poke(1, opcode);
        z80a.PC = 0;
        z80a.registers.SP = 9;
        if (z80a.step() == 0) {
          print('Opcode ${toHex(opcode)} not processed');
        }
      }
    }

    for (var opcode = 0; opcode < 256; opcode++) {
      var z80a = Z80a(MemoryTest(size: 20), PortsTest());
      if (opcode >= 0x40 && opcode < 0x80 || opcode >= 0xA0 && opcode < 0xC0) {
        if (![
          0x4C,
          0x4E,
          0x54,
          0x5C,
          0x63,
          0x64,
          0x6B,
          0x6C,
          0x6E,
          0x70,
          0x71,
          0x74,
          0x7C
        ].contains(opcode)) {
          z80a.memory.poke(0, Z80a.EXTENDED_OPCODES);
          z80a.memory.poke(1, opcode);
          z80a.PC = 0;
          z80a.registers.SP = 9;
          if (z80a.step() == 0) {
            print('Opcode ${toHex(opcode)} not processed');
          }
        }
      }
    }
  }, skip: false);

  void printOpcode(int opcode, Z80Instruction instruction,
      {bool printIfNotDefined = false}) {
    if (instruction != null || printIfNotDefined) {
      if (instruction != null) {
        var tsFalse = instruction.tStates(cond: false);
        var tsTrue = instruction.tStates(cond: true);
        var ts = "$tsFalse${tsTrue != null ? ' $tsTrue' : ''}";
        var hex = toHex(opcode);
        var s = " " * (40 - hex.length - instruction.name.length);
        print("$hex => ${instruction.name}$s($ts)");
      } else
        print("(-------------- NOT DEFINED)");
    }
  }

  test('Show opcodes', () {
    var z80a = Z80a(MemoryTest(size: 20), PortsTest());

    print("********* Unprefixed *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (![
        Z80a.IX_PREFIX,
        Z80a.IY_PREFIX,
        Z80a.EXTENDED_OPCODES,
      ].contains(opcode)) {
        printOpcode(opcode, z80a.unPrefixedOpcodes[opcode],
            printIfNotDefined: true);
      }
    }

    print("********* Bit *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      printOpcode(opcode, z80a.bitOpcodes[opcode], printIfNotDefined: true);
    }

    print("********* Extended *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (opcode >= 0x40 && opcode < 0x80 || opcode >= 0xA0 && opcode < 0xC0)
        printOpcode(opcode, z80a.extendedOpcodes[opcode]);
    }

    print("********* IXY *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (![
        Z80a.BIT_OPCODES,
      ].contains(opcode)) {
        printOpcode(opcode, z80a.iXYOpcodes[opcode]);
      }
    }

    print("********* IXY Bit *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      var o = toHex(opcode);
      if (o[o.length - 1] == "6" || o[o.length - 1] == "E") {
        printOpcode(opcode, z80a.iXYbitOpcodes[opcode]);
      }
    }
  }, skip: true);
}
