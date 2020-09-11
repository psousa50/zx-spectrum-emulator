library z80;

import 'package:Z80/Cpu/Z80Instructions.dart';
import 'package:Z80/Memory.dart';
import 'package:Z80/Ports.dart';
import 'package:Z80/Util.dart';

import 'InstructionContext.dart';
import 'Registers.dart';
import 'Z80Instruction.dart';

// ignore_for_file: non_constant_identifier_names

enum InterruptMode {
  im0,
  im1,
  im2,
}

class Z80 {
  final Memory memory;
  final Ports ports;

  InterruptMode interruptMode;
  bool interruptsEnabled = false;
  bool halted = false;
  var registers = Registers();
  var PC = 0;

  Z80Instructions unPrefixedOpcodes;
  Z80Instructions extendedOpcodes;
  Z80Instructions bitOpcodes;
  Z80Instructions iXYOpcodes;
  Z80Instructions iXYbitOpcodes;

  static const IX_PREFIX = 0xDD;
  static const IY_PREFIX = 0xFD;

  static const BIT_OPCODES = 0xCB;
  static const EXTENDED_OPCODES = 0xED;

  static List<int> bitMask = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80];

  Z80(this.memory, this.ports) {
    buildUnprefixedOpcodes();
    buildExtendedOpcodes();
    buildBitOpcodes();
    buildIXYOpcodes();
    buildIXYBitOpcodes();
  }

  int get A => registers.A;
  int get F => registers.F;
  int get B => registers.B;
  int get C => registers.C;
  int get D => registers.D;
  int get E => registers.E;
  int get H => registers.H;
  int get L => registers.L;
  int get IX_H => registers.IX_H;
  int get IX_L => registers.IX_L;
  int get IY_H => registers.IY_H;
  int get IY_L => registers.IY_L;
  int get I => registers.I;
  int get R => registers.R;

  set A(int b) => registers.A = b;
  set F(int b) => registers.F = b;
  set B(int b) => registers.B = b;
  set C(int b) => registers.C = b;
  set D(int b) => registers.D = b;
  set E(int b) => registers.E = b;
  set H(int b) => registers.H = b;
  set L(int b) => registers.L = b;
  set S(int b) => registers.S = b;
  set P(int b) => registers.P = b;
  set IX_H(int b) => registers.IX_H = b;
  set IX_L(int b) => registers.IX_L = b;
  set IY_H(int b) => registers.IY_H = b;
  set IY_L(int b) => registers.IY_L = b;
  set I(int b) => registers.I = b;
  set R(int b) => registers.R = b;

  int get AF => registers.AF;
  int get BC => registers.BC;
  int get DE => registers.DE;
  int get HL => registers.HL;
  int get SP => registers.SP;
  int get IX => registers.IX;
  int get IY => registers.IY;
  int get AFt => registers.AFt;
  int get BCt => registers.BCt;
  int get DEt => registers.DEt;
  int get HLt => registers.HLt;

  set AF(int w) => registers.AF = w;
  set BC(int w) => registers.BC = w;
  set DE(int w) => registers.DE = w;
  set HL(int w) => registers.HL = w;
  set SP(int w) => registers.SP = w;
  set IX(int w) => registers.IX = w;
  set IY(int w) => registers.IY = w;
  set AFt(int w) => registers.AFt = w;
  set BCt(int w) => registers.BCt = w;
  set DEt(int w) => registers.DEt = w;
  set HLt(int w) => registers.HLt = w;

  bool get carryFlag => registers.carryFlag;
  bool get addSubtractFlag => registers.addSubtractFlag;
  bool get parityOverflowFlag => registers.parityOverflowFlag;
  bool get halfCarryFlag => registers.halfCarryFlag;
  bool get zeroFlag => registers.zeroFlag;
  bool get signFlag => registers.signFlag;

  set carryFlag(bool b) => registers.carryFlag = b;
  set addSubtractFlag(bool b) => registers.addSubtractFlag = b;
  set parityOverflowFlag(bool b) => registers.parityOverflowFlag = b;
  set halfCarryFlag(bool b) => registers.halfCarryFlag = b;
  set zeroFlag(bool b) => registers.zeroFlag = b;
  set signFlag(bool b) => registers.signFlag = b;

  int fetch() {
    final v = memory.peek(PC);
    PC = word(PC + 1);
    return v;
  }

  int fetch2() {
    final v = memory.peek2(PC);
    PC = word(PC + 2);
    return v;
  }

  int step() {
    var tStates = 0;

    if (halted) return 4;

    final opcode = fetch();

    switch (opcode) {
      case IX_PREFIX:
      case IY_PREFIX:
        tStates = processIXYOpcodes(opcode);
        R = R + 2;
        break;

      case EXTENDED_OPCODES:
        tStates = processOpcode(InstructionContext(fetch()), extendedOpcodes);
        R = R + 2;
        break;

      case BIT_OPCODES:
        tStates = processOpcode(InstructionContext(fetch()), bitOpcodes);
        R = R + 2;
        break;

      default:
        tStates = processOpcode(InstructionContext(opcode), unPrefixedOpcodes);
        R = R + 1;
        break;
    }

    return tStates;
  }

  Z80Instruction getInstruction() {
    Z80Instruction i;

    var d0 = memory.peek(PC + 0);
    var d1 = memory.peek(PC + 1);
    var d3 = memory.peek(PC + 3);
    switch (d0) {
      case IX_PREFIX:
      case IY_PREFIX:
        switch (d1) {
          case BIT_OPCODES:
            i = iXYbitOpcodes[d3];
            break;

          default:
            i = iXYOpcodes[d1];
            break;
        }
        break;

      case EXTENDED_OPCODES:
        i = extendedOpcodes[d1];
        break;

      case BIT_OPCODES:
        i = bitOpcodes[d1];
        break;

      default:
        i = unPrefixedOpcodes[d0];
        break;
    }

    return i;
  }

  int processIXYOpcodes(int prefix) {
    var tStates = 0;

    final opcode = fetch();

    switch (opcode) {
      case BIT_OPCODES:
        var d = fetch();
        tStates = processOpcode(
            InstructionContext.withPrefixAndDisplacement(fetch(), prefix, d),
            iXYbitOpcodes);
        break;

      default:
        tStates = processOpcode(
            InstructionContext.withPrefix(opcode, prefix), iXYOpcodes);
        break;
    }

    return tStates;
  }

  int processOpcode(
      InstructionContext context, Z80Instructions z80Instructions) {
    return z80Instructions.execute(context);
  }

  int byte(int v) => v % 256;

  int signedByte(int b) {
    var sb = byte(b);
    return (sb < 128) ? sb : sb - 256;
  }

  int word(int v) => v % 65536;

  int getIXY(int prefix) => prefix == IX_PREFIX ? IX : IY;

  void setIXY(int prefix, int w) => prefix == IX_PREFIX ? IX = w : IY = w;

  int getRIXY(int r8, int prefix) => prefix == IX_PREFIX
      ? r8 == Registers.R_H
          ? Registers.R_IX_H
          : r8 == Registers.R_L ? Registers.R_IX_L : r8
      : prefix == IY_PREFIX
          ? r8 == Registers.R_H
              ? Registers.R_IY_H
              : r8 == Registers.R_L ? Registers.R_IY_L : r8
          : r8;

  int iXYDisp(int prefix, int d) => getIXY(prefix) + signedByte(d);

  int r8Value(int r) => r == Registers.R_MHL ? memory.peek(HL) : registers[r];

  void setR8Value(int r, int b) =>
      r == Registers.R_MHL ? memory.poke(HL, byte(b)) : registers[r] = byte(b);

  int r16Value(int r) => 256 * registers[r] + registers[r + 1];

  void setR16Value(int r, int w) {
    registers[r] = hi(w);
    registers[r + 1] = lo(w);
  }

  int addWord(int w1, int w2) {
    int r = w1 + w2;
    carryFlag = r > 65535;
    addSubtractFlag = false;
    halfCarryFlag = (w1 & 0x0FFF) + (w2 & 0x0FFF) > 0x0FFF;
    return word(r);
  }

  void setZeroAndSignFlagsOn8BitResult(int b) {
    zeroFlag = b == 0;
    signFlag = b > 127;
  }

  void setZeroAndSignFlagsOn16BitResult(int b) {
    zeroFlag = b == 0;
    signFlag = b > 32767;
  }

  void push2(int w) {
    memory.poke(SP - 1, hi(w));
    memory.poke(SP - 2, lo(w));
    SP = SP - 2;
  }

  int pop2() {
    SP = SP + 2;
    return w(memory.peek(SP - 2), memory.peek(SP - 1));
  }

  bool sameSign8(int b1, int b2) => (b1 & 0x80) ^ (b2 & 0x80) == 0;

  bool getFlagCondition(int b) {
    bool flag;
    switch (b ~/ 2) {
      case 0:
        flag = zeroFlag;
        break;

      case 1:
        flag = carryFlag;
        break;

      case 2:
        flag = parityOverflowFlag;
        break;

      case 3:
        flag = signFlag;
        break;
    }

    if (b % 2 == 0) flag = !flag;

    return flag;
  }

  bool parity(int b) {
    var count = 0;
    for (var i = 0; i < 8; i++) {
      count += b & 0x01;
      b = b >> 1;
    }
    return count & 0x01 == 0x01;
  }

  int addA(int value) {
    var sum = A + value;
    carryFlag = sum > 255;
    halfCarryFlag = (A & 0x0F) + (value & 0x0F) > 0x0F;
    var result = byte(sum);
    parityOverflowFlag = (((A & 0x80) ^ (value & 0x80)) == 0) &&
        (value & 0x80 != (result & 0x80));
    setZeroAndSignFlagsOn8BitResult(result);
    addSubtractFlag = false;

    return result;
  }

  int incR8Value(int value) {
    parityOverflowFlag = value == 0x7F;
    halfCarryFlag = 1 + (value & 0x0F) > 0x0F;
    var newValue = byte(value + 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    addSubtractFlag = false;

    return newValue;
  }

  int decR8Value(int value) {
    parityOverflowFlag = value == 0x80;
    halfCarryFlag = (value & 0x0F) - 1 < 0;
    var newValue = byte(value - 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    addSubtractFlag = true;

    return newValue;
  }

  int adcA(int value) => addA(value + (carryFlag ? 1 : 0));

  int subA(int value) {
    var diff = A - value;
    carryFlag = diff < 0;
    halfCarryFlag = (A & 0x0F) - (value & 0x0F) < 0;
    var result = byte(diff);
    parityOverflowFlag = !sameSign8(A, value) && sameSign8(value, result);
    setZeroAndSignFlagsOn8BitResult(result);
    addSubtractFlag = true;

    return result;
  }

  int sbcA(int value) => subA(value + (carryFlag ? 1 : 0));

  int andA(int value) {
    var result = A & value;
    setZeroAndSignFlagsOn8BitResult(result);
    carryFlag = false;
    halfCarryFlag = true;
    addSubtractFlag = false;
    parityOverflowFlag = parity(result);

    return result;
  }

  int xorA(int value) {
    var result = A ^ value;
    setZeroAndSignFlagsOn8BitResult(result);
    carryFlag = false;
    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = parity(result);

    return result;
  }

  int orA(int value) {
    var result = A | value;
    setZeroAndSignFlagsOn8BitResult(result);
    carryFlag = false;
    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = parity(result);

    return result;
  }

  int cpA(int value) => subA(value);

  int rlOp(int value) {
    var b7 = (value & 0x80) >> 7;
    var result = byte(value << 1) | (carryFlag ? 0x01 : 0x00);
    carryFlag = b7 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    return result;
  }

  int rl(int value) {
    var result = rlOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int rrOp(int value) {
    var b0 = (value & 0x01);
    var result = byte(value >> 1) | (carryFlag ? 0x80 : 0x00);
    carryFlag = b0 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    return result;
  }

  int rr(int value) {
    var result = rrOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int rlcOp(int value) {
    var b7 = (value & 0x80) >> 7;
    var result = byte(value << 1) | b7;
    carryFlag = b7 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    return result;
  }

  int rlc(int value) {
    var result = rlcOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int rrcOp(int value) {
    int b0 = (value & 0x01);
    var result = byte(value >> 1) | (b0 << 7);
    carryFlag = b0 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    return result;
  }

  int rrc(int value) {
    var result = rrcOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int sla(int value) {
    carryFlag = value & 0x80 == 0x80;
    addSubtractFlag = false;
    halfCarryFlag = false;
    var result = byte(value << 1);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int sra(int value) {
    int b0 = (value & 0x01);
    var b7 = (value & 0x80);
    var result = byte(value >> 1) | b7;
    carryFlag = b0 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  int srl(int value) {
    int b0 = (value & 0x01);
    var result = byte(value >> 1);
    carryFlag = b0 == 1;
    addSubtractFlag = false;
    halfCarryFlag = false;
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    return result;
  }

  void bitNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    zeroFlag = value & mask == 0;
    halfCarryFlag = true;
    addSubtractFlag = false;
  }

  int resNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    return value & ~mask;
  }

  int setNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    return value | mask;
  }

  int nop(InstructionContext context) {
    return context.instruction.tStates();
  }

  int daa(InstructionContext context) {
    var sign = addSubtractFlag ? -1 : 1;
    if (halfCarryFlag || (A & 0x0F > 0x09)) A = addA(0x06 * sign);
    if (carryFlag || (A & 0xF0 > 0x90)) A = addA(0x60 * sign);

    return context.instruction.tStates();
  }

  int rlca(InstructionContext context) {
    A = rlcOp(A);
    return context.instruction.tStates();
  }

  int rlcR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rlc(r8Value(r8)));
    return context.instruction.tStates();
  }

  int rrcR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rrc(r8Value(r8)));
    return context.instruction.tStates();
  }

  int rlR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rl(r8Value(r8)));
    return context.instruction.tStates();
  }

  int rrR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rr(r8Value(r8)));
    return context.instruction.tStates();
  }

  int slaR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, sla(r8Value(r8)));
    return context.instruction.tStates();
  }

  int sraR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, sra(r8Value(r8)));
    return context.instruction.tStates();
  }

  int srlR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, srl(r8Value(r8)));
    return context.instruction.tStates();
  }

  int rrca(InstructionContext context) {
    A = rrcOp(A);
    return context.instruction.tStates();
  }

  int rla(InstructionContext context) {
    A = rlOp(A);
    return context.instruction.tStates();
  }

  int rra(InstructionContext context) {
    A = rrOp(A);
    return context.instruction.tStates();
  }

  int cpl(InstructionContext context) {
    A = A ^ 255;
    addSubtractFlag = true;
    halfCarryFlag = true;
    return context.instruction.tStates();
  }

  int scf(InstructionContext context) {
    F = F & ~Registers.F_ADD_SUB | Registers.F_CARRY;
    addSubtractFlag = false;
    halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ccf(InstructionContext context) {
    F = F & ~Registers.F_ADD_SUB ^ Registers.F_CARRY;
    return context.instruction.tStates();
  }

  int djnz(InstructionContext context) {
    var d = fetch();
    B = byte(B - 1);
    bool cond = B != 0;
    if (cond) {
      PC = word(PC + signedByte(d));
    }
    return context.instruction.tStates(cond: cond);
  }

  int jr(InstructionContext context) {
    var d = fetch();
    PC = word(PC + signedByte(d));
    return context.instruction.tStates();
  }

  int jrcc(InstructionContext context) {
    var d = fetch();
    var cond = getFlagCondition(bit345(context.opcode) - 4);
    if (cond) {
      PC = word(PC + signedByte(d));
    }
    return context.instruction.tStates(cond: cond);
  }

  int ldmBCA(InstructionContext context) {
    memory.poke(BC, A);
    return context.instruction.tStates();
  }

  int ldAmBC(InstructionContext context) {
    A = memory.peek(BC);
    return context.instruction.tStates();
  }

  int ldAmDE(InstructionContext context) {
    A = memory.peek(DE);
    return context.instruction.tStates();
  }

  int ldmDEA(InstructionContext context) {
    memory.poke(DE, A);
    return context.instruction.tStates();
  }

  int exAFAFq(InstructionContext context) {
    final af = AF;
    AF = AFt;
    AFt = af;
    return context.instruction.tStates();
  }

  int incR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit345(context.opcode), context.prefix);
    setR8Value(r8, incR8Value(r8Value(r8)));
    return context.instruction.tStates();
  }

  int incmIXY(InstructionContext context) {
    var d = fetch();
    memory.poke(iXYDisp(context.prefix, d),
        incR8Value(memory.peek(iXYDisp(context.prefix, d))));
    return context.instruction.tStates();
  }

  int decmIXY(InstructionContext context) {
    var d = fetch();
    memory.poke(iXYDisp(context.prefix, d),
        decR8Value(memory.peek(iXYDisp(context.prefix, d))));
    return context.instruction.tStates();
  }

  int addIXYR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setIXY(context.prefix, addWord(getIXY(context.prefix), r16Value(r16)));
    return context.instruction.tStates();
  }

  int addIXYIXY(InstructionContext context) {
    setIXY(context.prefix,
        addWord(getIXY(context.prefix), getIXY(context.prefix)));
    return context.instruction.tStates();
  }

  int decR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit345(context.opcode), context.prefix);
    setR8Value(r8, decR8Value(r8Value(r8)));
    return context.instruction.tStates();
  }

  int incR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, word(r16Value(r16) + 1));
    return context.instruction.tStates();
  }

  int decR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, word(r16Value(r16) - 1));
    return context.instruction.tStates();
  }

  int addHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    HL = addWord(HL, r16Value(r16));
    return context.instruction.tStates();
  }

  int ldR8n(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit345(context.opcode), context.prefix);
    setR8Value(r8, fetch());
    return context.instruction.tStates();
  }

  int ldR8mHL(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, memory.peek(HL));
    return context.instruction.tStates();
  }

  int ldmnnHL(InstructionContext context) {
    memory.poke2(fetch2(), HL);
    return context.instruction.tStates();
  }

  int ldHLmnn(InstructionContext context) {
    HL = memory.peek2(fetch2());
    return context.instruction.tStates();
  }

  int ldmnnA(InstructionContext context) {
    memory.poke(fetch2(), A);
    return context.instruction.tStates();
  }

  int ldAmnn(InstructionContext context) {
    A = memory.peek(fetch2());
    return context.instruction.tStates();
  }

  int ldmHLnn(InstructionContext context) {
    memory.poke(HL, fetch());
    return context.instruction.tStates();
  }

  int addAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = addA(r8Value(r8));
    return context.instruction.tStates();
  }

  int adcAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = adcA(r8Value(r8));
    return context.instruction.tStates();
  }

  int subAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = subA(r8Value(r8));
    return context.instruction.tStates();
  }

  int sbcAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = sbcA(r8Value(r8));
    return context.instruction.tStates();
  }

  int andAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = andA(r8Value(r8));
    return context.instruction.tStates();
  }

  int xorAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = xorA(r8Value(r8));
    return context.instruction.tStates();
  }

  int orAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    A = orA(r8Value(r8));
    return context.instruction.tStates();
  }

  int cpAR8(InstructionContext context) {
    int r8 = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    subA(r8Value(r8));
    return context.instruction.tStates();
  }

  int addAn(InstructionContext context) {
    A = addA(fetch());
    return context.instruction.tStates();
  }

  int adcAn(InstructionContext context) {
    A = adcA(fetch());
    return context.instruction.tStates();
  }

  int subAn(InstructionContext context) {
    A = subA(fetch());
    return context.instruction.tStates();
  }

  int sbcAn(InstructionContext context) {
    A = sbcA(fetch());
    return context.instruction.tStates();
  }

  int andAn(InstructionContext context) {
    A = andA(fetch());
    return context.instruction.tStates();
  }

  int xorAn(InstructionContext context) {
    A = xorA(fetch());
    return context.instruction.tStates();
  }

  int orAn(InstructionContext context) {
    A = orA(fetch());
    return context.instruction.tStates();
  }

  int cpAn(InstructionContext context) {
    cpA(fetch());
    return context.instruction.tStates();
  }

  int ldR8R8(InstructionContext context) {
    int r8Dest = getRIXY(Registers.rBit345(context.opcode), context.prefix);
    int r8Source = getRIXY(Registers.rBit012(context.opcode), context.prefix);
    setR8Value(r8Dest, r8Value(r8Source));
    return context.instruction.tStates();
  }

  int ldR16nn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, fetch2());
    return context.instruction.tStates();
  }

  int inR8C(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    var result = ports.inPort(BC);
    setR8Value(r8, result);
    setZeroAndSignFlagsOn8BitResult(result);
    parityOverflowFlag = parity(result);
    addSubtractFlag = false;
    halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int outCR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    ports.outPort(BC, r8Value(r8));
    return context.instruction.tStates();
  }

  int sbcHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    int value = r16Value(r16);
    int cf = (carryFlag ? 1 : 0);
    var result = HL - value - cf;
    parityOverflowFlag = (((HL & 0x8000) ^ (value & 0x8000)) == 0) &&
        (value & 0x8000 != (result & 0x8000));
    carryFlag = result < 0;
    halfCarryFlag = (HL & 0x0FFF) - (value & 0x0FFF) - cf < 0x00;
    addSubtractFlag = true;
    HL = word(result);
    setZeroAndSignFlagsOn16BitResult(HL);
    return context.instruction.tStates();
  }

  int adcHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    int value = r16Value(r16);
    int cf = (carryFlag ? 1 : 0);
    var result = HL + value + cf;
    parityOverflowFlag = (((HL & 0x8000) ^ (value & 0x8000)) == 0) &&
        (value & 0x8000 != (result & 0x8000));
    carryFlag = result > 65535;
    halfCarryFlag = (HL & 0x0FFF) + (value & 0x0FFF) + cf > 0x0FFF;
    addSubtractFlag = false;
    HL = word(result);
    setZeroAndSignFlagsOn16BitResult(HL);
    return context.instruction.tStates();
  }

  int ldmnnR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    memory.poke2(fetch2(), r16Value(r16));
    return context.instruction.tStates();
  }

  int ldR16mnn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    var a = fetch2();
    setR16Value(r16, memory.peek2(a));
    return context.instruction.tStates();
  }

  int neg(InstructionContext context) {
    carryFlag = A != 0;
    parityOverflowFlag = A == 0x80;
    halfCarryFlag = A != 0;
    addSubtractFlag = true;
    var result = byte(0 - A);
    A = result;
    setZeroAndSignFlagsOn8BitResult(result);
    return context.instruction.tStates();
  }

  int callnn(InstructionContext context) {
    var address = fetch2();
    push2(PC);
    PC = address;
    return context.instruction.tStates();
  }

  int ret(InstructionContext context) {
    PC = pop2();
    return context.instruction.tStates();
  }

  int retn(InstructionContext context) => ret(context);
  int reti(InstructionContext context) => ret(context);

  int jpnn(InstructionContext context) {
    PC = fetch2();
    return context.instruction.tStates();
  }

  int callccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    var address = fetch2();
    if (cond) {
      push2(PC);
      PC = address;
    }
    return context.instruction.tStates(cond: cond);
  }

  int retcc(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    if (cond) {
      PC = pop2();
    }
    return context.instruction.tStates(cond: cond);
  }

  int jpccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    var address = fetch2();
    if (cond) {
      PC = address;
    }
    return context.instruction.tStates(cond: cond);
  }

  int outnA(InstructionContext context) {
    var port = w(fetch(), A);
    ports.outPort(port, A);
    return context.instruction.tStates();
  }

  int inAn(InstructionContext context) {
    var port = w(fetch(), A);
    A = ports.inPort(port);
    return context.instruction.tStates();
  }

  int exx(InstructionContext context) {
    var bc = BC;
    var de = DE;
    var hl = HL;
    BC = BCt;
    DE = DEt;
    HL = HLt;
    BCt = bc;
    DEt = de;
    HLt = hl;
    return context.instruction.tStates();
  }

  int exSPHL(InstructionContext context) {
    var msp = memory.peek2(SP);
    memory.poke2(SP, HL);
    HL = msp;
    return context.instruction.tStates();
  }

  int jpmHL(InstructionContext context) {
    PC = HL;
    return context.instruction.tStates();
  }

  int exDEHL(InstructionContext context) {
    var de = DE;
    DE = HL;
    HL = de;
    return context.instruction.tStates();
  }

  int ldSPHL(InstructionContext context) {
    SP = HL;
    return context.instruction.tStates();
  }

  int pushR16(InstructionContext context) {
    int r16 = Registers.r16AFTable[bit45(context.opcode)];
    push2(r16Value(r16));
    return context.instruction.tStates();
  }

  int popR16(InstructionContext context) {
    int r16 = Registers.r16AFTable[bit45(context.opcode)];
    setR16Value(r16, pop2());
    return context.instruction.tStates();
  }

  int rstNN(InstructionContext context) {
    var rst = context.opcode & 0x38;
    push2(PC);
    PC = rst;
    return context.instruction.tStates();
  }

  int ldIXYnn(InstructionContext context) {
    setIXY(context.prefix, fetch2());
    return context.instruction.tStates();
  }

  int ldmnnIXY(InstructionContext context) {
    memory.poke2(fetch2(), getIXY(context.prefix));
    return context.instruction.tStates();
  }

  int ldIXYmnn(InstructionContext context) {
    setIXY(context.prefix, memory.peek2(fetch2()));
    return context.instruction.tStates();
  }

  int incIXY(InstructionContext context) {
    setIXY(context.prefix, word(getIXY(context.prefix) + 1));
    return context.instruction.tStates();
  }

  int decIXY(InstructionContext context) {
    setIXY(context.prefix, word(getIXY(context.prefix) - 1));
    return context.instruction.tStates();
  }

  int ldmIXYdn(InstructionContext context) {
    var d = fetch();
    var value = fetch();
    memory.poke(iXYDisp(context.prefix, d), value);
    return context.instruction.tStates();
  }

  int ldR8mIXYd(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    int d = fetch();
    setR8Value(r8, memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int ldmIXYdR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    int d = fetch();
    memory.poke(iXYDisp(context.prefix, d), r8Value(r8));
    return context.instruction.tStates();
  }

  int addAIXYd(InstructionContext context) {
    var d = fetch();
    A = addA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int adcAIXYd(InstructionContext context) {
    var d = fetch();
    A = adcA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int subAIXYd(InstructionContext context) {
    var d = fetch();
    A = subA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int sbcAIXYd(InstructionContext context) {
    var d = fetch();
    A = sbcA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int andAIXYd(InstructionContext context) {
    var d = fetch();
    A = andA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int xorAIXYd(InstructionContext context) {
    var d = fetch();
    A = xorA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int orAIXYd(InstructionContext context) {
    var d = fetch();
    A = orA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int cpAIXYd(InstructionContext context) {
    var d = fetch();
    cpA(memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int popIXY(InstructionContext context) {
    setIXY(context.prefix, pop2());
    return context.instruction.tStates();
  }

  int pushIXY(InstructionContext context) {
    push2(getIXY(context.prefix));
    return context.instruction.tStates();
  }

  int jpmIXY(InstructionContext context) {
    PC = getIXY(context.prefix);
    return context.instruction.tStates();
  }

  int exmSPIXY(InstructionContext context) {
    var msp = memory.peek2(SP);
    memory.poke2(SP, getIXY(context.prefix));
    setIXY(context.prefix, msp);
    return context.instruction.tStates();
  }

  int ldSPIXY(InstructionContext context) {
    SP = getIXY(context.prefix);
    return context.instruction.tStates();
  }

  int rlcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, rlc(memory.peek(address)));
    return context.instruction.tStates();
  }

  int rrcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, rrc(memory.peek(address)));
    return context.instruction.tStates();
  }

  int rlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, rl(memory.peek(address)));
    return context.instruction.tStates();
  }

  int rrMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, rr(memory.peek(address)));
    return context.instruction.tStates();
  }

  int slaMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, sla(memory.peek(address)));
    return context.instruction.tStates();
  }

  int sraMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, sra(memory.peek(address)));
    return context.instruction.tStates();
  }

  int srlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, srl(memory.peek(address)));
    return context.instruction.tStates();
  }

  int bitnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    bitNR8Op(bit, memory.peek(iXYDisp(context.prefix, d)));
    return context.instruction.tStates();
  }

  int resnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, resNR8Op(bit, memory.peek(address)));
    return context.instruction.tStates();
  }

  int setnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = iXYDisp(context.prefix, d);
    memory.poke(address, setNR8Op(bit, memory.peek(address)));
    return context.instruction.tStates();
  }

  int bitnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    bitNR8Op(bit, r8Value(r8));
    return context.instruction.tStates();
  }

  int resnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, resNR8Op(bit, r8Value(r8)));
    return context.instruction.tStates();
  }

  int setnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, setNR8Op(bit, r8Value(r8)));
    return context.instruction.tStates();
  }

  int im0(InstructionContext context) {
    interruptMode = InterruptMode.im0;
    return context.instruction.tStates();
  }

  int im1(InstructionContext context) {
    interruptMode = InterruptMode.im1;
    return context.instruction.tStates();
  }

  int im2(InstructionContext context) {
    interruptMode = InterruptMode.im2;
    return context.instruction.tStates();
  }

  int di(InstructionContext context) {
    interruptsEnabled = false;
    return context.instruction.tStates();
  }

  int ei(InstructionContext context) {
    interruptsEnabled = true;
    return context.instruction.tStates();
  }

  int halt(InstructionContext context) {
    halted = true;
    return context.instruction.tStates();
  }

  int ldAI(InstructionContext context) {
    A = I;
    setZeroAndSignFlagsOn8BitResult(A);
    addSubtractFlag = false;
    halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ldIA(InstructionContext context) {
    I = A;
    return context.instruction.tStates();
  }

  int ldAR(InstructionContext context) {
    A = R;
    setZeroAndSignFlagsOn8BitResult(A);
    addSubtractFlag = false;
    halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ldRA(InstructionContext context) {
    R = A;
    return context.instruction.tStates();
  }

  int rld(InstructionContext context) {
    int v1 = A;
    int v2 = memory.peek(HL);

    A = (v1 & 0xF0) | ((v2 & 0xF0) >> 4);
    memory.poke(HL, (v2 << 4) | (v1 & 0x0F));

    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = parity(A);
    setZeroAndSignFlagsOn8BitResult(A);

    return context.instruction.tStates();
  }

  int rrd(InstructionContext context) {
    int v1 = A;
    int v2 = memory.peek(HL);

    A = (v1 & 0xF0) | (v2 & 0x0F);
    memory.poke(HL, (v2 >> 4) | ((v1 & 0x0F) << 4));

    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = parity(A);
    setZeroAndSignFlagsOn8BitResult(A);

    return context.instruction.tStates();
  }

  int ldi(InstructionContext context) {
    memory.poke(DE, memory.peek(HL));
    HL = HL + 1;
    DE = DE + 1;
    BC = BC - 1;
    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = BC != 0;
    return context.instruction.tStates();
  }

  int ldd(InstructionContext context) {
    memory.poke(DE, memory.peek(HL));
    HL = HL - 1;
    DE = DE - 1;
    BC = BC - 1;
    halfCarryFlag = false;
    addSubtractFlag = false;
    parityOverflowFlag = BC != 0;
    return context.instruction.tStates();
  }

  int cpi(InstructionContext context) {
    subA(memory.peek(HL));
    HL = HL + 1;
    BC = BC - 1;
    addSubtractFlag = false;
    parityOverflowFlag = BC != 0;
    return context.instruction.tStates();
  }

  int cpd(InstructionContext context) {
    subA(memory.peek(HL));
    HL = HL - 1;
    BC = BC - 1;
    addSubtractFlag = false;
    parityOverflowFlag = BC != 0;
    return context.instruction.tStates();
  }

  int ini(InstructionContext context) {
    memory.poke(HL, ports.inPort(C));
    HL = HL + 1;
    B = B - 1;
    addSubtractFlag = true;
    zeroFlag = B == 0;
    return context.instruction.tStates();
  }

  int ind(InstructionContext context) {
    memory.poke(HL, ports.inPort(C));
    HL = HL - 1;
    B = B - 1;
    addSubtractFlag = true;
    zeroFlag = B == 0;
    return context.instruction.tStates();
  }

  int outi(InstructionContext context) {
    ports.outPort(C, memory.peek(HL));
    HL = HL + 1;
    B = B - 1;
    addSubtractFlag = true;
    zeroFlag = B == 0;
    return context.instruction.tStates();
  }

  int outd(InstructionContext context) {
    ports.outPort(C, memory.peek(HL));
    HL = HL - 1;
    B = B - 1;
    addSubtractFlag = true;
    zeroFlag = B == 0;
    return context.instruction.tStates();
  }

  int ldir(InstructionContext context) {
    ldi(context);
    var cond = BC == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int lddr(InstructionContext context) {
    ldd(context);
    var cond = BC == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int cpir(InstructionContext context) {
    cpi(context);
    var cond = BC == 0 || zeroFlag;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int cpdr(InstructionContext context) {
    cpd(context);
    var cond = BC == 0 || zeroFlag;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int inir(InstructionContext context) {
    ini(context);
    zeroFlag = true;
    var cond = B == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int indr(InstructionContext context) {
    ind(context);
    zeroFlag = true;
    var cond = B == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int otir(InstructionContext context) {
    outi(context);
    zeroFlag = true;
    var cond = B == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int otdr(InstructionContext context) {
    outd(context);
    zeroFlag = true;
    var cond = B == 0;
    if (!cond) PC = PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  void buildUnprefixedOpcodes() {
    unPrefixedOpcodes = Z80Instructions();
    var unPrefixed = unPrefixedOpcodes;

    unPrefixed.build(0x00, "NOP", nop, 4);
    unPrefixed.buildM16C4(0x01, "LD [r16], nn", ldR16nn, 10);
    unPrefixed.build(0x02, "LD (BC), A", ldmBCA, 7);
    unPrefixed.buildM16C4(0x03, "INC [r16]", incR16, 6);
    unPrefixed.buildM8C8(0x04, "INC [rb345]", incR8, 4);
    unPrefixed.buildM8C8(0x05, "DEC [rb345]", decR8, 4);
    unPrefixed.buildM8C8(0x06, "LD [rb345], n", ldR8n, 7);
    unPrefixed.build(0x07, "RLCA", rlca, 4);
    unPrefixed.build(0x08, "EX AF, AF'", exAFAFq, 4);
    unPrefixed.buildM16C4(0x09, "ADD HL, [r16]", addHLR16, 11);
    unPrefixed.build(0x0A, "LD A, (BC)", ldAmBC, 4);
    unPrefixed.buildM16C4(0x0B, "DEC [r16]", decR16, 6);
    unPrefixed.build(0x0F, "RRCA", rrca, 4);

    unPrefixed.build(0x10, "DJNZ nn", djnz, 8, tStatesOnTrueCond: 13);
    unPrefixed.build(0x12, "LD (DE), A", ldmDEA, 7);
    unPrefixed.build(0x17, "RLA", rla, 4);
    unPrefixed.build(0x18, "JR nn", jr, 12);
    unPrefixed.build(0x1A, "LD A, (DE)", ldAmDE, 7);
    unPrefixed.build(0x1F, "RRA", rra, 4);

    unPrefixed.buildM8C8(0x20, "JR [cc], nn", jrcc, 7,
        tStatesOnTrueCond: 12, count: 4);
    unPrefixed.build(0x22, "LD (nn), HL", ldmnnHL, 16);
    unPrefixed.build(0x27, "DAA", daa, 4);
    unPrefixed.build(0x2A, "LD HL, (nn)", ldHLmnn, 16);
    unPrefixed.build(0x2F, "CPL", cpl, 4);

    unPrefixed.build(0x32, "LD (nn), A", ldmnnA, 10);
    unPrefixed.build(0x36, "LD (HL), nn", ldmHLnn, 10);
    unPrefixed.build(0x37, "SCF", scf, 4);
    unPrefixed.build(0x3A, "LD A, (nn)", ldAmnn, 13);
    unPrefixed.build(0x3F, "CCF", ccf, 4);

    unPrefixed.build(0x40, "LD [rb345], [rb012]", ldR8R8, 4, count: 64);
    unPrefixed.buildM8C8(0x46, "LD [rb345], (HL)", ldR8R8, 7);

    unPrefixed.buildM1C8(0x70, "LD (HL), [rb012]", ldR8R8, 7);
    unPrefixed.build(0x76, "HALT", halt, 4);
    unPrefixed.buildM1C8(0x80, "ADD A, [rb012]", addAR8, 4);
    unPrefixed.buildM1C8(0x88, "ADC A, [rb012]", adcAR8, 4);
    unPrefixed.buildM1C8(0x90, "SUB [rb012]", subAR8, 4);
    unPrefixed.buildM1C8(0x98, "SBC [rb012]", sbcAR8, 4);
    unPrefixed.buildM1C8(0xA0, "AND [rb012]", andAR8, 4);
    unPrefixed.buildM1C8(0xA8, "XOR [rb012]", xorAR8, 4);
    unPrefixed.buildM1C8(0xB0, "OR [rb012]", orAR8, 4);
    unPrefixed.buildM1C8(0xB8, "CP [rb012]", cpAR8, 4);

    unPrefixed.buildM8C8(0xC0, "RET [cc]", retcc, 5, tStatesOnTrueCond: 11);
    unPrefixed.buildM16C4(0xC1, "POP [r16af]", popR16, 10);
    unPrefixed.buildM8C8(0xC2, "JP [cc], nn", jpccnn, 10,
        tStatesOnTrueCond: 10);
    unPrefixed.build(0xC3, "JP nn", jpnn, 10);
    unPrefixed.buildM8C8(0xC4, "CALL [cc], nn", callccnn, 10,
        tStatesOnTrueCond: 17);
    unPrefixed.buildM16C4(0xC5, "PUSH [r16af]", pushR16, 11);
    unPrefixed.build(0xC6, "ADD A, N", addAn, 7);
    unPrefixed.buildM8C8(0xC7, "RST [rst]", rstNN, 11);
    unPrefixed.build(0xC9, "RET", ret, 10);
    unPrefixed.build(0xCD, "CALL nn", callnn, 17);
    unPrefixed.build(0xCE, "ADC A, N", adcAn, 7);

    unPrefixed.build(0xD3, "OUT (N), A", outnA, 11);
    unPrefixed.build(0xD6, "SUB N", subAn, 7);
    unPrefixed.build(0xD9, "EXX", exx, 4);
    unPrefixed.build(0xDB, "IN A, (N)", inAn, 11);
    unPrefixed.build(0xDE, "SBC A, N", sbcAn, 7);

    unPrefixed.build(0xE3, "EX (SP), HL", exSPHL, 19);
    unPrefixed.build(0xE6, "AND A, N", andAn, 7);
    unPrefixed.build(0xE9, "JP (HL)", jpmHL, 4);
    unPrefixed.build(0xEB, "EX DE, HL", exDEHL, 4);
    unPrefixed.build(0xEE, "XOR N", xorAn, 7);

    unPrefixed.build(0xF3, "DI", di, 4);
    unPrefixed.build(0xF6, "OR N", orAn, 7);
    unPrefixed.build(0xF9, "LD SP, HL", ldSPHL, 6);
    unPrefixed.build(0xFB, "EI", ei, 4);
    unPrefixed.build(0xFE, "CP N", cpAn, 7);
  }

  void buildExtendedOpcodes() {
    extendedOpcodes = Z80Instructions();
    extendedOpcodes.buildM8C8(0x40, "IN [rb345], (C)", inR8C, 12);
    extendedOpcodes.buildM8C8(0x41, "OUT (C), [rb345]", outCR8, 12);
    extendedOpcodes.buildM16C4(0x42, "SBC HL, [r16]", sbcHLR16, 15);
    extendedOpcodes.buildM16C4(0x43, "LD (nn), [r16]", ldmnnR16, 20);
    extendedOpcodes.buildM16C4(0x44, "NEG", neg, 8);
    extendedOpcodes.buildM16C4(0x45, "RETN", retn, 14);
    extendedOpcodes.buildM16C4(0x4A, "ADC HL, [r16]", adcHLR16, 15);
    extendedOpcodes.buildM16C4(0x4B, "LD [r16], (nn)", ldR16mnn, 20);
    extendedOpcodes.buildM16C4(0x4C, "NEG", neg, 8);
    extendedOpcodes.buildM16C4(0x4D, "RETI", reti, 14);

    extendedOpcodes.buildM16C4(0x46, "IM 0", im0, 8);
    extendedOpcodes.buildM16C4(0x56, "IM 1", im1, 8);
    extendedOpcodes.buildM16C4(0x5E, "IM 2", im2, 8);

    extendedOpcodes.buildM16C4(0x47, "LD I, A", ldIA, 9);
    extendedOpcodes.buildM16C4(0x4F, "LD R, A", ldRA, 9);
    extendedOpcodes.buildM16C4(0x57, "LD A, I", ldAI, 9);
    extendedOpcodes.buildM16C4(0x5F, "LD A, R", ldAR, 9);

    extendedOpcodes.build(0x67, "RDD", rrd, 18);
    extendedOpcodes.build(0x6F, "RLD", rld, 18);

    extendedOpcodes.build(0xA0, "LDI", ldi, 16);
    extendedOpcodes.build(0xA1, "CPI", cpi, 16);
    extendedOpcodes.build(0xA2, "INI", ini, 16);
    extendedOpcodes.build(0xA3, "OUTI", outi, 16);
    extendedOpcodes.build(0xA8, "LDD", ldd, 16);
    extendedOpcodes.build(0xA9, "CPD", cpd, 16);
    extendedOpcodes.build(0xAA, "IND", ind, 16);
    extendedOpcodes.build(0xAB, "OUTD", outd, 16);
    extendedOpcodes.build(0xB0, "LDIR", ldir, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xB1, "CPIR", cpir, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xB2, "INIR", inir, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xB3, "OTIR", otir, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xB8, "LDDR", lddr, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xB9, "CPDR", cpdr, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xBB, "OTDR", otdr, 21, tStatesOnTrueCond: 16);
    extendedOpcodes.build(0xBA, "INDR", indr, 21, tStatesOnTrueCond: 16);
  }

  void buildIXYOpcodes() {
    iXYOpcodes = Z80Instructions();

    iXYOpcodes.build(0x09, "ADD IXY, BC", addIXYR16, 15);
    iXYOpcodes.build(0x19, "ADD IXY, DE", addIXYR16, 15);
    iXYOpcodes.build(0x39, "ADD IXY, SP", addIXYR16, 15);
    iXYOpcodes.build(0x29, "ADD IXY, IXY", addIXYIXY, 15);

    iXYOpcodes.build(0x24, "INC IXYH", incR8, 8);
    iXYOpcodes.build(0x25, "DEC IXYH", decR8, 8);

    iXYOpcodes.build(0x26, "LD IXYH, n", ldR8n, 11);

    iXYOpcodes.build(0x2C, "INC IXYL", incR8, 8);
    iXYOpcodes.build(0x2D, "DEC IXYL", decR8, 8);

    iXYOpcodes.build(0x2E, "LD IXYL, n", ldR8n, 11);

    iXYOpcodes.build(0x44, "LD [rb345], IXH", ldR8R8, 8,
        count: 4, multiplier: 8);

    iXYOpcodes.build(0x45, "LD [rb345], IXL", ldR8R8, 8,
        count: 4, multiplier: 8);

    iXYOpcodes.build(0x60, "LD IXYH, [rb012]", ldR8R8, 8, count: 6);
    iXYOpcodes.build(0x67, "LD IXYH, [rb012]", ldR8R8, 8);

    iXYOpcodes.build(0x68, "LD IXYL, [rb012]", ldR8R8, 8, count: 6);
    iXYOpcodes.build(0x6F, "LD IXYL, [rb012]", ldR8R8, 8);

    iXYOpcodes.build(0x7C, "LD A, IXYH", ldR8R8, 8);
    iXYOpcodes.build(0x7D, "LD A, IXYL", ldR8R8, 8);

    iXYOpcodes.build(0x34, "INC (IXY + d)", incmIXY, 23);
    iXYOpcodes.build(0x35, "DEC (IXY + d)", decmIXY, 23);

    iXYOpcodes.build(0x21, "LD IXY, nn", ldIXYnn, 23);
    iXYOpcodes.build(0x22, "LD (nn), IXY", ldmnnIXY, 23);
    iXYOpcodes.build(0x2A, "LD IXY, (nn)", ldIXYmnn, 23);
    iXYOpcodes.build(0x23, "INC IXY", incIXY, 23);
    iXYOpcodes.build(0x2B, "DEC IXY", decIXY, 23);
    iXYOpcodes.build(0x36, "LD (IXY + d), n", ldmIXYdn, 23);

    iXYOpcodes.buildM8C8(0x46, "LD [rb345], (IXY + d)", ldR8mIXYd, 19);
    iXYOpcodes.buildM1C8(0x70, "LD (IXY + d), [rb345]", ldmIXYdR8, 19);

    iXYOpcodes.build(0x36, "LD (IXY + d), n", ldmIXYdn, 23);

    iXYOpcodes.build(0x84, "ADD A, IXYH", addAR8, 8);
    iXYOpcodes.build(0x85, "ADD A, IXYL", addAR8, 8);
    iXYOpcodes.build(0x86, "ADD A, (IXY + d)", addAIXYd, 19);

    iXYOpcodes.build(0x8C, "ADC A, IXYH", adcAR8, 8);
    iXYOpcodes.build(0x8D, "ADC A, IXYL", adcAR8, 8);
    iXYOpcodes.build(0x8E, "ADC A, (IXY + d)", adcAIXYd, 19);

    iXYOpcodes.build(0x94, "SUB IXYH", subAR8, 8);
    iXYOpcodes.build(0x95, "SUB IXYL", subAR8, 8);
    iXYOpcodes.build(0x96, "SUB (IXY + d)", subAIXYd, 19);

    iXYOpcodes.build(0x9C, "SBC A, IXYH", sbcAR8, 8);
    iXYOpcodes.build(0x9D, "SBC A, IXYL", sbcAR8, 8);
    iXYOpcodes.build(0x9E, "SBC A, (IXY + d)", sbcAIXYd, 19);

    iXYOpcodes.build(0xA4, "AND IXYH", andAR8, 8);
    iXYOpcodes.build(0xA5, "AND IXYL", andAR8, 8);
    iXYOpcodes.build(0xA6, "AND (IXY + d)", andAIXYd, 19);

    iXYOpcodes.build(0xAC, "XOR IXYH", xorAR8, 8);
    iXYOpcodes.build(0xAD, "XOR IXYL", xorAR8, 8);
    iXYOpcodes.build(0xAE, "XOR (IXY + d)", xorAIXYd, 19);

    iXYOpcodes.build(0xB4, "OR IXYH", orAR8, 8);
    iXYOpcodes.build(0xB5, "OR IXYL", orAR8, 8);
    iXYOpcodes.build(0xB6, "OR (IXY + d)", orAIXYd, 19);

    iXYOpcodes.build(0xBC, "CP IXYH", cpAR8, 8);
    iXYOpcodes.build(0xBD, "CP IXYL", cpAR8, 8);
    iXYOpcodes.build(0xBE, "CP (IXY + d)", cpAIXYd, 19);

    iXYOpcodes.build(0xE1, "POP IXY", popIXY, 19);
    iXYOpcodes.build(0xE5, "PUSH IXY", pushIXY, 19);
    iXYOpcodes.build(0xE9, "JP (IXY)", jpmIXY, 19);
    iXYOpcodes.build(0xE3, "EX (SP)", exmSPIXY, 19);
    iXYOpcodes.build(0xF9, "LD SP, IXY", ldSPIXY, 19);
  }

  void buildBitOpcodes() {
    bitOpcodes = Z80Instructions();

    bitOpcodes.buildM1C8(0x00, "RLC [rb012]", rlcR8, 8);
    bitOpcodes.buildM1C8(0x08, "RRC [rb012]", rrcR8, 8);
    bitOpcodes.buildM1C8(0x10, "RL [rb012]", rlR8, 8);
    bitOpcodes.buildM1C8(0x18, "RR [rb012]", rrR8, 8);
    bitOpcodes.buildM1C8(0x20, "SLA [rb012]", slaR8, 8);
    bitOpcodes.buildM1C8(0x28, "SRA [rb012]", sraR8, 8);
    bitOpcodes.buildM1C8(0x38, "SRL [rb012]", srlR8, 8);

    bitOpcodes.build(0x40, "BIT [bit], [rb012]", bitnR8, 8, count: 128);
    bitOpcodes.build(0x80, "RES [bit], [rb012]", resnR8, 8, count: 128);
    bitOpcodes.build(0xC0, "SET [bit], [rb012]", setnR8, 8, count: 128);
  }

  void buildIXYBitOpcodes() {
    iXYbitOpcodes = Z80Instructions();

    iXYbitOpcodes.build(0x06, "RLC (IXY + d)", rlcMIXYd, 23);
    iXYbitOpcodes.build(0x0E, "RRC (IXY + d)", rrcMIXYd, 23);
    iXYbitOpcodes.build(0x16, "RL (IXY + d)", rlMIXYd, 23);
    iXYbitOpcodes.build(0x1E, "RR (IXY + d)", rrMIXYd, 23);
    iXYbitOpcodes.build(0x26, "SLA (IXY + d)", slaMIXYd, 23);
    iXYbitOpcodes.build(0x2E, "SRA (IXY + d)", sraMIXYd, 23);
    iXYbitOpcodes.build(0x3E, "SRL (IXY + d)", srlMIXYd, 23);

    iXYbitOpcodes.buildM8C8(0x46, "BIT [bit], (IXY + d)", bitnMIXYd, 20);
    iXYbitOpcodes.buildM8C8(0x86, "RES [bit], (IXY + d)", resnMIXYd, 20);
    iXYbitOpcodes.buildM8C8(0xC6, "SET [bit], (IXY + d)", setnMIXYd, 20);
  }

  void maskableInterrupt() {
    if (!interruptsEnabled) return;

    halted = false;

    switch (interruptMode) {
      case InterruptMode.im1:
        interruptsEnabled = false;
        push2(PC);
        PC = 0x38;
        break;

      case InterruptMode.im2:
        interruptsEnabled = false;
        push2(PC);
        PC = memory.peek2(I * 256 + 254);
        break;

      default:
        break;
    }
  }
}
