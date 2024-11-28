import 'Z80Instruction.dart';

class InstructionContext {
  int opcode;
  Z80Instruction instruction = Z80Instruction();
  int prefix = 0;
  int displacement = 0;

  InstructionContext(this.opcode);
  InstructionContext.withPrefix(this.opcode, this.prefix)
      : this.displacement = 0;
  InstructionContext.withPrefixAndDisplacement(
      this.opcode, this.prefix, this.displacement);

  InstructionContext withInstruction(Z80Instruction instruction) {
    this.instruction = instruction;
    return this;
  }
}
