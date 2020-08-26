library z80a;

import 'package:Z80a/Cpu/Z80Instructions.dart';
import 'package:Z80a/Memory.dart';
import 'package:Z80a/Ports.dart';
import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Util.dart';

// ignore_for_file: non_constant_identifier_names

class Z80a {
  final Memory memory;
  final Ports ports;

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

  Z80a(this.memory, this.ports) {
    buildUnprefixedOpcodes();
    buildExtendedOpcodes();
    buildBitOpcodes();
    buildIXYOpcodes();
    buildIXYBitOpcodes();
  }

  var registers = Registers();
  var PC = 0;

  int fetch() {
    final v = this.memory.peek(this.PC);
    this.PC = this.PC + 1;
    return v;
  }

  int fetch2() {
    final v = this.memory.peek2(this.PC);
    this.PC = this.PC + 2;
    return v;
  }

  int step() {
    var tStates = 0;

    final opcode = fetch();

    switch (opcode) {
      case IX_PREFIX:
      case IY_PREFIX:
        tStates = processIXYOpcodes(opcode);
        break;

      case EXTENDED_OPCODES:
        tStates = processOpcode(InstructionContext(fetch()), extendedOpcodes);
        break;

      case BIT_OPCODES:
        tStates = processOpcode(InstructionContext(fetch()), bitOpcodes);
        break;

      default:
        tStates = processOpcode(InstructionContext(opcode), unPrefixedOpcodes);
        break;
    }

    return tStates;
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

  int word(int v) => v % 65536;

  int getIXY(int prefix) => prefix == IX_PREFIX ? registers.IX : registers.IY;

  void setIXY(int prefix, int w) =>
      prefix == IX_PREFIX ? registers.IX = w : registers.IY = w;

  int r8Value(int r) =>
      r == Registers.R_MHL ? this.memory.peek(registers.HL) : registers[r];

  int r16Value(int r) => 256 * registers[r] + registers[r + 1];

  void setR8Value(int r, int b) => r == Registers.R_MHL
      ? this.memory.poke(registers.HL, byte(b))
      : registers[r] = byte(b);

  void setR16Value(int r, int w) {
    registers[r] = hi(w);
    registers[r + 1] = lo(w);
  }

  int addWord(int w1, int w2) {
    int r = w1 + w2;
    registers.carryFlag = r > 65535;
    return word(r);
  }

  void setZeroAndSignFlagsOn8BitResult(int b) {
    registers.zeroFlag = b == 0;
    registers.signFlag = b > 127;
  }

  void setZeroAndSignFlagsOn16BitResult(int b) {
    registers.zeroFlag = b == 0;
    registers.signFlag = b > 32767;
  }

  void push2(int w) {
    this.memory.poke(registers.SP - 1, hi(w));
    this.memory.poke(registers.SP - 2, lo(w));
    registers.SP = registers.SP - 2;
  }

  int pop2() {
    registers.SP = registers.SP + 2;
    return w(
        this.memory.peek(registers.SP - 2), this.memory.peek(registers.SP - 1));
  }

  bool sameSign8(int b1, int b2) => (b1 & 0x80) ^ (b2 & 0x80) == 0;

  bool getFlagCondition(int b) {
    bool flag;
    switch (b ~/ 2) {
      case 0:
        flag = registers.zeroFlag;
        break;

      case 1:
        flag = registers.carryFlag;
        break;

      case 2:
        flag = registers.parityOverflowFlag;
        break;

      case 3:
        flag = registers.signFlag;
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
    var sum = registers.A + value;
    registers.carryFlag = sum > 255;
    registers.halfCarryFlag = (registers.A & 0x0F) + (value & 0x0F) > 0x0F;
    var result = byte(sum);
    registers.parityOverflowFlag =
        (((registers.A & 0x80) ^ (value & 0x80)) == 0) &&
            (value & 0x80 != (result & 0x80));
    setZeroAndSignFlagsOn8BitResult(result);
    registers.addSubtractFlag = false;

    return result;
  }

  int incR8Value(int value) {
    registers.parityOverflowFlag = value == 0x7F;
    var newValue = byte(value + 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    registers.addSubtractFlag = false;

    return newValue;
  }

  int decR8Value(int value) {
    registers.parityOverflowFlag = value == 0x80;
    var newValue = byte(value - 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    registers.addSubtractFlag = true;

    return newValue;
  }

  int adcA(int value) => addA(value + (registers.carryFlag ? 1 : 0));

  int subA(int value) {
    var diff = registers.A - value;
    registers.carryFlag = diff < 0;
    registers.halfCarryFlag = (registers.A & 0x0F) - (value & 0x0F) < 0;
    var result = byte(diff);
    registers.parityOverflowFlag =
        !sameSign8(registers.A, value) && sameSign8(value, result);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.addSubtractFlag = true;

    return result;
  }

  int sbcA(int value) => subA(value + (registers.carryFlag ? 1 : 0));

  int andA(int value) {
    var result = registers.A & value;
    setZeroAndSignFlagsOn8BitResult(result);
    registers.carryFlag = false;
    registers.halfCarryFlag = false;
    registers.addSubtractFlag = false;
    registers.parityOverflowFlag = parity(result);

    return result;
  }

  int xorA(int value) {
    var result = registers.A ^ value;
    setZeroAndSignFlagsOn8BitResult(result);
    registers.carryFlag = false;
    registers.halfCarryFlag = false;
    registers.addSubtractFlag = false;
    registers.parityOverflowFlag = parity(result);

    return result;
  }

  int orA(int value) {
    var result = registers.A | value;
    setZeroAndSignFlagsOn8BitResult(result);
    registers.carryFlag = false;
    registers.halfCarryFlag = false;
    registers.addSubtractFlag = false;
    registers.parityOverflowFlag = parity(result);

    return result;
  }

  int cpA(int value) => subA(value);

  int rlOp(int value) {
    var b7 = (value & 0x80) >> 7;
    var result = byte(value << 1) | (registers.carryFlag ? 0x01 : 0x00);
    registers.carryFlag = b7 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return result;
  }

  int rl(int value) {
    var result = rlOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int rrOp(int value) {
    var b0 = (value & 0x01);
    var result = byte(value >> 1) | (registers.carryFlag ? 0x80 : 0x00);
    registers.carryFlag = b0 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return result;
  }

  int rr(int value) {
    var result = rrOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int rlcOp(int value) {
    var b7 = (value & 0x80) >> 7;
    var result = byte(value << 1) | b7;
    registers.carryFlag = b7 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return result;
  }

  int rlc(int value) {
    var result = rlcOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int rrcOp(int value) {
    int b0 = (value & 0x01);
    var result = byte(value >> 1) | (b0 << 7);
    registers.carryFlag = b0 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return result;
  }

  int rrc(int value) {
    var result = rrcOp(value);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int sla(int value) {
    registers.carryFlag = value & 0x80 == 0x80;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    var result = byte(value << 1);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int sra(int value) {
    int b0 = (value & 0x01);
    var b7 = (value & 0x80);
    var result = byte(value >> 1) | b7;
    registers.carryFlag = b0 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  int srl(int value) {
    int b0 = (value & 0x01);
    var result = byte(value >> 1);
    registers.carryFlag = b0 == 1;
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    return result;
  }

  void bitNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    registers.zeroFlag = value & mask == 0;
    registers.halfCarryFlag = true;
    registers.addSubtractFlag = false;
  }

  int resNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    return value & ~mask;
  }

  int setNR8Op(int bit, int value) {
    var mask = bitMask[bit];
    return value | mask;
  }

  void nop(InstructionContext context) {}

  void rlca(InstructionContext context) {
    registers.A = rlcOp(registers.A);
  }

  void rlcR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rlc(r8Value(r8)));
  }

  void rrcR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rrc(r8Value(r8)));
  }

  void rlR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rl(r8Value(r8)));
  }

  void rrR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, rr(r8Value(r8)));
  }

