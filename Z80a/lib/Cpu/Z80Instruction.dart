import 'InstructionContext.dart';

typedef int OpcodeHandler(InstructionContext context);

class Z80Instruction {
  String name;
  OpcodeHandler handler;
  int _tStatesOnFalseCond;
  int _tStatesOnTrueCond;

  Z80Instruction(this.name, this.handler, this._tStatesOnFalseCond);

  int tStates({bool cond: false}) =>
      cond ? _tStatesOnTrueCond : _tStatesOnFalseCond;
}
