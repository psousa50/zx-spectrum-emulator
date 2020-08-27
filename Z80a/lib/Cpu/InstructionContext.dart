import 'Z80Instruction.dart';

class InstructionContext {
  int opcode;
  Z80Instruction instruction;
  int prefix;
  int displacement;

  InstructionContext(this.opcode);
  InstructionContext.withPrefix(this.opcode, this.prefix);
  InstructionContext.withPrefixAndDisplacement(
      this.opcode, this.prefix, this.displacement);

  InstructionContext withInstruction(Z80Instruction instruction) {
    this.instruction = instruction;
    return this;
  }
}
