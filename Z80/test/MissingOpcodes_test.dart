import 'package:Z80/Cpu/Z80Instruction.dart';
import 'package:Z80/Util.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Z80/Cpu/Z80.dart';
import 'MemoryTest.dart';
import 'PortsTest.dart';

void main() {
  test('All opcodes should be processed', () {
    for (var opcode = 0; opcode < 256; opcode++) {
      var z80 = Z80(MemoryTest(size: 20), PortsTest());
      if (![
        Z80.IX_PREFIX,
        Z80.IY_PREFIX,
        Z80.EXTENDED_OPCODES,
      ].contains(opcode)) {
        z80.memory.poke(0, opcode);
        z80.memory.poke(1, 0);
        z80.memory.poke(2, 0);
        z80.memory.poke(3, 0);
        z80.PC = 0;
        z80.registers.SP = 9;
        if (z80.step() == 0) {
          print('Opcode ${toHex(opcode)} not processed');
        }
      }
    }

    for (var opcode = 0; opcode < 256; opcode++) {
      var z80 = Z80(MemoryTest(size: 20), PortsTest());
      if (opcode < 0x30 && opcode > 0x37) {
        z80.memory.poke(0, Z80.BIT_OPCODES);
        z80.memory.poke(1, opcode);
        z80.PC = 0;
        z80.registers.SP = 9;
        if (z80.step() == 0) {
          print('Opcode ${toHex(opcode)} not processed');
        }
      }
    }

    for (var opcode = 0; opcode < 256; opcode++) {
      var z80 = Z80(MemoryTest(size: 20), PortsTest());
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
          0x7C,
          0xA4,
          0xA5,
          0xA6,
          0xA7,
          0xAC,
          0xAD,
          0xAE,
          0xAF,
          0xB4,
          0xB5,
          0xB6,
          0xB7,
          0xBC,
          0xBD,
          0xBE,
          0xBF,
        ].contains(opcode)) {
          z80.memory.poke(0, Z80.EXTENDED_OPCODES);
          z80.memory.poke(1, opcode);
          z80.PC = 0;
          z80.registers.SP = 9;
          if (z80.step() == 0) {
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
    var z80 = Z80(MemoryTest(size: 20), PortsTest());

    print("********* Unprefixed *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (![
        Z80.IX_PREFIX,
        Z80.IY_PREFIX,
        Z80.EXTENDED_OPCODES,
      ].contains(opcode)) {
        printOpcode(opcode, z80.unPrefixedOpcodes[opcode],
            printIfNotDefined: true);
      }
    }

    print("********* Bit *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      printOpcode(opcode, z80.bitOpcodes[opcode], printIfNotDefined: true);
    }

    print("********* Extended *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (opcode >= 0x40 && opcode < 0x80 || opcode >= 0xA0 && opcode < 0xC0)
        printOpcode(opcode, z80.extendedOpcodes[opcode]);
    }

    print("********* IXY *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      if (![
        Z80.BIT_OPCODES,
      ].contains(opcode)) {
        printOpcode(opcode, z80.iXYOpcodes[opcode]);
      }
    }

    print("********* IXY Bit *********");
    for (var opcode = 0; opcode < 256; opcode++) {
      var o = toHex(opcode);
      if (o[o.length - 1] == "6" || o[o.length - 1] == "E") {
        printOpcode(opcode, z80.iXYbitOpcodes[opcode]);
      }
    }
  }, skip: true);
}