  void slaR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, sla(r8Value(r8)));
  }

  void sraR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, sra(r8Value(r8)));
  }

  void srlR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, srl(r8Value(r8)));
  }

  void rrca(InstructionContext context) {
    registers.A = rrcOp(registers.A);
  }

  void rla(InstructionContext context) {
    registers.A = rlOp(registers.A);
  }

  void rra(InstructionContext context) {
    registers.A = rrOp(registers.A);
  }

  void cpl(InstructionContext context) {
    registers.A = registers.A ^ 255;
  }

  void scf(InstructionContext context) {
    registers.F = registers.F & ~Registers.F_ADD_SUB | Registers.F_CARRY;
  }

  void ccf(InstructionContext context) {
    registers.F = registers.F & ~Registers.F_ADD_SUB ^ Registers.F_CARRY;
  }

  void djnz(InstructionContext context) {
    var d = fetch();
    registers.B = byte(registers.B - 1);
    if (registers.B == 0) {
      this.PC = this.PC + d;
    }
  }

  void jr(InstructionContext context) {
    var d = fetch();
    this.PC = this.PC + d;
  }

  void jrcc(InstructionContext context) {
    var d = fetch();
    var cond = getFlagCondition(bit345(context.opcode) - 4);
    if (cond) {
      this.PC = this.PC + d;
    }
  }

  void ldmBCA(InstructionContext context) {
    this.memory.poke(registers.BC, registers.A);
  }

  void ldAmBC(InstructionContext context) {
    registers.A = this.memory.peek(registers.BC);
  }

  void ldAmDE(InstructionContext context) {
    registers.A = this.memory.peek(registers.DE);
  }

  void ldmDEA(InstructionContext context) {
    this.memory.poke(registers.DE, registers.A);
  }

  void exAFAFq(InstructionContext context) {
    final af = registers.AF;
    registers.AF = registers.AFt;
    registers.AFt = af;
  }

  void incR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, incR8Value(this.r8Value(r8)));
  }

  void incmIXY(InstructionContext context) {
    var d = fetch();
    this.memory.poke(getIXY(context.prefix) + d,
        incR8Value(this.memory.peek(getIXY(context.prefix) + d)));
  }

  void decmIXY(InstructionContext context) {
    var d = fetch();
    this.memory.poke(getIXY(context.prefix) + d,
        decR8Value(this.memory.peek(getIXY(context.prefix) + d)));
  }

  void addIXYR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setIXY(context.prefix, addWord(getIXY(context.prefix), r16Value(r16)));
  }

  void addIXYIXY(InstructionContext context) {
    setIXY(context.prefix,
        addWord(getIXY(context.prefix), getIXY(context.prefix)));
  }

  void decR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, decR8Value(this.r8Value(r8)));
  }

  void incR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, word(r16Value(r16) + 1));
  }

  void decR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, word(r16Value(r16) - 1));
  }

  void addHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    registers.HL = addWord(registers.HL, r16Value(r16));
  }

  void ldR8n(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, fetch());
  }

  void ldR8mHL(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, this.memory.peek(registers.HL));
  }

  void ldmHLR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    this.memory.poke(registers.HL, r8Value(r8));
  }

  void ldmnnHL(InstructionContext context) {
    this.memory.poke2(fetch2(), registers.HL);
  }

  void ldHLmnn(InstructionContext context) {
    registers.HL = this.memory.peek2(fetch2());
  }

  void ldmnnA(InstructionContext context) {
    this.memory.poke(fetch2(), registers.A);
  }

  void ldAmnn(InstructionContext context) {
    registers.A = this.memory.peek(fetch2());
  }

  void ldmHLnn(InstructionContext context) {
    this.memory.poke(registers.HL, fetch());
  }

  void addAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = addA(r8Value(r8));
  }

  void adcAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = adcA(r8Value(r8));
  }

  void subAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = subA(r8Value(r8));
  }

  void sbcAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = sbcA(r8Value(r8));
  }

  void andAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = andA(r8Value(r8));
  }

  void xorAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = xorA(r8Value(r8));
  }

  void orAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = orA(r8Value(r8));
  }

  void cpAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    subA(r8Value(r8));
  }

  void addAn(InstructionContext context) {
    registers.A = addA(fetch());
  }

  void adcAn(InstructionContext context) {
    registers.A = adcA(fetch());
  }

  void subAn(InstructionContext context) {
    registers.A = subA(fetch());
  }

  void sbcAn(InstructionContext context) {
    registers.A = sbcA(fetch());
  }

  void andAn(InstructionContext context) {
    registers.A = andA(fetch());
  }

  void xorAn(InstructionContext context) {
    registers.A = xorA(fetch());
  }

  void orAn(InstructionContext context) {
    registers.A = orA(fetch());
  }

  void cpAn(InstructionContext context) {
    cpA(fetch());
  }

  void ldR8R8(InstructionContext context) {
    int r8Dest = Registers.rBit345(context.opcode);
    int r8Source = Registers.rBit012(context.opcode);
    this.setR8Value(r8Dest, r8Value(r8Source));
  }

  void ldR16nn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, fetch2());
  }

  void inR8C(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    var result = this.ports.inPort(registers.C);
    setR8Value(r8, result);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
  }

  void outCR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    this.ports.outPort(registers.C, r8Value(r8));
  }

  void sbcHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    int value = r16Value(r16);
    int cf = (registers.carryFlag ? 1 : 0);
    var result = registers.HL - value - cf;
    registers.parityOverflowFlag =
        (((registers.HL & 0x8000) ^ (value & 0x8000)) == 0) &&
            (value & 0x8000 != (result & 0x8000));
    registers.carryFlag = result < 0;
    registers.halfCarryFlag =
        (registers.HL & 0x0FFF) - (value & 0x0FFF) - cf < 0x00;
    registers.addSubtractFlag = true;
    registers.HL = word(result);
    setZeroAndSignFlagsOn16BitResult(registers.HL);
  }

  void adcHLR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    int value = r16Value(r16);
    int cf = (registers.carryFlag ? 1 : 0);
    var result = registers.HL + value + cf;
    registers.parityOverflowFlag =
        (((registers.HL & 0x8000) ^ (value & 0x8000)) == 0) &&
            (value & 0x8000 != (result & 0x8000));
    registers.carryFlag = result > 65535;
    registers.halfCarryFlag =
        (registers.HL & 0x0FFF) + (value & 0x0FFF) + cf > 0x0FFF;
    registers.addSubtractFlag = false;
    registers.HL = word(result);
    setZeroAndSignFlagsOn16BitResult(registers.HL);
  }

  void ldmnnR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    this.memory.poke2(fetch2(), r16Value(r16));
  }

  void ldR16mnn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    var a = fetch2();
    setR16Value(r16, this.memory.peek2(a));
  }

  void neg(InstructionContext context) {
    registers.carryFlag = registers.A != 0;
    registers.parityOverflowFlag = registers.A == 0x80;
    registers.halfCarryFlag = registers.A != 0;
    registers.addSubtractFlag = true;
    var result = byte(0 - registers.A);
    registers.A = result;
    setZeroAndSignFlagsOn8BitResult(result);
  }

  void callnn(InstructionContext context) {
    var address = fetch2();
    push2(PC);
    this.PC = address;
  }

  void ret(InstructionContext context) {
    this.PC = pop2();
  }

  void jp(InstructionContext context) {
    this.PC = fetch2();
  }

  void callccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    var address = fetch2();
    if (cond) {
      push2(PC);
      this.PC = address;
    }
  }

  void retcc(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    if (cond) {
      this.PC = pop2();
    }
  }

  void jpccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    if (cond) {
      this.PC = fetch2();
    }
  }

  void outnA(InstructionContext context) {
    this.ports.outPort(fetch(), registers.A);
  }

  void inAn(InstructionContext context) {
    registers.A = this.ports.inPort(fetch());
  }

  void exx(InstructionContext context) {
    var bc = registers.BC;
    var de = registers.DE;
    var hl = registers.HL;
    registers.BC = registers.BCt;
    registers.DE = registers.DEt;
    registers.HL = registers.HLt;
    registers.BCt = bc;
    registers.DEt = de;
    registers.HLt = hl;
  }

  void exSPHL(InstructionContext context) {
    var msp = this.memory.peek2(registers.SP);
    this.memory.poke2(registers.SP, registers.HL);
    registers.HL = msp;
  }

  void jpmHL(InstructionContext context) {
    this.PC = this.memory.peek2(registers.HL);
  }

  void exDEHL(InstructionContext context) {
    var de = registers.DE;
    registers.DE = registers.HL;
    registers.HL = de;
  }

  void ldSPHL(InstructionContext context) {
    registers.SP = registers.HL;
  }

  void pushR16(InstructionContext context) {
    int r16 = Registers.r16AFTable[bit45(context.opcode)];
    push2(r16Value(r16));
  }

  void popR16(InstructionContext context) {
    int r16 = Registers.r16AFTable[bit45(context.opcode)];
    setR16Value(r16, pop2());
  }

  void rstNN(InstructionContext context) {
    var rst = context.opcode & 0x38;
    push2(this.PC);
    this.PC = rst;
  }

  void ldIXYnn(InstructionContext context) {
    setIXY(context.prefix, fetch2());
  }

  void ldmnnIXY(InstructionContext context) {
    this.memory.poke2(fetch2(), getIXY(context.prefix));
  }

  void ldIXYmnn(InstructionContext context) {
    setIXY(context.prefix, this.memory.peek2(fetch2()));
  }

  void incIXY(InstructionContext context) {
    setIXY(context.prefix, word(getIXY(context.prefix) + 1));
  }

  void decIXY(InstructionContext context) {
    setIXY(context.prefix, word(getIXY(context.prefix) - 1));
  }

  void ldmIXYdn(InstructionContext context) {
    var d = fetch();
    var value = fetch();
    this.memory.poke(getIXY(context.prefix) + d, value);
  }

  void ldR8mIXYd(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    int d = fetch();
    setR8Value(r8, this.memory.peek(getIXY(context.prefix) + d));
  }

  void ldmIXYdR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    int d = fetch();
    this.memory.poke(getIXY(context.prefix) + d, r8Value(r8));
  }

  void addAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = addA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void adcAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = adcA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void subAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = subA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void sbcAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = sbcA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void andAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = andA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void xorAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = xorA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void orAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = orA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void cpAIXYd(InstructionContext context) {
    var d = fetch();
    cpA(this.memory.peek(getIXY(context.prefix) + d));
  }

  void popIXY(InstructionContext context) {
    setIXY(context.prefix, pop2());
  }

  void pushIXY(InstructionContext context) {
    push2(getIXY(context.prefix));
  }

  void jpmIXY(InstructionContext context) {
    this.PC = this.memory.peek2(getIXY(context.prefix));
  }

  void exmSPIXY(InstructionContext context) {
    var msp = this.memory.peek2(registers.SP);
    this.memory.poke2(registers.SP, getIXY(context.prefix));
    setIXY(context.prefix, msp);
  }

  void ldSPIXY(InstructionContext context) {
    registers.SP = getIXY(context.prefix);
  }

  void rlcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rlc(this.memory.peek(address)));
  }

  void rrcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rrc(this.memory.peek(address)));
  }

  void rlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rl(this.memory.peek(address)));
  }

  void rrMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rr(this.memory.peek(address)));
  }

  void slaMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, sla(this.memory.peek(address)));
  }

  void sraMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, sra(this.memory.peek(address)));
  }

  void srlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, srl(this.memory.peek(address)));
  }

  void bitnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    bitNR8Op(bit, this.memory.peek(getIXY(context.prefix) + d));
  }

  void resnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, resNR8Op(bit, this.memory.peek(address)));
  }

  void setnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, setNR8Op(bit, this.memory.peek(address)));
  }

  void bitnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    bitNR8Op(bit, r8Value(r8));
  }

  void resnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, resNR8Op(bit, r8Value(r8)));
  }

  void setnR8(InstructionContext context) {
    var bit = bit345(context.opcode);
    int r8 = Registers.rBit012(context.opcode);
    setR8Value(r8, setNR8Op(bit, r8Value(r8)));
  }

  void buildUnprefixedOpcodes() {
    unPrefixedOpcodes = Z80Instructions();

    unPrefixedOpcodes.add(0x00, "NOP", nop, 4);
    unPrefixedOpcodes.addR16(0x01, "LD [r16], nn", ldR16nn, 4, multiplier: 16);
    unPrefixedOpcodes.add(0x02, "LD (BC), A", ldmBCA, 4);
    unPrefixedOpcodes.addR16(0x03, "INC [r16]", incR16, 4, multiplier: 16);
    unPrefixedOpcodes.addR8(0x04, "INC [r8]", incR8, 4, multiplier: 8);
    unPrefixedOpcodes.addR8(0x05, "DEC [r8]", decR8, 4, multiplier: 8);
    unPrefixedOpcodes.addR8(0x06, "LD [r8], n", ldR8n, 4, multiplier: 8);
    unPrefixedOpcodes.add(0x07, "RLCA", rlca, 4);
    unPrefixedOpcodes.add(0x0F, "RRCA", rrca, 4);

    unPrefixedOpcodes.add(0x10, "DJNZ nn", djnz, 4);
    unPrefixedOpcodes.add(0x18, "JR nn", jr, 4);

    unPrefixedOpcodes.addFlags(0x20, "JR CC, nn", jrcc, 4,
        multiplier: 8, count: 4);

    unPrefixedOpcodes.add(0x17, "RLA", rla, 4);
    unPrefixedOpcodes.add(0x1F, "RRA", rra, 4);
    unPrefixedOpcodes.add(0x2F, "CPL", cpl, 4);
    unPrefixedOpcodes.add(0x37, "SCF", scf, 4);
    unPrefixedOpcodes.add(0x3F, "CCF", ccf, 4);
    unPrefixedOpcodes.addR16(0x09, "ADD HL, [r16]", addHLR16, 4,
        multiplier: 16);
    unPrefixedOpcodes.add(0x0A, "LD A, (BC)", ldAmBC, 4);
    unPrefixedOpcodes.add(0x1A, "LD A, (DE)", ldAmDE, 4);
    unPrefixedOpcodes.addR16(0x0B, "DEC [r16]", decR16, 4, multiplier: 16);
    unPrefixedOpcodes.add(0x12, "LD (DE), A", ldmDEA, 4);
    unPrefixedOpcodes.add(0x22, "LD (nn), HL", ldmnnHL, 4);
    unPrefixedOpcodes.add(0x2A, "LD HL, (nn)", ldHLmnn, 4);
    unPrefixedOpcodes.add(0x32, "LD (nn), A", ldmnnA, 4);
    unPrefixedOpcodes.add(0x3A, "LD A, (nn)", ldAmnn, 4);
    unPrefixedOpcodes.add(0x36, "LD (HL), nn", ldmHLnn, 4);
    unPrefixedOpcodes.addR8R8(0x40, "LD [rDest], [rSource]", ldR8R8, 4);
    unPrefixedOpcodes.addR8(0x70, "LD (HL), [r8]", ldmHLR8, 4);
    unPrefixedOpcodes.add(0x08, "EX AF, AF'", exAFAFq, 4);
    unPrefixedOpcodes.addR8(0x80, "ADD A, [r8]", addAR8, 4);
    unPrefixedOpcodes.addR8(0x88, "ADC A, [r8]", adcAR8, 4);
    unPrefixedOpcodes.addR8(0x90, "SUB [r8]", subAR8, 4);
    unPrefixedOpcodes.addR8(0x98, "SBC [r8]", sbcAR8, 4);
    unPrefixedOpcodes.addR8(0xA0, "AND [r8]", andAR8, 4);
    unPrefixedOpcodes.addR8(0xA8, "XOR [r8]", xorAR8, 4);
    unPrefixedOpcodes.addR8(0xB0, "OR [r8]", orAR8, 4);
    unPrefixedOpcodes.addR8(0xB8, "CP [r8]", cpAR8, 4);

    unPrefixedOpcodes.addR16(0xC1, "POP [r16]", popR16, 4, multiplier: 16);
    unPrefixedOpcodes.addR16(0xC5, "PUSH [r16]", pushR16, 4, multiplier: 16);

    unPrefixedOpcodes.addR8(0xC7, "RST", rstNN, 4, multiplier: 8);

    unPrefixedOpcodes.add(0xCD, "CALL nn", callnn, 4);
    unPrefixedOpcodes.add(0xC9, "RET", ret, 4);
    unPrefixedOpcodes.add(0xC3, "JP", jp, 4);

    unPrefixedOpcodes.addFlags(0xC4, "CALL [flag], nn", callccnn, 4,
        multiplier: 8);
    unPrefixedOpcodes.addFlags(0xC0, "RET [flag]", retcc, 4, multiplier: 8);
    unPrefixedOpcodes.addFlags(0xC2, "JP [flag], nn", jpccnn, 4, multiplier: 8);

    unPrefixedOpcodes.add(0xD3, "OUT (N), A", outnA, 4);
    unPrefixedOpcodes.add(0xDB, "IN A, (N)", inAn, 4);

    unPrefixedOpcodes.add(0xD9, "EXX", exx, 4);
    unPrefixedOpcodes.add(0xE3, "EX (SP), HL", exSPHL, 4);

    unPrefixedOpcodes.add(0xE9, "JP (HL)", jpmHL, 4);
    unPrefixedOpcodes.add(0xEB, "EX DE, HL", exDEHL, 4);
    unPrefixedOpcodes.add(0xF9, "LD SP, HL", ldSPHL, 4);

    unPrefixedOpcodes.add(0xC6, "ADD A, N", addAn, 4);
    unPrefixedOpcodes.add(0xCE, "ADC A, N", adcAn, 4);
    unPrefixedOpcodes.add(0xD6, "SUB N", subAn, 4);
    unPrefixedOpcodes.add(0xDE, "SBC A, N", sbcAn, 4);
    unPrefixedOpcodes.add(0xE6, "AND A, N", andAn, 4);
    unPrefixedOpcodes.add(0xEE, "XOR N", xorAn, 4);
    unPrefixedOpcodes.add(0xF6, "OR N", orAn, 4);
    unPrefixedOpcodes.add(0xFE, "CP N", cpAn, 4);
  }

  void buildExtendedOpcodes() {
    extendedOpcodes = Z80Instructions();
    extendedOpcodes.addR8(0x40, "IN [r8], C", inR8C, 12, multiplier: 8);
    extendedOpcodes.addR8(0x41, "OUT C, [r8]", outCR8, 12, multiplier: 8);
    extendedOpcodes.addR16(0x42, "SBC HL, [r16]", sbcHLR16, 15, multiplier: 16);
    extendedOpcodes.addR16(0x4A, "ADC HL, [r16]", adcHLR16, 15, multiplier: 16);
    extendedOpcodes.addR16(0x43, "LD (NN), [r16]", ldmnnR16, 20,
        multiplier: 16);
    extendedOpcodes.addR16(0x4B, "LD [r16], (nn)", ldR16mnn, 20,
        multiplier: 16);
    extendedOpcodes.addMultiple(0x44, 4, "NEG", neg, 8, multiplier: 16);
    extendedOpcodes.addMultiple(0x4C, 4, "NEG", neg, 8, multiplier: 16);
  }

  void buildIXYOpcodes() {
    iXYOpcodes = Z80Instructions();

    iXYOpcodes.add(0x09, "ADD IXY, BC", addIXYR16, 15);
    iXYOpcodes.add(0x19, "ADD IXY, DE", addIXYR16, 15);
    iXYOpcodes.add(0x39, "ADD IXY, SP", addIXYR16, 15);
    iXYOpcodes.add(0x29, "ADD IXY, IXY", addIXYIXY, 15);

    iXYOpcodes.add(0x34, "INC (IXY + d)", incmIXY, 23);
    iXYOpcodes.add(0x35, "DEC (IXY + d)", decmIXY, 23);

    iXYOpcodes.add(0x21, "LD IXY, nn", ldIXYnn, 23);
    iXYOpcodes.add(0x22, "LD (nn), IXY", ldmnnIXY, 23);
    iXYOpcodes.add(0x2A, "LD IXY, (nn)", ldIXYmnn, 23);
    iXYOpcodes.add(0x23, "INC IXY", incIXY, 23);
    iXYOpcodes.add(0x2B, "DEC IXY", decIXY, 23);
    iXYOpcodes.add(0x36, "LD (IXY + d), n", ldmIXYdn, 23);

    iXYOpcodes.addR8(0x46, "LD [r8], (IXY + d)", ldR8mIXYd, 19, multiplier: 8);
    iXYOpcodes.addR8(0x70, "LD (IXY + d), [r8]", ldmIXYdR8, 19);

    iXYOpcodes.add(0x36, "LD (IXY + d), n", ldmIXYdn, 23);

    iXYOpcodes.add(0x86, "ADD A, (IXY + d)", addAIXYd, 19);
    iXYOpcodes.add(0x8E, "ADC A, (IXY + d)", adcAIXYd, 19);
    iXYOpcodes.add(0x96, "SUB (IXY + d)", subAIXYd, 19);
    iXYOpcodes.add(0x9E, "SBC A, (IXY + d)", sbcAIXYd, 19);
    iXYOpcodes.add(0xA6, "AND (IXY + d)", andAIXYd, 19);
    iXYOpcodes.add(0xAE, "XOR (IXY + d)", xorAIXYd, 19);
    iXYOpcodes.add(0xB6, "OR (IXY + d)", orAIXYd, 19);
    iXYOpcodes.add(0xBE, "CP (IXY + d)", cpAIXYd, 19);

    iXYOpcodes.add(0xE1, "POP IXY", popIXY, 19);
    iXYOpcodes.add(0xE5, "PUSH IXY", pushIXY, 19);
    iXYOpcodes.add(0xE9, "JP (IXY)", jpmIXY, 19);
    iXYOpcodes.add(0xE3, "EX (SP)", exmSPIXY, 19);
    iXYOpcodes.add(0xF9, "LD SP, IXY", ldSPIXY, 19);
  }

  void buildBitOpcodes() {
    bitOpcodes = Z80Instructions();

    bitOpcodes.addR8(0x00, "RLC [r8]", rlcR8, 8);
    bitOpcodes.addR8(0x08, "RRC [r8]", rrcR8, 8);
    bitOpcodes.addR8(0x10, "RL [r8]", rlR8, 8);
    bitOpcodes.addR8(0x18, "RR [r8]", rrR8, 8);
    bitOpcodes.addR8(0x20, "SLA [r8]", slaR8, 8);
    bitOpcodes.addR8(0x28, "SRA [r8]", sraR8, 8);
    bitOpcodes.addR8(0x38, "SRL [r8]", srlR8, 8);

    bitOpcodes.addBit8R8(0x40, "BIT [bit], [r8]", bitnR8, 8);
    bitOpcodes.addBit8R8(0x80, "RES [bit], [r8]", resnR8, 8);
    bitOpcodes.addBit8R8(0xC0, "SET [bit], [r8]", setnR8, 8);
  }

  void buildIXYBitOpcodes() {
    iXYbitOpcodes = Z80Instructions();

    iXYbitOpcodes.add(0x06, "RLC (IXY + d)", rlcMIXYd, 23);
    iXYbitOpcodes.add(0x0E, "RRC (IXY + d)", rrcMIXYd, 23);
    iXYbitOpcodes.add(0x16, "RL (IXY + d)", rlMIXYd, 23);
    iXYbitOpcodes.add(0x1E, "RR (IXY + d)", rrMIXYd, 23);
    iXYbitOpcodes.add(0x26, "SLA (IXY + d)", slaMIXYd, 23);
    iXYbitOpcodes.add(0x2E, "SRA (IXY + d)", sraMIXYd, 23);
    iXYbitOpcodes.add(0x3E, "SRL (IXY + d)", srlMIXYd, 23);

    iXYbitOpcodes.addBit8(0x46, "BIT [bit], (IXY + d)", bitnMIXYd, 20,
        multiplier: 8);
    iXYbitOpcodes.addBit8(0x86, "RES [bit], (IXY + d)", resnMIXYd, 20,
        multiplier: 8);
    iXYbitOpcodes.addBit8(0xC6, "RES [bit], (IXY + d)", setnMIXYd, 20,
        multiplier: 8);
  }
}
