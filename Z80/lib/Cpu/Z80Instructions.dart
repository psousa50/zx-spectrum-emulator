import '../Util.dart';
import 'InstructionContext.dart';
import 'Registers.dart';
import 'Z80Instruction.dart';

class Z80Instructions {
  final Map<int, Z80Instruction> instructions = {};

  Z80Instructions();

  void build(
    int opcodeStart,
    String namePattern,
    OpcodeHandler handler,
    int tStatesOnFalseCond, {
    int multiplier = 1,
    int count = 1,
    int tStatesOnTrueCond = 0,
  }) {
    var flags = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"];

    for (var i = 0; i < count; i++) {
      var opcode = opcodeStart + i * multiplier;
      var rb012 = Registers.rBit012(opcode);
      var rb345 = Registers.rBit345(opcode);
      var r16 = i < 4 ? Registers.r16SPTable[i] : 0;
      var r16af = i < 4 ? Registers.r16AFTable[i] : 0;
      var flag = i < 8 ? flags[i] : "";
      var bit = bit345(opcode);
      var rst = opcode & 0x38;
      var name = namePattern
          .replaceAll("[cc]", flag)
          .replaceAll("[rb012]", Registers.r8Names[rb012]!)
          .replaceAll("[rb345]", Registers.r8Names[rb345]!)
          .replaceAll("[r8]", Registers.r8Names[rb345]!)
          .replaceAll("[r16]", Registers.r16Names[r16]!)
          .replaceAll("[r16af]", Registers.r16Names[r16af]!)
          .replaceAll("[rst]", rst.toString())
          .replaceAll("[bit]", bit.toString());

      instructions[opcode] = Z80Instruction(
        opcode: opcode,
        name: name,
        handler: handler,
        tStatesOnFalseCond: tStatesOnFalseCond,
        tStatesOnTrueCond: tStatesOnTrueCond,
      );
    }
  }

  void buildM1C8(
    int opcodeStart,
    String namePattern,
    OpcodeHandler handler,
    int tStates, {
    int multiplier = 1,
  }) =>
      build(
        opcodeStart,
        namePattern,
        handler,
        tStates,
        multiplier: multiplier,
        count: 8,
      );

  void buildM8C8(
    int opcodeStart,
    String namePattern,
    OpcodeHandler handler,
    int tStates, {
    int count = 8,
    int tStatesOnTrueCond = 0,
  }) =>
      build(
        opcodeStart,
        namePattern,
        handler,
        tStates,
        multiplier: 8,
        tStatesOnTrueCond: tStatesOnTrueCond,
        count: count,
      );

  void buildM16C4(
    int opcodeStart,
    String namePattern,
    OpcodeHandler handler,
    int tStates,
  ) =>
      build(
        opcodeStart,
        namePattern,
        handler,
        tStates,
        multiplier: 16,
        count: 4,
      );

  Z80Instruction? operator [](int i) => instructions[i];

  int execute(InstructionContext context) {
    var tStates = 0;
    var instruction = instructions[context.opcode];
    if (instruction != null) {
      tStates = instruction.handler(context.withInstruction(instruction));
    }
    return tStates;
  }
}
