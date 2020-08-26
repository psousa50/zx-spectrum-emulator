import 'package:Z80a/Cpu/Registers.dart';

typedef void OpcodeHandler({int opcode});

class Z80Instruction {
  String name;
  OpcodeHandler handler;
  int tStates;

  Z80Instruction(this.name, this.handler, this.tStates);
}

class Z80Instructions {
  Map<int, Z80Instruction> instructions;

  Z80Instructions() {
    instructions = Map<int, Z80Instruction>();
  }

  void add(int opcode, String name, OpcodeHandler handler, int tStates) {
    instructions[opcode] = Z80Instruction(
      name,
      handler,
      tStates,
    );
  }

  void addMultiple(
      int opcode, int count, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < count; i++) {
      add(
        opcode + i * multiplier,
        name,
        handler,
        tStates,
      );
    }
  }

  void addFlags(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1, int count = 8}) {
    var flags = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"];
    for (var i = 0; i < count; i++) {
      var flag = flags[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[r8]", flag),
        handler,
        tStates,
      );
    }
  }

  void addR8(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < 8; i++) {
      var r8 = Registers.r8Table[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[r8]", Registers.r8Names[r8]),
        handler,
        tStates + (r8 == Registers.R_MHL ? 3 : 0),
      );
    }
  }

  void addR8R8(int opcode, String name, OpcodeHandler handler, int tStates) {
    for (var r1 = 0; r1 < 8; r1++) {
      var rSource = Registers.r8Table[r1];
      for (var r2 = 0; r2 < 8; r2++) {
        var rDest = Registers.r8Table[r2];
        add(
          opcode + r1 * 8 + r2,
          name
              .replaceAll("[rDest]", Registers.r8Names[rDest])
              .replaceAll("[rSource]", Registers.r8Names[rSource]),
          handler,
          tStates +
              (rSource == Registers.R_MHL || rDest == Registers.R_MHL ? 3 : 0),
        );
      }
    }
  }

  void addR16(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < 4; i++) {
      var r16 = Registers.r16SPTable[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[r16]", Registers.r16Names[r16]),
        handler,
        tStates,
      );
    }
  }

  int execute(int opcode) {
    var tStates = 0;
    var instruction = instructions[opcode];
    if (instruction != null) {
      instruction.handler(opcode: opcode);
      tStates = instruction.tStates;
    }
    return tStates;
  }
}
