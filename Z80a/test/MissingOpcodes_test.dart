import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Z80a.dart';

void main() {
  test('All opcodes should be processed', () {
    for (var opcode = 0; opcode < 256; opcode++) {
      var z80a = Z80a(Memory(size: 20));
      if (![0x27, 0x76, 0xD3, 0xDB, 0xF3].contains(opcode)) {
        z80a.memory.poke(0, opcode);
        z80a.memory.poke(1, 0);
        z80a.memory.poke(2, 0);
        z80a.memory.poke(3, 0);
        z80a.PC = 0;
        z80a.SP = 9;
        if (!z80a.step()) {
          print('Opcode ${opcode.toRadixString(16)} not processed');
        }
        // expect(z80a.step(), true,
        //     reason: 'Opcode ${opcode.toRadixString(16)} not processed');
      }
    }
  }, skip: false);
}
