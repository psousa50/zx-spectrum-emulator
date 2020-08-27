import 'InstructionContext.dart';
import 'Registers.dart';
import 'Z80Instruction.dart';

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

  Z80Instruction operator [](int i) => instructions[i];

  void addFlags(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1, int count = 8}) {
    var flags = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"];
    for (var i = 0; i < count; i++) {
      var flag = flags[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[flag]", flag),
        handler,
        tStates,
      );
    }
  }

  void addBit8R8(int opcode, String name, OpcodeHandler handler, int tStates) {
    for (var b = 0; b < 8; b++) {
      for (var i = 0; i < 8; i++) {
        var r8 = Registers.r8Table[i];
        add(
          opcode + b * 8 + i,
          name
              .replaceAll("[bit]", b.toString())
              .replaceAll("[r8]", Registers.r8Names[r8]),
          handler,
          tStates,
        );
      }
    }
  }

  void addBit8(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1, int count = 8}) {
    for (var i = 0; i < count; i++) {
      add(
        opcode + i * multiplier,
        name.replaceAll("[bit]", i.toString()),
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
        name
            .replaceAll("[r8]", Registers.r8Names[r8])
            .replaceAll("[bit]", i.toString()),
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

  int execute(InstructionContext context) {
    var tStates = 0;
    var instruction = instructions[context.opcode];
    if (instruction != null) {
      tStates = instruction.handler(context.withInstruction(instruction));
      if (tStates == null) tStates = 1;
    }
    return tStates;
  }
}
