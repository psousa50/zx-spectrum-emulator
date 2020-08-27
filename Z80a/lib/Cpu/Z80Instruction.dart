import 'OpcodeHandler.dart';

class Z80Instruction {
  String name;
  OpcodeHandler handler;
  int _tStatesOnNormal;
  int _tStatesOnTrue;

  Z80Instruction(this.name, this.handler, this._tStatesOnNormal);

  int tStates({bool cond: false}) => cond ? _tStatesOnNormal : _tStatesOnNormal;
}
