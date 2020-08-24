import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Z80a.dart';
import 'MemoryTest.dart';
import 'PortsTest.dart';

void main() {
  test('All opcodes should be processed', () {
    for (var opcode = 0; opcode < 256; opcode++) {
      var z80a = Z80a(MemoryTest(size: 20), PortsTest());
      if (![0x27, 0x76, 0xF3, 0xFB].contains(opcode)) {
        z80a.memory.poke(0, opcode);
        z80a.memory.poke(1, 0);
        z80a.memory.poke(2, 0);
        z80a.memory.poke(3, 0);
        z80a.PC = 0;
        z80a.registers.SP = 9;
        if (!z80a.step()) {
          print('Opcode ${opcode.toRadixString(16)} not processed');
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
          if (!z80a.step()) {
            print('Opcode ${opcode.toRadixString(16)} not processed');
          }
        }
      }
    }
  }, skip: false);
}
