import 'package:Z80a/Cpu/Z80Instructions.dart';
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
        0x27,
        0x76,
        0xF3,
        0xFB
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
      if (![0x27, 0x76, 0xF3, 0xFB].contains(opcode)) {
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
    }
  }, skip: true);

  void printOpcode(int opcode, Z80Instruction instruction,
      {bool printIfNotDefined = false}) {
    if (instruction != null || printIfNotDefined) {
      var name = instruction != null
          ? instruction.name
          : "(-------------- NOT DEFINED)";
      print("${toHex(opcode)} => $name");
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
  });
}
