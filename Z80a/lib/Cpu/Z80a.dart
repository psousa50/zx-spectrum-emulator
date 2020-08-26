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

  static List<int> bitMask = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80];

  static const IX_PREFIX = 0xDD;
  static const IY_PREFIX = 0xFD;

  static const BIT_OPCODES = 0xCB;
  static const EXTENDED_OPCODES = 0xED;

  int getIXY(int prefix) => prefix == IX_PREFIX ? registers.IX : registers.IY;

  void setIXY(int prefix, int w) =>
      prefix == IX_PREFIX ? registers.IX = w : registers.IY = w;

  Z80a(this.memory, this.ports) {
    buildUnprefixedOpcodes();
    buildExtendedOpcodes();
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

  int byte(int v) => v % 256;

  int word(int v) => v % 65536;

  int getReg(int r) =>
      r == Registers.R_MHL ? this.memory.peek(registers.HL) : registers[r];

  int getReg2(int r) => 256 * registers[r] + registers[r + 1];

  void setReg(int r, int b) => r == Registers.R_MHL
      ? this.memory.poke(registers.HL, byte(b))
      : registers[r] = byte(b);

  void setReg2(int r, int w) {
    registers[r] = hi(w);
    registers[r + 1] = lo(w);
  }

  int addW(int w1, int w2) {
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

  int step() {
    var tStates = 0;

    final opcode = fetch();

    switch (opcode) {
      case IX_PREFIX:
      case IY_PREFIX:
        processIXYOpcodes(opcode);
        tStates = 1;
        break;

      case EXTENDED_OPCODES:
        tStates = processOpcode(fetch(), extendedOpcodes);
        break;

      case BIT_OPCODES:
        processBitOpcodes();
        tStates = 1;
        break;

      default:
        tStates = processOpcode(opcode, unPrefixedOpcodes);
        break;
    }

    return tStates;
  }

  bool processIXYOpcodes(int prefix) {
    var processed = true;

    final opcode = fetch();

    switch (opcode) {
      case BIT_OPCODES:
        processIXYBitOpcodes(prefix);
        break;

      case 0x34: // INC (IXY+d)
        var d = fetch();
        this.memory.poke(getIXY(prefix) + d,
            incR8Value(this.memory.peek(getIXY(prefix) + d)));
        break;

      case 0x35: // DEC (IXY+d)
        var d = fetch();
        this.memory.poke(getIXY(prefix) + d,
            decR8Value(this.memory.peek(getIXY(prefix) + d)));
        break;

      case 0x09: // ADD IXY, BC
      case 0x19: // ADD IXY, DE
      case 0x39: // ADD IXY, SP
        int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
        setIXY(prefix, addW(getIXY(prefix), getReg2(r16)));
        break;

      case 0x29: // ADD IXY, IX
        setIXY(prefix, addW(getIXY(prefix), getIXY(prefix)));
        break;

      case 0x21: // LD IXY, NN
        setIXY(prefix, fetch2());
        break;

      case 0x22: // LD (NN), IXY
        this.memory.poke2(fetch2(), getIXY(prefix));
        break;

      case 0x2A: // LD IXY, (NN)
        setIXY(prefix, this.memory.peek2(fetch2()));
        break;

      case 0x23: // INC IXY
        setIXY(prefix, word(getIXY(prefix) + 1));
        break;

      case 0x2B: // DEC IXY
        setIXY(prefix, word(getIXY(prefix) - 1));
        break;

      case 0x36: // LD (IXY + d), N
        var d = fetch();
        var value = fetch();
        this.memory.poke(getIXY(prefix) + d, value);
        break;

      case 0x46: // LD B, (IXY + d)
      case 0x4E: // LD C, (IXY + d)
      case 0x56: // LD D, (IXY + d)
      case 0x5E: // LD E, (IXY + d)
      case 0x66: // LD H, (IXY + d)
      case 0x6E: // LD L, (IXY + d)
        int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
        int d = fetch();
        setReg(r8, this.memory.peek(getIXY(prefix) + d));
        break;

      case 0x70: // LD B, (IXY + d)
      case 0x71: // LD C, (IXY + d)
      case 0x72: // LD D, (IXY + d)
      case 0x73: // LD E, (IXY + d)
      case 0x74: // LD H, (IXY + d)
      case 0x75: // LD L, (IXY + d)
      case 0x77: // LD A, (IXY + d)
        int r8 = Registers.r8Table[opcode & 0x07];
        int d = fetch();
        this.memory.poke(getIXY(prefix) + d, getReg(r8));
        break;

      case 0x86: // ADD A, (IXY + d)
        var d = fetch();
        registers.A = addA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0x8E: // ADC A, (IXY + d)
        var d = fetch();
        registers.A = adcA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0x96: // SUB (IXY + d)
        var d = fetch();
        registers.A = subA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0x9E: // SBC A, (IXY + d)
        var d = fetch();
        registers.A = sbcA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0xA6: // AND (IXY + d)
        var d = fetch();
        registers.A = andA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0xAE: // XOR (IXY + d)
        var d = fetch();
        registers.A = xorA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0xB6: // OR (IXY + d)
        var d = fetch();
        registers.A = orA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0xBE: // CP (IXY + d)
        var d = fetch();
        cpA(this.memory.peek(getIXY(prefix) + d));
        break;

      case 0xE1: // POP IXY
        setIXY(prefix, pop2());
        break;

      case 0xE5: // PUSH IXY
        push2(getIXY(prefix));
        break;

      case 0xE9: // JP (IXY)
        this.PC = this.memory.peek2(getIXY(prefix));
        break;

      case 0xE3: // EX (SP), IXY
        var msp = this.memory.peek2(registers.SP);
        this.memory.poke2(registers.SP, getIXY(prefix));
        setIXY(prefix, msp);
        break;

      case 0xF9: // LD SP, IXY
        registers.SP = getIXY(prefix);
        break;

      default:
        break;
    }

    return processed;
  }

  void bitNR8(int bit, int value) {
    var mask = bitMask[bit];
    registers.zeroFlag = value & mask == 0;
    registers.halfCarryFlag = true;
    registers.addSubtractFlag = false;
  }

  int resNR8(int bit, int value) {
    var mask = bitMask[bit];
    return value & ~mask;
  }

  int setNR8(int bit, int value) {
    var mask = bitMask[bit];
    return value | mask;
  }

  bool processBitOpcodes() {
    var processed = true;

    final opcode = fetch();

    switch (opcode) {
      case 0x00: // RLC B
      case 0x01: // RLC C
      case 0x02: // RLC D
      case 0x03: // RLC E
      case 0x04: // RLC H
      case 0x05: // RLC L
      case 0x06: // RLC (HL)
      case 0x07: // RLC A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, rlc(getReg(r8)));
        break;

      case 0x08: // RRC B
      case 0x09: // RRC C
      case 0x0A: // RRC D
      case 0x0B: // RRC E
      case 0x0C: // RRC H
      case 0x0D: // RRC L
      case 0x0E: // RRC (HL)
      case 0x0F: // RRC A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, rrc(getReg(r8)));
        break;

      case 0x10: // RL B
      case 0x11: // RL C
      case 0x12: // RL D
      case 0x13: // RL E
      case 0x14: // RL H
      case 0x15: // RL L
      case 0x16: // RL (HL)
      case 0x17: // RL A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, rl(getReg(r8)));
        break;

      case 0x18: // RR B
      case 0x19: // RR C
      case 0x1A: // RR D
      case 0x1B: // RR E
      case 0x1C: // RR H
      case 0x1D: // RR L
      case 0x1E: // RR (HL)
      case 0x1F: // RR A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, rr(getReg(r8)));
        break;

      case 0x20: // SLA B
      case 0x21: // SLA C
      case 0x22: // SLA D
      case 0x23: // SLA E
      case 0x24: // SLA H
      case 0x25: // SLA L
      case 0x26: // SLA (HL)
      case 0x27: // SLA A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, sla(getReg(r8)));
        break;

      case 0x28: // SRA B
      case 0x29: // SRA C
      case 0x2A: // SRA D
      case 0x2B: // SRA E
      case 0x2C: // SRA H
      case 0x2D: // SRA L
      case 0x2E: // SRA (HL)
      case 0x2F: // SRA A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, sra(getReg(r8)));
        break;

      case 0x38: // SRL B
      case 0x39: // SRL C
      case 0x3A: // SRL D
      case 0x3B: // SRL E
      case 0x3C: // SRL H
      case 0x3D: // SRL L
      case 0x3E: // SRA (HL)
      case 0x3F: // SRA A
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, srl(getReg(r8)));
        break;

      case 0x40: // BIT 0, B
      case 0x41: // BIT 0, C
      case 0x42: // BIT 0, D
      case 0x43: // BIT 0, E
      case 0x44: // BIT 0, H
      case 0x45: // BIT 0, L
      case 0x46: // BIT 0, (HL)
      case 0x47: // BIT 0, A

      case 0x48: // BIT 1, B
      case 0x49: // BIT 1, C
      case 0x4A: // BIT 1, D
      case 0x4B: // BIT 1, E
      case 0x4C: // BIT 1, H
      case 0x4D: // BIT 1, L
      case 0x4E: // BIT 1, (HL)
      case 0x4F: // BIT 1, A

      case 0x50: // BIT 2, B
      case 0x51: // BIT 2, C
      case 0x52: // BIT 2, D
      case 0x53: // BIT 2, E
      case 0x54: // BIT 2, H
      case 0x55: // BIT 2, L
      case 0x56: // BIT 2, (HL)
      case 0x57: // BIT 2, A

      case 0x58: // BIT 3, B
      case 0x59: // BIT 3, C
      case 0x5A: // BIT 3, D
      case 0x5B: // BIT 3, E
      case 0x5C: // BIT 3, H
      case 0x5D: // BIT 3, L
      case 0x5E: // BIT 3, (HL)
      case 0x5F: // BIT 3, A

      case 0x60: // BIT 4, B
      case 0x61: // BIT 4, C
      case 0x62: // BIT 4, D
      case 0x63: // BIT 4, E
      case 0x64: // BIT 4, H
      case 0x65: // BIT 4, L
      case 0x66: // BIT 4, (HL)
      case 0x67: // BIT 4, A

      case 0x68: // BIT 5, B
      case 0x69: // BIT 5, C
      case 0x6A: // BIT 5, D
      case 0x6B: // BIT 5, E
      case 0x6C: // BIT 5, H
      case 0x6D: // BIT 5, L
      case 0x6E: // BIT 5, (HL)
      case 0x6F: // BIT 5, A

      case 0x70: // BIT 6, B
      case 0x71: // BIT 6, C
      case 0x72: // BIT 6, D
      case 0x73: // BIT 6, E
      case 0x74: // BIT 6, H
      case 0x75: // BIT 6, L
      case 0x76: // BIT 6, (HL)
      case 0x77: // BIT 6, A

      case 0x78: // BIT 7, B
      case 0x79: // BIT 7, C
      case 0x7A: // BIT 7, D
      case 0x7B: // BIT 7, E
      case 0x7C: // BIT 7, H
      case 0x7D: // BIT 7, L
      case 0x7E: // BIT 7, (HL)
      case 0x7F: // BIT 7, A

        var bit = (opcode & 0x38) >> 3;
        int r8 = Registers.r8Table[opcode & 0x07];
        bitNR8(bit, getReg(r8));
        break;

      case 0x80: // RES 0, B
      case 0x81: // RES 0, C
      case 0x82: // RES 0, D
      case 0x83: // RES 0, E
      case 0x84: // RES 0, H
      case 0x85: // RES 0, L
      case 0x86: // RES 0, (HL)
      case 0x87: // RES 0, A

      case 0x88: // RES 1, B
      case 0x89: // RES 1, C
      case 0x8A: // RES 1, D
      case 0x8B: // RES 1, E
      case 0x8C: // RES 1, H
      case 0x8D: // RES 1, L
      case 0x8E: // RES 1, (HL)
      case 0x8F: // RES 1, A

      case 0x90: // RES 2, B
      case 0x91: // RES 2, C
      case 0x92: // RES 2, D
      case 0x93: // RES 2, E
      case 0x94: // RES 2, H
      case 0x95: // RES 2, L
      case 0x96: // RES 2, (HL)
      case 0x97: // RES 2, A

      case 0x98: // RES 3, B
      case 0x99: // RES 3, C
      case 0x9A: // RES 3, D
      case 0x9B: // RES 3, E
      case 0x9C: // RES 3, H
      case 0x9D: // RES 3, L
      case 0x9E: // RES 3, (HL)
      case 0x9F: // RES 3, A

      case 0xA0: // RES 4, B
      case 0xA1: // RES 4, C
      case 0xA2: // RES 4, D
      case 0xA3: // RES 4, E
      case 0xA4: // RES 4, H
      case 0xA5: // RES 4, L
      case 0xA6: // RES 4, (HL)
      case 0xA7: // RES 4, A

      case 0xA8: // RES 5, B
      case 0xA9: // RES 5, C
      case 0xAA: // RES 5, D
      case 0xAB: // RES 5, E
      case 0xAC: // RES 5, H
      case 0xAD: // RES 5, L
      case 0xAE: // RES 5, (HL)
      case 0xAF: // RES 5, A

      case 0xB0: // RES 6, B
      case 0xB1: // RES 6, C
      case 0xB2: // RES 6, D
      case 0xB3: // RES 6, E
      case 0xB4: // RES 6, H
      case 0xB5: // RES 6, L
      case 0xB6: // RES 6, (HL)
      case 0xB7: // RES 6, A

      case 0xB8: // RES 7, B
      case 0xB9: // RES 7, C
      case 0xBA: // RES 7, D
      case 0xBB: // RES 7, E
      case 0xBC: // RES 7, H
      case 0xBD: // RES 7, L
      case 0xBE: // RES 7, (HL)
      case 0xBF: // RES 7, A

        var bit = (opcode & 0x38) >> 3;
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, resNR8(bit, getReg(r8)));
        break;

      case 0xC0: // SET 0, B
      case 0xC1: // SET 0, C
      case 0xC2: // SET 0, D
      case 0xC3: // SET 0, E
      case 0xC4: // SET 0, H
      case 0xC5: // SET 0, L
      case 0xC6: // SET 0, (HL)
      case 0xC7: // SET 0, A

      case 0xC8: // SET 1, B
      case 0xC9: // SET 1, C
      case 0xCA: // SET 1, D
      case 0xCB: // SET 1, E
      case 0xCC: // SET 1, H
      case 0xCD: // SET 1, L
      case 0xCE: // SET 1, (HL)
      case 0xCF: // SET 1, A

      case 0xD0: // SET 2, B
      case 0xD1: // SET 2, C
      case 0xD2: // SET 2, D
      case 0xD3: // SET 2, E
      case 0xD4: // SET 2, H
      case 0xD5: // SET 2, L
      case 0xD6: // SET 2, (HL)
      case 0xD7: // SET 2, A

      case 0xD8: // SET 3, B
      case 0xD9: // SET 3, C
      case 0xDA: // SET 3, D
      case 0xDB: // SET 3, E
      case 0xDC: // SET 3, H
      case 0xDD: // SET 3, L
      case 0xDE: // SET 3, (HL)
      case 0xDF: // SET 3, A

      case 0xE0: // SET 4, B
      case 0xE1: // SET 4, C
      case 0xE2: // SET 4, D
      case 0xE3: // SET 4, E
      case 0xE4: // SET 4, H
      case 0xE5: // SET 4, L
      case 0xE6: // SET 4, (HL)
      case 0xE7: // SET 4, A

      case 0xE8: // SET 5, B
      case 0xE9: // SET 5, C
      case 0xEA: // SET 5, D
      case 0xEB: // SET 5, E
      case 0xEC: // SET 5, H
      case 0xED: // SET 5, L
      case 0xEE: // SET 5, (HL)
      case 0xEF: // SET 5, A

      case 0xF0: // SET 6, B
      case 0xF1: // SET 6, C
      case 0xF2: // SET 6, D
      case 0xF3: // SET 6, E
      case 0xF4: // SET 6, H
      case 0xF5: // SET 6, L
      case 0xF6: // SET 6, (HL)
      case 0xF7: // SET 6, A

      case 0xF8: // SET 7, B
      case 0xF9: // SET 7, C
      case 0xFA: // SET 7, D
      case 0xFB: // SET 7, E
      case 0xFC: // SET 7, H
      case 0xFD: // SET 7, L
      case 0xFE: // SET 7, (HL)
      case 0xFF: // SET 7, A

        var bit = (opcode & 0x38) >> 3;
        int r8 = Registers.r8Table[opcode & 0x07];
        setReg(r8, setNR8(bit, getReg(r8)));
        break;

      default:
        processed = false;
        break;
    }

    return processed;
  }

  bool processIXYBitOpcodes(int prefix) {
    var processed = true;

    final d = fetch();
    final opcode = fetch();

    switch (opcode) {
      case 0x46: // BIT 0, (IXY + d)
      case 0x4E: // BIT 1, (IXY + d)
      case 0x56: // BIT 2, (IXY + d)
      case 0x5E: // BIT 3, (IXY + d)
      case 0x66: // BIT 4, (IXY + d)
      case 0x6E: // BIT 5, (IXY + d)
      case 0x76: // BIT 6, (IXY + d)
      case 0x7E: // BIT 7, (IXY + d)
        var bit = (opcode & 0x38) >> 3;
        bitNR8(bit, this.memory.peek(getIXY(prefix) + d));
        break;

      case 0x86: // RES 0, (IXY + d)
      case 0x8E: // RES 1, (IXY + d)
      case 0x96: // RES 2, (IXY + d)
      case 0x9E: // RES 3, (IXY + d)
      case 0xA6: // RES 4, (IXY + d)
      case 0xAE: // RES 5, (IXY + d)
      case 0xB6: // RES 6, (IXY + d)
      case 0xBE: // RES 7, (IXY + d)
        var bit = (opcode & 0x38) >> 3;
        var address = getIXY(prefix) + d;
        this.memory.poke(address, resNR8(bit, this.memory.peek(address)));
        break;

      case 0xC6: // SET 0, (IXY + d)
      case 0xCE: // SET 1, (IXY + d)
      case 0xD6: // SET 2, (IXY + d)
      case 0xDE: // SET 3, (IXY + d)
      case 0xE6: // SET 4, (IXY + d)
      case 0xEE: // SET 5, (IXY + d)
      case 0xF6: // SET 6, (IXY + d)
      case 0xFE: // SET 7, (IXY + d)
        var bit = (opcode & 0x38) >> 3;
        var address = getIXY(prefix) + d;
        this.memory.poke(address, setNR8(bit, this.memory.peek(address)));
        break;

      default:
        processed = false;
        break;
    }

    return processed;
  }

  int processOpcode(int opcode, Z80Instructions z80Instructions) {
    return z80Instructions.execute(opcode);
  }

  void nop({int opcode}) {}

  void rlca({int opcode}) {
    registers.A = rlcOp(registers.A);
  }

  void rrca({int opcode}) {
    registers.A = rrcOp(registers.A);
  }

  void rla({int opcode}) {
    registers.A = rlOp(registers.A);
  }

  void rra({int opcode}) {
    registers.A = rrOp(registers.A);
  }

  void cpl({int opcode}) {
    registers.A = registers.A ^ 255;
  }

  void scf({int opcode}) {
    registers.F = registers.F & ~Registers.F_ADD_SUB | Registers.F_CARRY;
  }

  void ccf({int opcode}) {
    registers.F = registers.F & ~Registers.F_ADD_SUB ^ Registers.F_CARRY;
  }

  void djnz({int opcode}) {
    var d = fetch();
    registers.B = byte(registers.B - 1);
    if (registers.B == 0) {
      this.PC = this.PC + d;
    }
  }

  void jr({int opcode}) {
    var d = fetch();
    this.PC = this.PC + d;
  }

  void jrcc({int opcode}) {
    var d = fetch();
    var cond = getFlagCondition(((opcode & 0x38) >> 3) - 4);
    if (cond) {
      this.PC = this.PC + d;
    }
  }

  void ldmBCA({int opcode}) {
    this.memory.poke(registers.BC, registers.A);
  }

  void ldAmBC({int opcode}) {
    registers.A = this.memory.peek(registers.BC);
  }

  void ldAmDE({int opcode}) {
    registers.A = this.memory.peek(registers.DE);
  }

  void ldmDEA({int opcode}) {
    this.memory.poke(registers.DE, registers.A);
  }

  void exAFAFq({int opcode}) {
    final af = registers.AF;
    registers.AF = registers.AFt;
    registers.AFt = af;
  }

  void incR8({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    setReg(r8, incR8Value(this.getReg(r8)));
  }

  void decR8({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    setReg(r8, decR8Value(this.getReg(r8)));
  }

  void incR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    setReg2(r16, word(getReg2(r16) + 1));
  }

  void decR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    setReg2(r16, word(getReg2(r16) - 1));
  }

  void addHLR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    registers.HL = addW(registers.HL, getReg2(r16));
  }

  void ldR8n({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    setReg(r8, fetch());
  }

  void ldR8mHL({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    setReg(r8, this.memory.peek(registers.HL));
  }

  void ldmHLR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    this.memory.poke(registers.HL, getReg(r8));
  }

  void ldmnnHL({int opcode}) {
    this.memory.poke2(fetch2(), registers.HL);
  }

  void ldHLmnn({int opcode}) {
    registers.HL = this.memory.peek2(fetch2());
  }

  void ldmnnA({int opcode}) {
    this.memory.poke(fetch2(), registers.A);
  }

  void ldAmnn({int opcode}) {
    registers.A = this.memory.peek(fetch2());
  }

  void ldmHLnn({int opcode}) {
    this.memory.poke(registers.HL, fetch());
  }

  void addAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = addA(getReg(r8));
  }

  void adcAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = adcA(getReg(r8));
  }

  void subAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = subA(getReg(r8));
  }

  void sbcAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = sbcA(getReg(r8));
  }

  void andAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = andA(getReg(r8));
  }

  void xorAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = xorA(getReg(r8));
  }

  void orAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    registers.A = orA(getReg(r8));
  }

  void cpAR8({int opcode}) {
    int r8 = Registers.r8Table[opcode & 0x07];
    subA(getReg(r8));
  }

  void addAn({int opcode}) {
    registers.A = addA(fetch());
  }

  void adcAn({int opcode}) {
    registers.A = adcA(fetch());
  }

  void subAn({int opcode}) {
    registers.A = subA(fetch());
  }

  void sbcAn({int opcode}) {
    registers.A = sbcA(fetch());
  }

  void andAn({int opcode}) {
    registers.A = andA(fetch());
  }

  void xorAn({int opcode}) {
    registers.A = xorA(fetch());
  }

  void orAn({int opcode}) {
    registers.A = orA(fetch());
  }

  void cpAn({int opcode}) {
    cpA(fetch());
  }

  void ldR8R8({int opcode}) {
    int r8Dest = Registers.r8Table[(opcode & 0x38) >> 3];
    int r8Source = Registers.r8Table[(opcode & 0x07)];
    this.setReg(r8Dest, getReg(r8Source));
  }

  void ldR16nn({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    setReg2(r16, fetch2());
  }

  void inR8C({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    var result = this.ports.inPort(registers.C);
    setReg(r8, result);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
  }

  void outCR8({int opcode}) {
    int r8 = Registers.r8Table[(opcode & 0x38) >> 3];
    this.ports.outPort(registers.C, getReg(r8));
  }

  void sbcHLR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    int value = getReg2(r16);
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

  void adcHLR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    int value = getReg2(r16);
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

  void ldmnnR16({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    this.memory.poke2(fetch2(), getReg2(r16));
  }

  void ldR16mnn({int opcode}) {
    int r16 = Registers.r16SPTable[(opcode & 0x30) >> 4];
    var a = fetch2();
    setReg2(r16, this.memory.peek2(a));
  }

  void neg({int opcode}) {
    registers.carryFlag = registers.A != 0;
    registers.parityOverflowFlag = registers.A == 0x80;
    registers.halfCarryFlag = registers.A != 0;
    registers.addSubtractFlag = true;
    var result = byte(0 - registers.A);
    registers.A = result;
    setZeroAndSignFlagsOn8BitResult(result);
  }

  void callnn({int opcode}) {
    var address = fetch2();
    push2(PC);
    this.PC = address;
  }

  void ret({int opcode}) {
    this.PC = pop2();
  }

  void jp({int opcode}) {
    this.PC = fetch2();
  }

  void callccnn({int opcode}) {
    var cond = getFlagCondition((opcode & 0x38) >> 3);
    var address = fetch2();
    if (cond) {
      push2(PC);
      this.PC = address;
    }
  }

  void retcc({int opcode}) {
    var cond = getFlagCondition((opcode & 0x38) >> 3);
    if (cond) {
      this.PC = pop2();
    }
  }

  void jpccnn({int opcode}) {
    var cond = getFlagCondition((opcode & 0x38) >> 3);
    if (cond) {
      this.PC = fetch2();
    }
  }

  void outnA({int opcode}) {
    this.ports.outPort(fetch(), registers.A);
  }

  void inAn({int opcode}) {
    registers.A = this.ports.inPort(fetch());
  }

  void exx({int opcode}) {
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

  void exSPHL({int opcode}) {
    var msp = this.memory.peek2(registers.SP);
    this.memory.poke2(registers.SP, registers.HL);
    registers.HL = msp;
  }

  void jpmHL({int opcode}) {
    this.PC = this.memory.peek2(registers.HL);
  }

  void exDEHL({int opcode}) {
    var de = registers.DE;
    registers.DE = registers.HL;
    registers.HL = de;
  }

  void ldSPHL({int opcode}) {
    registers.SP = registers.HL;
  }

  void pushR16({int opcode}) {
    int r16 = Registers.r16AFTable[(opcode & 0x30) >> 4];
    push2(getReg2(r16));
  }

  void popR16({int opcode}) {
    int r16 = Registers.r16AFTable[(opcode & 0x30) >> 4];
    setReg2(r16, pop2());
  }

  void rstNN({int opcode}) {
    var rst = opcode & 0x38;
    push2(this.PC);
    this.PC = rst;
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
    unPrefixedOpcodes.add(0x0A, " LD A, (BC)", ldAmBC, 4);
    unPrefixedOpcodes.add(0x1A, " LD A, (DE)", ldAmDE, 4);
    unPrefixedOpcodes.addR16(0x0B, "DEC [r16]", decR16, 4, multiplier: 16);
    unPrefixedOpcodes.add(0x12, " LD (DE), A", ldmDEA, 4);
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
}
