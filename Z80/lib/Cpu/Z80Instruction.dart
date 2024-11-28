import 'InstructionContext.dart';

typedef int OpcodeHandler(InstructionContext context);

class Z80Instruction {
  int opcode = 0;
  String name = "NOP";
  OpcodeHandler handler = (context) => 0;
  int _tStatesOnFalseCond = 0;
  int _tStatesOnTrueCond = 0;

  Z80Instruction({
    int? opcode,
    String? name,
    OpcodeHandler? handler,
    int? tStatesOnFalseCond,
    int? tStatesOnTrueCond,
  }) {
    if (opcode != null) this.opcode = opcode;
    if (name != null) this.name = name;
    if (handler != null) this.handler = handler;
    if (tStatesOnFalseCond != null)
      this._tStatesOnFalseCond = tStatesOnFalseCond;
    if (tStatesOnTrueCond != null) this._tStatesOnTrueCond = tStatesOnTrueCond;
  }
  int tStates({bool cond = false}) =>
      cond ? _tStatesOnTrueCond : _tStatesOnFalseCond;
}
