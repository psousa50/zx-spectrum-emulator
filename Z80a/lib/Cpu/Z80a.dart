library z80a;

import 'package:Z80a/Cpu/Z80Instructions.dart';
import 'package:Z80a/Memory.dart';
import 'package:Z80a/Ports.dart';
import 'package:Z80a/Cpu/Registers.dart';
import 'package:Z80a/Util.dart';

import 'InstructionContext.dart';
import 'Z80Instruction.dart';

// ignore_for_file: non_constant_identifier_names

enum InterruptMode {
  im0,
  im1,
  im2,
}

class Z80a {
  final Memory memory;
  final Ports ports;

  InterruptMode _interruptMode;
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

  Z80a(this.memory, this.ports) {
    buildUnprefixedOpcodes();
    buildExtendedOpcodes();
    buildBitOpcodes();
    buildIXYOpcodes();
    buildIXYBitOpcodes();
  }

  InterruptMode get interruptMode => _interruptMode;

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

    if (halted) return 0;

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

  Z80Instruction getInstruction() {
    Z80Instruction i;

    var d0 = this.memory.peek(this.PC + 0);
    var d1 = this.memory.peek(this.PC + 1);
    var d3 = this.memory.peek(this.PC + 3);
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
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = (w1 & 0x0FFF) + (w2 & 0x0FFF) > 0x0FFF;
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
    registers.halfCarryFlag = 1 + (value & 0x0F) > 0x0F;
    var newValue = byte(value + 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    registers.addSubtractFlag = false;

    return newValue;
  }

  int decR8Value(int value) {
    registers.parityOverflowFlag = value == 0x80;
    registers.halfCarryFlag = (value & 0x0F) - 1 < 0;
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
    registers.halfCarryFlag = true;
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

  int nop(InstructionContext context) {
    return context.instruction.tStates();
  }

  int daa(InstructionContext context) {
    var sign = registers.addSubtractFlag ? -1 : 1;
    if (registers.halfCarryFlag || (registers.A & 0x0F > 0x09))
      registers.A = addA(0x06 * sign);
    if (registers.carryFlag || (registers.A & 0xF0 > 0x90))
      registers.A = addA(0x60 * sign);

    return context.instruction.tStates();
  }

  int rlca(InstructionContext context) {
    registers.A = rlcOp(registers.A);
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
    registers.A = rrcOp(registers.A);
    return context.instruction.tStates();
  }

  int rla(InstructionContext context) {
    registers.A = rlOp(registers.A);
    return context.instruction.tStates();
  }

  int rra(InstructionContext context) {
    registers.A = rrOp(registers.A);
    return context.instruction.tStates();
  }

  int cpl(InstructionContext context) {
    registers.A = registers.A ^ 255;
    this.registers.addSubtractFlag = true;
    this.registers.halfCarryFlag = true;
    return context.instruction.tStates();
  }

  int scf(InstructionContext context) {
    registers.F = registers.F & ~Registers.F_ADD_SUB | Registers.F_CARRY;
    this.registers.addSubtractFlag = false;
    this.registers.halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ccf(InstructionContext context) {
    registers.F = registers.F & ~Registers.F_ADD_SUB ^ Registers.F_CARRY;
    return context.instruction.tStates();
  }

  int djnz(InstructionContext context) {
    var d = fetch();
    registers.B = byte(registers.B - 1);
    bool cond = registers.B != 0;
    if (cond) {
      this.PC = this.PC + signedByte(d);
    }
    return context.instruction.tStates(cond: cond);
  }

  int jr(InstructionContext context) {
    var d = fetch();
    this.PC = this.PC + signedByte(d);
    return context.instruction.tStates();
  }

  int jrcc(InstructionContext context) {
    var d = fetch();
    var cond = getFlagCondition(bit345(context.opcode) - 4);
    if (cond) {
      this.PC = this.PC + signedByte(d);
    }
    return context.instruction.tStates(cond: cond);
  }

  int ldmBCA(InstructionContext context) {
    this.memory.poke(registers.BC, registers.A);
    return context.instruction.tStates();
  }

  int ldAmBC(InstructionContext context) {
    registers.A = this.memory.peek(registers.BC);
    return context.instruction.tStates();
  }

  int ldAmDE(InstructionContext context) {
    registers.A = this.memory.peek(registers.DE);
    return context.instruction.tStates();
  }

  int ldmDEA(InstructionContext context) {
    this.memory.poke(registers.DE, registers.A);
    return context.instruction.tStates();
  }

  int exAFAFq(InstructionContext context) {
    final af = registers.AF;
    registers.AF = registers.AFt;
    registers.AFt = af;
    return context.instruction.tStates();
  }

  int incR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, incR8Value(this.r8Value(r8)));
    return context.instruction.tStates();
  }

  int incmIXY(InstructionContext context) {
    var d = fetch();
    this.memory.poke(getIXY(context.prefix) + d,
        incR8Value(this.memory.peek(getIXY(context.prefix) + d)));
    return context.instruction.tStates();
  }

  int decmIXY(InstructionContext context) {
    var d = fetch();
    this.memory.poke(getIXY(context.prefix) + d,
        decR8Value(this.memory.peek(getIXY(context.prefix) + d)));
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
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, decR8Value(this.r8Value(r8)));
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
    registers.HL = addWord(registers.HL, r16Value(r16));
    return context.instruction.tStates();
  }

