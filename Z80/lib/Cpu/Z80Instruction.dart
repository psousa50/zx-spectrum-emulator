import 'InstructionContext.dart';

typedef int OpcodeHandler(InstructionContext context);

class Z80Instruction {
  int opcode;
  String name;
  OpcodeHandler handler;
  int _tStatesOnFalseCond;
  int _tStatesOnTrueCond;

  Z80Instruction(this.opcode, this.name, this.handler, this._tStatesOnFalseCond,
      {int tStatesOnTrueCond}) {
    this._tStatesOnTrueCond = tStatesOnTrueCond;
  }

  int tStates({bool cond: false}) =>
      cond ? _tStatesOnTrueCond : _tStatesOnFalseCond;
}