  int ldR8n(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, fetch());
    return context.instruction.tStates();
  }

  int ldR8mHL(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    setR8Value(r8, this.memory.peek(registers.HL));
    return context.instruction.tStates();
  }

  int ldmnnHL(InstructionContext context) {
    this.memory.poke2(fetch2(), registers.HL);
    return context.instruction.tStates();
  }

  int ldHLmnn(InstructionContext context) {
    registers.HL = this.memory.peek2(fetch2());
    return context.instruction.tStates();
  }

  int ldmnnA(InstructionContext context) {
    this.memory.poke(fetch2(), registers.A);
    return context.instruction.tStates();
  }

  int ldAmnn(InstructionContext context) {
    registers.A = this.memory.peek(fetch2());
    return context.instruction.tStates();
  }

  int ldmHLnn(InstructionContext context) {
    this.memory.poke(registers.HL, fetch());
    return context.instruction.tStates();
  }

  int addAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = addA(r8Value(r8));
    return context.instruction.tStates();
  }

  int adcAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = adcA(r8Value(r8));
    return context.instruction.tStates();
  }

  int subAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = subA(r8Value(r8));
    return context.instruction.tStates();
  }

  int sbcAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = sbcA(r8Value(r8));
    return context.instruction.tStates();
  }

  int andAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = andA(r8Value(r8));
    return context.instruction.tStates();
  }

  int xorAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = xorA(r8Value(r8));
    return context.instruction.tStates();
  }

  int orAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    registers.A = orA(r8Value(r8));
    return context.instruction.tStates();
  }

  int cpAR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    subA(r8Value(r8));
    return context.instruction.tStates();
  }

  int addAn(InstructionContext context) {
    registers.A = addA(fetch());
    return context.instruction.tStates();
  }

  int adcAn(InstructionContext context) {
    registers.A = adcA(fetch());
    return context.instruction.tStates();
  }

  int subAn(InstructionContext context) {
    registers.A = subA(fetch());
    return context.instruction.tStates();
  }

  int sbcAn(InstructionContext context) {
    registers.A = sbcA(fetch());
    return context.instruction.tStates();
  }

  int andAn(InstructionContext context) {
    registers.A = andA(fetch());
    return context.instruction.tStates();
  }

  int xorAn(InstructionContext context) {
    registers.A = xorA(fetch());
    return context.instruction.tStates();
  }

  int orAn(InstructionContext context) {
    registers.A = orA(fetch());
    return context.instruction.tStates();
  }

  int cpAn(InstructionContext context) {
    cpA(fetch());
    return context.instruction.tStates();
  }

  int ldR8R8(InstructionContext context) {
    int r8Dest = Registers.rBit345(context.opcode);
    int r8Source = Registers.rBit012(context.opcode);
    this.setR8Value(r8Dest, r8Value(r8Source));
    return context.instruction.tStates();
  }

  int ldR16nn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    setR16Value(r16, fetch2());
    return context.instruction.tStates();
  }

  int inR8C(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    var result = this.ports.inPort(registers.BC);
    setR8Value(r8, result);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int outCR8(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    this.ports.outPort(registers.C, r8Value(r8));
    return context.instruction.tStates();
  }

  int sbcHLR16(InstructionContext context) {
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
    return context.instruction.tStates();
  }

  int adcHLR16(InstructionContext context) {
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
    return context.instruction.tStates();
  }

  int ldmnnR16(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    this.memory.poke2(fetch2(), r16Value(r16));
    return context.instruction.tStates();
  }

  int ldR16mnn(InstructionContext context) {
    int r16 = Registers.rBit45(context.opcode);
    var a = fetch2();
    setR16Value(r16, this.memory.peek2(a));
    return context.instruction.tStates();
  }

  int neg(InstructionContext context) {
    registers.carryFlag = registers.A != 0;
    registers.parityOverflowFlag = registers.A == 0x80;
    registers.halfCarryFlag = registers.A != 0;
    registers.addSubtractFlag = true;
    var result = byte(0 - registers.A);
    registers.A = result;
    setZeroAndSignFlagsOn8BitResult(result);
    return context.instruction.tStates();
  }

  int callnn(InstructionContext context) {
    var address = fetch2();
    push2(PC);
    this.PC = address;
    return context.instruction.tStates();
  }

  int ret(InstructionContext context) {
    this.PC = pop2();
    return context.instruction.tStates();
  }

  int retn(InstructionContext context) => ret(context);
  int reti(InstructionContext context) => ret(context);

  int jp(InstructionContext context) {
    this.PC = fetch2();
    return context.instruction.tStates();
  }

  int callccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    var address = fetch2();
    if (cond) {
      push2(PC);
      this.PC = address;
    }
    return context.instruction.tStates(cond: cond);
  }

  int retcc(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    if (cond) {
      this.PC = pop2();
    }
    return context.instruction.tStates(cond: cond);
  }

  int jpccnn(InstructionContext context) {
    var cond = getFlagCondition(bit345(context.opcode));
    if (cond) {
      this.PC = fetch2();
    }
    return context.instruction.tStates(cond: cond);
  }

  int outnA(InstructionContext context) {
    this.ports.outPort(fetch(), registers.A);
    return context.instruction.tStates();
  }

  int inAn(InstructionContext context) {
    registers.A = this.ports.inPort(fetch());
    return context.instruction.tStates();
  }

  int exx(InstructionContext context) {
    var bc = registers.BC;
    var de = registers.DE;
    var hl = registers.HL;
    registers.BC = registers.BCt;
    registers.DE = registers.DEt;
    registers.HL = registers.HLt;
    registers.BCt = bc;
    registers.DEt = de;
    registers.HLt = hl;
    return context.instruction.tStates();
  }

  int exSPHL(InstructionContext context) {
    var msp = this.memory.peek2(registers.SP);
    this.memory.poke2(registers.SP, registers.HL);
    registers.HL = msp;
    return context.instruction.tStates();
  }

  int jpmHL(InstructionContext context) {
    this.PC = registers.HL;
    return context.instruction.tStates();
  }

  int exDEHL(InstructionContext context) {
    var de = registers.DE;
    registers.DE = registers.HL;
    registers.HL = de;
    return context.instruction.tStates();
  }

  int ldSPHL(InstructionContext context) {
    registers.SP = registers.HL;
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
    push2(this.PC);
    this.PC = rst;
    return context.instruction.tStates();
  }

  int ldIXYnn(InstructionContext context) {
    setIXY(context.prefix, fetch2());
    return context.instruction.tStates();
  }

  int ldmnnIXY(InstructionContext context) {
    this.memory.poke2(fetch2(), getIXY(context.prefix));
    return context.instruction.tStates();
  }

  int ldIXYmnn(InstructionContext context) {
    setIXY(context.prefix, this.memory.peek2(fetch2()));
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
    this.memory.poke(getIXY(context.prefix) + d, value);
    return context.instruction.tStates();
  }

  int ldR8mIXYd(InstructionContext context) {
    int r8 = Registers.rBit345(context.opcode);
    int d = fetch();
    setR8Value(r8, this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int ldmIXYdR8(InstructionContext context) {
    int r8 = Registers.rBit012(context.opcode);
    int d = fetch();
    this.memory.poke(getIXY(context.prefix) + d, r8Value(r8));
    return context.instruction.tStates();
  }

  int addAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = addA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int adcAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = adcA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int subAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = subA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int sbcAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = sbcA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int andAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = andA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int xorAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = xorA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int orAIXYd(InstructionContext context) {
    var d = fetch();
    registers.A = orA(this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int cpAIXYd(InstructionContext context) {
    var d = fetch();
    cpA(this.memory.peek(getIXY(context.prefix) + d));
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
    this.PC = getIXY(context.prefix);
    return context.instruction.tStates();
  }

  int exmSPIXY(InstructionContext context) {
    var msp = this.memory.peek2(registers.SP);
    this.memory.poke2(registers.SP, getIXY(context.prefix));
    setIXY(context.prefix, msp);
    return context.instruction.tStates();
  }

  int ldSPIXY(InstructionContext context) {
    registers.SP = getIXY(context.prefix);
    return context.instruction.tStates();
  }

  int rlcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rlc(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int rrcMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rrc(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int rlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rl(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int rrMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, rr(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int slaMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, sla(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int sraMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, sra(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int srlMIXYd(InstructionContext context) {
    var d = context.displacement;
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, srl(this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int bitnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    bitNR8Op(bit, this.memory.peek(getIXY(context.prefix) + d));
    return context.instruction.tStates();
  }

  int resnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, resNR8Op(bit, this.memory.peek(address)));
    return context.instruction.tStates();
  }

  int setnMIXYd(InstructionContext context) {
    var d = context.displacement;
    var bit = bit345(context.opcode);
    var address = getIXY(context.prefix) + d;
    this.memory.poke(address, setNR8Op(bit, this.memory.peek(address)));
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
    this._interruptMode = InterruptMode.im0;
    return context.instruction.tStates();
  }

  int im1(InstructionContext context) {
    this._interruptMode = InterruptMode.im1;
    return context.instruction.tStates();
  }

  int im2(InstructionContext context) {
    this._interruptMode = InterruptMode.im2;
    return context.instruction.tStates();
  }

  int di(InstructionContext context) {
    this.interruptsEnabled = false;
    return context.instruction.tStates();
  }

  int ei(InstructionContext context) {
    this.interruptsEnabled = true;
    return context.instruction.tStates();
  }

  int halt(InstructionContext context) {
    this.halted = true;
    return context.instruction.tStates();
  }

  int ldAI(InstructionContext context) {
    this.registers.A = this.registers.I;
    setZeroAndSignFlagsOn8BitResult(this.registers.A);
    this.registers.addSubtractFlag = false;
    this.registers.halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ldIA(InstructionContext context) {
    this.registers.I = this.registers.A;
    return context.instruction.tStates();
  }

  int ldAR(InstructionContext context) {
    this.registers.A = this.registers.R;
    setZeroAndSignFlagsOn8BitResult(this.registers.A);
    this.registers.addSubtractFlag = false;
    this.registers.halfCarryFlag = false;
    return context.instruction.tStates();
  }

  int ldRA(InstructionContext context) {
    this.registers.R = this.registers.A;
    return context.instruction.tStates();
  }

  int ldi(InstructionContext context) {
    this.memory.poke(this.registers.DE, this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL + 1;
    this.registers.DE = this.registers.DE + 1;
    this.registers.BC = this.registers.BC - 1;
    this.registers.halfCarryFlag = false;
    this.registers.addSubtractFlag = false;
    this.registers.parityOverflowFlag = this.registers.BC != 0;
    return context.instruction.tStates();
  }

  int ldd(InstructionContext context) {
    this.memory.poke(this.registers.DE, this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL - 1;
    this.registers.DE = this.registers.DE - 1;
    this.registers.BC = this.registers.BC - 1;
    this.registers.halfCarryFlag = false;
    this.registers.addSubtractFlag = false;
    this.registers.parityOverflowFlag = this.registers.BC != 0;
    return context.instruction.tStates();
  }

  int cpi(InstructionContext context) {
    subA(this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL + 1;
    this.registers.BC = this.registers.BC - 1;
    this.registers.addSubtractFlag = false;
    this.registers.parityOverflowFlag = this.registers.BC != 0;
    return context.instruction.tStates();
  }

  int cpd(InstructionContext context) {
    subA(this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL - 1;
    this.registers.BC = this.registers.BC - 1;
    this.registers.addSubtractFlag = false;
    this.registers.parityOverflowFlag = this.registers.BC != 0;
    return context.instruction.tStates();
  }

  int ini(InstructionContext context) {
    this.memory.poke(this.registers.HL, this.ports.inPort(registers.C));
    this.registers.HL = this.registers.HL + 1;
    this.registers.B = this.registers.B - 1;
    this.registers.addSubtractFlag = true;
    this.registers.zeroFlag = this.registers.B == 0;
    return context.instruction.tStates();
  }

  int ind(InstructionContext context) {
    this.memory.poke(this.registers.HL, this.ports.inPort(registers.C));
    this.registers.HL = this.registers.HL - 1;
    this.registers.B = this.registers.B - 1;
    this.registers.addSubtractFlag = true;
    this.registers.zeroFlag = this.registers.B == 0;
    return context.instruction.tStates();
  }

  int outi(InstructionContext context) {
    this.ports.outPort(registers.C, this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL + 1;
    this.registers.B = this.registers.B - 1;
    this.registers.addSubtractFlag = true;
    this.registers.zeroFlag = this.registers.B == 0;
    return context.instruction.tStates();
  }

  int outd(InstructionContext context) {
    this.ports.outPort(registers.C, this.memory.peek(this.registers.HL));
    this.registers.HL = this.registers.HL - 1;
    this.registers.B = this.registers.B - 1;
    this.registers.addSubtractFlag = true;
    this.registers.zeroFlag = this.registers.B == 0;
    return context.instruction.tStates();
  }

  int ldir(InstructionContext context) {
    ldi(context);
    var cond = this.registers.BC == 0;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int lddr(InstructionContext context) {
    ldd(context);
    var cond = this.registers.BC == 0;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int cpir(InstructionContext context) {
    cpi(context);
    var cond = this.registers.BC == 0 || this.registers.zeroFlag;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int cpdr(InstructionContext context) {
    cpd(context);
    var cond = this.registers.BC == 0 || this.registers.zeroFlag;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int inir(InstructionContext context) {
    ini(context);
    this.registers.zeroFlag = true;
    var cond = this.registers.B == 0;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int indr(InstructionContext context) {
    ind(context);
    this.registers.zeroFlag = true;
    var cond = this.registers.B == 0;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int otir(InstructionContext context) {
    outi(context);
    this.registers.zeroFlag = true;
    var cond = this.registers.B == 0;
    if (!cond) this.PC = this.PC - 2;
    return context.instruction.tStates(cond: cond);
  }

  int otdr(InstructionContext context) {
    outd(context);
    this.registers.zeroFlag = true;
    var cond = this.registers.B == 0;
    if (!cond) this.PC = this.PC - 2;
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
    unPrefixed.buildM16C4(0xC1, "POP [r16]", popR16, 10);
    unPrefixed.buildM8C8(0xC2, "JP [cc], nn", jpccnn, 10,
        tStatesOnTrueCond: 10);
    unPrefixed.build(0xC3, "JP", jp, 10);
    unPrefixed.buildM8C8(0xC4, "CALL [cc], nn", callccnn, 10,
        tStatesOnTrueCond: 17);
    unPrefixed.buildM16C4(0xC5, "PUSH [r16]", pushR16, 11);
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
    extendedOpcodes.buildM8C8(0x40, "IN [rb345], C", inR8C, 12);
    extendedOpcodes.buildM8C8(0x41, "OUT C, [rb345]", outCR8, 12);
    extendedOpcodes.buildM16C4(0x42, "SBC HL, [r16]", sbcHLR16, 15);
    extendedOpcodes.buildM16C4(0x43, "LD (nn), [r16]", ldmnnR16, 20);
    extendedOpcodes.buildM16C4(0x44, "NEG", neg, 8);
    extendedOpcodes.buildM16C4(0x45, "RETN", retn, 14);
    extendedOpcodes.buildM16C4(0x4A, "ADC HL, [r16]", adcHLR16, 15);
    extendedOpcodes.buildM16C4(0x4B, "LD [r16], (nn)", ldR16mnn, 20);
    extendedOpcodes.buildM16C4(0x4C, "NEG", neg, 8);
    extendedOpcodes.buildM16C4(0x4D, "RETI", reti, 14);

    extendedOpcodes.buildM16C4(0x46, "IM 0", im0, 8);
    extendedOpcodes.buildM16C4(0x47, "LD I, A", ldIA, 9);
    extendedOpcodes.buildM16C4(0x4F, "LD R, A", ldRA, 9);
    extendedOpcodes.buildM16C4(0x66, "IM 0", im0, 8);

    extendedOpcodes.buildM16C4(0x56, "IM 1", im1, 8);
    extendedOpcodes.buildM16C4(0x57, "LD A, I", ldAI, 9);
    extendedOpcodes.buildM16C4(0x5F, "LD A, R", ldAR, 9);
    extendedOpcodes.buildM16C4(0x66, "IM 1", im1, 8);

    extendedOpcodes.buildM16C4(0x5E, "IM 1", im2, 8);
    extendedOpcodes.buildM16C4(0x6E, "IM 1", im2, 8);

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

    iXYOpcodes.build(0x86, "ADD A, (IXY + d)", addAIXYd, 19);
    iXYOpcodes.build(0x8E, "ADC A, (IXY + d)", adcAIXYd, 19);
    iXYOpcodes.build(0x96, "SUB (IXY + d)", subAIXYd, 19);
    iXYOpcodes.build(0x9E, "SBC A, (IXY + d)", sbcAIXYd, 19);
    iXYOpcodes.build(0xA6, "AND (IXY + d)", andAIXYd, 19);
    iXYOpcodes.build(0xAE, "XOR (IXY + d)", xorAIXYd, 19);
    iXYOpcodes.build(0xB6, "OR (IXY + d)", orAIXYd, 19);
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
    iXYbitOpcodes.buildM8C8(0xC6, "RES [bit], (IXY + d)", setnMIXYd, 20);
  }

  void maskableInterrupt() {
    if (!interruptsEnabled) return;

    switch (interruptMode) {
      case InterruptMode.im1:
        interruptsEnabled = false;
        push2(this.PC);
        this.PC = 0x38;
        break;

      case InterruptMode.im2:
        interruptsEnabled = false;
        push2(this.PC);
        this.PC = this.memory.peek2(this.registers.I * 256 + 254);
        break;

      default:
        break;
    }
  }
}
