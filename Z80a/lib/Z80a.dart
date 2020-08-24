library z80a;

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Ports.dart';
import 'package:Z80a/Util.dart';

import 'Registers.dart';

class OpcodeResult {
  bool processed;
  int tStates;

  OpcodeResult(this.processed, this.tStates);

  OpcodeResult.processed(int tStates) {
    this.processed = true;
    this.tStates = tStates;
  }

  OpcodeResult.notProcessed() {
    this.processed = false;
    this.tStates = 0;
  }
}

typedef OpcodeResult OpcodeHandler({int opcode});

class Z80Instruction {
  String name;
  OpcodeHandler handler;
  int tStates;

  Z80Instruction(this.name, this.handler, this.tStates);
}

class Z80Instructions {
  static const r8Table = {
    0: Registers.R_B,
    1: Registers.R_C,
    2: Registers.R_D,
    3: Registers.R_E,
    4: Registers.R_H,
    5: Registers.R_L,
    6: Z80a.R_MHL,
    7: Registers.R_A,
  };

  static const r16SPTable = {
    0: Registers.R_BC,
    1: Registers.R_DE,
    2: Registers.R_HL,
    3: Registers.R_SP,
  };

  Map<int, Z80Instruction> instructions;

  Z80Instructions() {
    instructions = Map<int, Z80Instruction>();
  }

  void add(int opcode, String name, OpcodeHandler handler, int tStates) {
    instructions[opcode] = Z80Instruction(
      name,
      handler,
      tStates,
    );
  }

  void addMultiple(
      int opcode, int count, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < count; i++) {
      add(
        opcode + i * multiplier,
        name,
        handler,
        tStates,
      );
    }
  }

  void addR8(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < 8; i++) {
      var r8 = r8Table[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[r8]", Registers.r8Names[r8]),
        handler,
        tStates + (r8 == Z80a.R_MHL ? 3 : 0),
      );
    }
  }

  void addR16(int opcode, String name, OpcodeHandler handler, int tStates,
      {int multiplier = 1}) {
    for (var i = 0; i < 4; i++) {
      var r16 = r16SPTable[i];
      add(
        opcode + i * multiplier,
        name.replaceAll("[r16]", Registers.r16Names[r16]),
        handler,
        tStates,
      );
    }
  }

  OpcodeResult execute(int opcode) {
    return instructions[opcode] != null
        ? instructions[opcode].handler(opcode: opcode)
        : OpcodeResult.notProcessed();
  }
}

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

  static const R_MHL = 1000;
  static const R_MIXd = 2000;
  static const R_MIYd = 3000;

  int getIXY(int prefix) => prefix == IX_PREFIX ? registers.IX : registers.IY;

  void setIXY(int prefix, int w) =>
      prefix == IX_PREFIX ? registers.IX = w : registers.IY = w;

  static const r8Table = {
    0: Registers.R_B,
    1: Registers.R_C,
    2: Registers.R_D,
    3: Registers.R_E,
    4: Registers.R_H,
    5: Registers.R_L,
    6: R_MHL,
    7: Registers.R_A,
  };

  static const r16SPTable = {
    0: Registers.R_BC,
    1: Registers.R_DE,
    2: Registers.R_HL,
    3: Registers.R_SP,
  };

  static const r16SAFTable = {
    0: Registers.R_BC,
    1: Registers.R_DE,
    2: Registers.R_HL,
    3: Registers.R_AF,
  };

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
      r == R_MHL ? this.memory.peek(registers.HL) : registers[r];

  int getReg2(int r) => 256 * registers[r] + registers[r + 1];

  void setReg(int r, int b) => r == R_MHL
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

  int incR8(int value) {
    registers.parityOverflowFlag = value == 0x7F;
    var newValue = byte(value + 1);
    setZeroAndSignFlagsOn8BitResult(newValue);
    registers.addSubtractFlag = false;

    return newValue;
  }

  int decR8(int value) {
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

  bool step() {
    var processed = true;

    final opcode = fetch();

    var result = processOpcode(opcode, unPrefixedOpcodes);
    if (result.processed) return result.processed;

    switch (opcode) {
      case IX_PREFIX:
      case IY_PREFIX:
        processed = processIXYOpcodes(opcode);
        break;

      case EXTENDED_OPCODES:
        processed = processExtendedOpcodes();
        break;

      case BIT_OPCODES:
        processed = processBitOpcodes();
        break;

      default:
        processed = processUnprefixedOpCodes(opcode);
        break;
    }

    return processed;
  }

  bool processUnprefixedOpCodes(int opcode) {
    var processed = true;

    switch (opcode) {
      case 0x08: // EX AF, AF'
        final af = registers.AF;
        registers.AF = registers.AFt;
        registers.AFt = af;
        break;

      case 0x06: // LD B, n
      case 0x0E: // LD C, n
      case 0x16: // LD D, n
      case 0x1E: // LD E, n
      case 0x26: // LD H, n
      case 0x2E: // LD L, n
      case 0x3E: // LD A, n
        int r8 = r8Table[(opcode & 0x38) >> 3];
        setReg(r8, fetch());
        break;

      case 0x46: // LD B, (HL)
      case 0x4E: // LD C, (HL)
      case 0x56: // LD D, (HL)
      case 0x5E: // LD E, (HL)
      case 0x66: // LD H, (HL)
      case 0x6E: // LD L, (HL)
      case 0x7E: // LD A, (HL)
        int r8 = r8Table[(opcode & 0x38) >> 3];
        setReg(r8, this.memory.peek(registers.HL));
        break;

      case 0x70: // LD (HL), B
      case 0x71: // LD (HL), C
      case 0x72: // LD (HL), D
      case 0x73: // LD (HL), E
      case 0x74: // LD (HL), H
      case 0x75: // LD (HL), L
      case 0x77: // LD (HL), A
        int r8 = r8Table[opcode & 0x07];
        this.memory.poke(registers.HL, getReg(r8));
        break;

      // case 0x80: // ADD A, B
      // case 0x81: // ADD A, C
      // case 0x82: // ADD A, D
      // case 0x83: // ADD A, E
      // case 0x84: // ADD A, H
      // case 0x85: // ADD A, L
      // case 0x86: // ADD A, (HL)
      // case 0x87: // ADD A, A
      //   int r8 = r8Table[opcode & 0x07];
      //   registers.A = addA(getReg(r8));
      //   break;

      // case 0x88: // ADC A, B
      // case 0x89: // ADC A, C
      // case 0x8A: // ADC A, D
      // case 0x8B: // ADC A, E
      // case 0x8C: // ADC A, H
      // case 0x8D: // ADC A, L
      // case 0x8E: // ADC A, (HL)
      // case 0x8F: // ADC A, A
      //   int r8 = r8Table[opcode & 0x07];
      //   registers.A = adcA(getReg(r8));
      //   break;

      // case 0x90: // SUB B
      // case 0x91: // SUB C
      // case 0x92: // SUB D
      // case 0x93: // SUB E
      // case 0x94: // SUB H
      // case 0x95: // SUB L
      // case 0x96: // SUB (HL)
      // case 0x97: // SUB A
      //   int r8 = r8Table[opcode & 0x07];
      //   registers.A = subA(getReg(r8));
      //   break;

      case 0x98: // SBC A, B
      case 0x99: // SBC A, C
      case 0x9A: // SBC A, D
      case 0x9B: // SBC A, E
      case 0x9C: // SBC A, H
      case 0x9D: // SBC A, L
      case 0x9E: // SBC A, (HL)
      case 0x9F: // SBC A, A
        int r8 = r8Table[opcode & 0x07];
        registers.A = sbcA(getReg(r8));
        break;

      case 0xA0: // AND B
      case 0xA1: // AND C
      case 0xA2: // AND D
      case 0xA3: // AND E
      case 0xA4: // AND H
      case 0xA5: // AND L
      case 0xA6: // AND (HL)
      case 0xA7: // AND A
        int r8 = r8Table[opcode & 0x07];
        registers.A = andA(getReg(r8));
        break;

      case 0xA8: // XOR B
      case 0xA9: // XOR C
      case 0xAA: // XOR D
      case 0xAB: // XOR E
      case 0xAC: // XOR H
      case 0xAD: // XOR L
      case 0xAE: // XOR (HL)
      case 0xAF: // XOR A
        int r8 = r8Table[opcode & 0x07];
        registers.A = xorA(getReg(r8));
        break;

      case 0xB0: // OR B
      case 0xB1: // OR C
      case 0xB2: // OR D
      case 0xB3: // OR E
      case 0xB4: // OR H
      case 0xB5: // OR L
      case 0xB6: // OR (HL)
      case 0xB7: // OR A
        int r8 = r8Table[opcode & 0x07];
        registers.A = orA(getReg(r8));
        break;

      case 0xB8: // CP B
      case 0xB9: // CP C
      case 0xBA: // CP D
      case 0xBB: // CP E
      case 0xBC: // CP H
      case 0xBD: // CP L
      case 0xBE: // CP (HL)
      case 0xBF: // CP A
        int r8 = r8Table[opcode & 0x07];
        subA(getReg(r8));
        break;

      case 0xC6: // ADD A, N
        registers.A = addA(fetch());
        break;

      case 0xCE: // ADC A, N
        registers.A = adcA(fetch());
        break;

      case 0xD6: // SUB N
        registers.A = subA(fetch());
        break;

      case 0xDE: // SBC A, N
        registers.A = sbcA(fetch());
        break;

      case 0xE6: // AND A, N
        registers.A = andA(fetch());
        break;

      case 0xEE: // XOR N
        registers.A = xorA(fetch());
        break;

      case 0xF6: // OR N
        registers.A = orA(fetch());
        break;

      case 0xFE: // CP N
        cpA(fetch());
        break;

      case 0x22: // LD (nn), HL
        this.memory.poke2(fetch2(), registers.HL);
        break;

      case 0x2A: // LD HL, (nn)
        var a = fetch2();
        registers.HL = this.memory.peek2(a);
        break;

      case 0x32: // LD (NN), A
        this.memory.poke(fetch2(), registers.A);
        break;

      case 0x36: // LD (HL), nn
        this.memory.poke(registers.HL, fetch());
        break;

      case 0x3A: // LD A, (NN)
        registers.A = this.memory.peek(fetch2());
        break;

      case 0x01: // LD BC, nn
      case 0x11: // LD DE, nn
      case 0x21: // LD HL, nn
      case 0x31: // LD SP, nn
        int r16 = r16SPTable[(opcode & 0x30) >> 4];
        setReg2(r16, fetch2());
        break;

      case 0x03: // INC BC
      case 0x13: // INC DE
      case 0x23: // INC HL
      case 0x33: // INC SP
        int r16 = r16SPTable[(opcode & 0x30) >> 4];
        setReg2(r16, word(getReg2(r16) + 1));
        break;

      case 0x0B: // DEC BC
      case 0x1B: // DEC DE
      case 0x2B: // DEC HL
      case 0x3B: // DEC SP
        int r16 = r16SPTable[(opcode & 0x30) >> 4];
        setReg2(r16, word(getReg2(r16) - 1));
        break;

      case 0x09: // ADD HL, BC
      case 0x19: // ADD HL, DE
      case 0x29: // ADD HL, HL
      case 0x39: // ADD HL, SP
        int r16 = r16SPTable[(opcode & 0x30) >> 4];
        registers.HL = addW(registers.HL, getReg2(r16));
        break;

      case 0x04: // INC B
      case 0x0C: // INC C
      case 0x14: // INC D
      case 0x1C: // INC E
      case 0x24: // INC H
      case 0x2C: // INC L
      case 0x34: // INC (HL)
      case 0x3C: // INC A
        int r8 = r8Table[(opcode & 0x38) >> 3];
        setReg(r8, incR8(this.getReg(r8)));
        break;

      case 0x05: // DEC B
      case 0x0D: // DEC C
      case 0x15: // DEC D
      case 0x1D: // DEC E
      case 0x25: // DEC H
      case 0x2D: // DEC L
      case 0x35: // DEC (HL)
      case 0x3D: // DEC A
        int r8 = r8Table[(opcode & 0x38) >> 3];
        setReg(r8, decR8(this.getReg(r8)));
        break;

      case 0x02: // LD (BC), A
        this.memory.poke(registers.BC, registers.A);
        break;

      case 0x12: // LD (DE), A
        this.memory.poke(registers.DE, registers.A);
        break;

      case 0x0A: // LD A, (BC)
        registers.A = this.memory.peek(registers.BC);
        break;

      case 0x1A: // LD A, (DE)
        registers.A = this.memory.peek(registers.DE);
        break;

      case 0x07: // RLCA
        registers.A = rlcOp(registers.A);
        break;

      case 0x0F: // RRCA
        registers.A = rrcOp(registers.A);
        break;

      case 0x17: // RLA
        registers.A = rlOp(registers.A);
        break;

      case 0x1F: // RRA
        registers.A = rrOp(registers.A);
        break;

      case 0x2F: // CPL
        registers.A = registers.A ^ 255;
        break;

      case 0x37: // CCF
        registers.F = registers.F & ~Registers.F_ADD_SUB | Registers.F_CARRY;
        break;

      case 0x3F: // CCF
        registers.F = registers.F & ~Registers.F_ADD_SUB ^ Registers.F_CARRY;
        break;

      case 0x40: // LD B, B
      case 0x41: // LD B, C
      case 0x42: // LD B, D
      case 0x43: // LD B, E
      case 0x44: // LD B, H
      case 0x45: // LD B, L
      case 0x47: // LD B, A
      case 0x48: // LD C, B
      case 0x49: // LD C, C
      case 0x4A: // LD C, D
      case 0x4B: // LD C, E
      case 0x4C: // LD C, H
      case 0x4D: // LD C, L
      case 0x4F: // LD C, A
      case 0x50: // LD D, B
      case 0x51: // LD D, C
      case 0x52: // LD D, D
      case 0x53: // LD D, E
      case 0x54: // LD D, H
      case 0x55: // LD D, L
      case 0x57: // LD D, A
      case 0x58: // LD E, B
      case 0x59: // LD E, C
      case 0x5A: // LD E, D
      case 0x5B: // LD E, E
      case 0x5C: // LD E, H
      case 0x5D: // LD E, L
      case 0x5F: // LD E, A
      case 0x60: // LD H, B
      case 0x61: // LD H, C
      case 0x62: // LD H, D
      case 0x63: // LD H, E
      case 0x64: // LD H, H
      case 0x65: // LD H, L
      case 0x67: // LD H, A
      case 0x68: // LD L, B
      case 0x69: // LD L, C
      case 0x6A: // LD L, D
      case 0x6B: // LD L, E
      case 0x6C: // LD L, H
      case 0x6D: // LD L, L
      case 0x6F: // LD L, A
      case 0x78: // LD A, B
      case 0x79: // LD A, C
      case 0x7A: // LD A, D
      case 0x7B: // LD A, E
      case 0x7C: // LD A, H
      case 0x7D: // LD A, L
      case 0x7F: // LD A, A
        int r8Source = r8Table[(opcode & 0x38) >> 3];
        int r8Dest = r8Table[(opcode & 0x07)];
        this.setReg(r8Dest, getReg(r8Source));
        break;

      case 0xCD: // CALL NN
        var address = fetch2();
        push2(PC);
        this.PC = address;
        break;

      case 0xC4: // CALL NZ
      case 0xCC: // CALL Z
      case 0xD4: // CALL NC
      case 0xDC: // CALL C
      case 0xE4: // CALL PO
      case 0xEC: // CALL PE
      case 0xF4: // CALL P
      case 0xFC: // CALL M
        var cond = getFlagCondition((opcode & 0x38) >> 3);
        var address = fetch2();
        if (cond) {
          push2(PC);
          this.PC = address;
        }
        break;

      case 0xC9: // RET
        this.PC = pop2();
        break;

      case 0xC0: // RET NZ
      case 0xC8: // RET Z
      case 0xD0: // RET NC
      case 0xD8: // RET C
      case 0xE0: // RET PO
      case 0xE8: // RET PE
      case 0xF0: // RET P
      case 0xF8: // RET M
        var cond = getFlagCondition((opcode & 0x38) >> 3);
        if (cond) {
          this.PC = pop2();
        }
        break;

      case 0xC2: // JP NZ
      case 0xCA: // JP Z
      case 0xD2: // JP NC
      case 0xDA: // JP C
      case 0xE2: // JP PO
      case 0xEA: // JP PE
      case 0xF2: // JP P
      case 0xFA: // JP M
        var cond = getFlagCondition((opcode & 0x38) >> 3);
        if (cond) {
          this.PC = fetch2();
        }
        break;

      case 0xC3: // JP NN
        this.PC = fetch2();
        break;

      case 0xC5: // PUSH BC
        push2(registers.BC);
        break;

      case 0xD5: // PUSH DE
        push2(registers.DE);
        break;

      case 0xE5: // PUSH HL
        push2(registers.HL);
        break;

      case 0xF5: // PUSH AF
        push2(registers.AF);
        break;

      case 0xC1: // POP BC
        registers.BC = pop2();
        break;

      case 0xD1: // POP DE
        registers.DE = pop2();
        break;

      case 0xE1: // POP HL
        registers.HL = pop2();
        break;

      case 0xF1: // POP AF
        registers.AF = pop2();
        break;

      case 0xC7: // RST 00
      case 0xCF: // RST 08
      case 0xD7: // RST 16
      case 0xDF: // RST 24
      case 0xE7: // RST 32
      case 0xEF: // RST 40
      case 0xF7: // RST 48
      case 0xFF: // RST 56
        var rst = opcode & 0x38;
        push2(this.PC);
        this.PC = rst;
        break;

      case 0xD9: // EXX
        var bc = registers.BC;
        var de = registers.DE;
        var hl = registers.HL;
        registers.BC = registers.BCt;
        registers.DE = registers.DEt;
        registers.HL = registers.HLt;
        registers.BCt = bc;
        registers.DEt = de;
        registers.HLt = hl;
        break;

      case 0x10: // DJNZ NN
        var d = fetch();
        registers.B = byte(registers.B - 1);
        if (registers.B == 0) {
          this.PC = this.PC + d;
        }
        break;

      case 0x18: // JR NN
        var d = fetch();
        this.PC = this.PC + d;
        break;

      case 0x20: // JR NZ
      case 0x28: // JR Z
      case 0x30: // JR NC
      case 0x38: // JR C
        var d = fetch();
        var cond = getFlagCondition(((opcode & 0x38) >> 3) - 4);
        if (cond) {
          this.PC = this.PC + d;
        }
        break;

      case 0xE3: // EX (SP), HL
        var msp = this.memory.peek2(registers.SP);
        this.memory.poke2(registers.SP, registers.HL);
        registers.HL = msp;
        break;

      case 0xE9: // JP (HL)
        this.PC = this.memory.peek2(registers.HL);
        break;

      case 0xEB: // EX DE, HL
        var de = registers.DE;
        registers.DE = registers.HL;
        registers.HL = de;
        break;

      case 0xF9: // LD SP, HL
        registers.SP = registers.HL;
        break;

      case 0xD3: // OUT (N), A
        this.ports.outPort(fetch(), registers.A);
        break;

      case 0xDB: // IN A, (N)
        registers.A = this.ports.inPort(fetch());
        break;

      default:
        processed = false;
        break;
    }

    return processed;
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
        this.memory.poke(
            getIXY(prefix) + d, incR8(this.memory.peek(getIXY(prefix) + d)));
        break;

      case 0x35: // DEC (IXY+d)
        var d = fetch();
        this.memory.poke(
            getIXY(prefix) + d, decR8(this.memory.peek(getIXY(prefix) + d)));
        break;

      case 0x09: // ADD IXY, BC
      case 0x19: // ADD IXY, DE
      case 0x39: // ADD IXY, SP
        int r16 = r16SPTable[(opcode & 0x30) >> 4];
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
        int r8 = r8Table[(opcode & 0x38) >> 3];
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
        int r8 = r8Table[opcode & 0x07];
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

  bool processExtendedOpcodes() {
    var processed = true;

    final opcode = fetch();

    switch (opcode) {
      // case 0x40: // IN B, (C)
      // case 0x48: // IN C, (C)
      // case 0x50: // IN D, (C)
      // case 0x58: // IN E, (C)
      // case 0x60: // IN H, (C)
      // case 0x68: // IN L, (C)
      // case 0x78: // IN A, (C)
      //   int r8 = r8Table[(opcode & 0x38) >> 3];
      //   var result = this.ports.inPort(registers.C);
      //   setReg(r8, result);
      //   setZeroAndSignFlagsOn8BitResult(result);
      //   registers.parityOverflowFlag = parity(result);
      //   registers.addSubtractFlag = false;
      //   registers.halfCarryFlag = false;
      //   break;

      // case 0x41: // OUT B, (C)
      // case 0x49: // OUT C, (C)
      // case 0x51: // OUT D, (C)
      // case 0x59: // OUT E, (C)
      // case 0x61: // OUT H, (C)
      // case 0x69: // OUT L, (C)
      // case 0x79: // OUT A, (C)
      //   int r8 = r8Table[(opcode & 0x38) >> 3];
      //   this.ports.outPort(registers.C, getReg(r8));
      //   break;

      // case 0x42: // SBC HL, BC
      // case 0x52: // SBC HL, DE
      // case 0x62: // SBC HL, HL
      // case 0x72: // SBC HL, SP
      //   int r16 = r16SPTable[(opcode & 0x30) >> 4];
      //   int value = getReg2(r16);
      //   int cf = (registers.carryFlag ? 1 : 0);
      //   var result = registers.HL - value - cf;
      //   registers.parityOverflowFlag =
      //       (((registers.HL & 0x8000) ^ (value & 0x8000)) == 0) &&
      //           (value & 0x8000 != (result & 0x8000));
      //   registers.carryFlag = result < 0;
      //   registers.halfCarryFlag =
      //       (registers.HL & 0x0FFF) - (value & 0x0FFF) - cf < 0x00;
      //   registers.addSubtractFlag = true;
      //   registers.HL = word(result);
      //   setZeroAndSignFlagsOn16BitResult(registers.HL);
      //   break;

      // case 0x4A: // ADC HL, BC
      // case 0x5A: // ADC HL, DE
      // case 0x6A: // ADC HL, HL
      // case 0x7A: // ADC HL, SP
      //   int r16 = r16SPTable[(opcode & 0x30) >> 4];
      //   int value = getReg2(r16);
      //   int cf = (registers.carryFlag ? 1 : 0);
      //   var result = registers.HL + value + cf;
      //   registers.parityOverflowFlag =
      //       (((registers.HL & 0x8000) ^ (value & 0x8000)) == 0) &&
      //           (value & 0x8000 != (result & 0x8000));
      //   registers.carryFlag = result > 65535;
      //   registers.halfCarryFlag =
      //       (registers.HL & 0x0FFF) + (value & 0x0FFF) + cf > 0x0FFF;
      //   registers.addSubtractFlag = false;
      //   registers.HL = word(result);
      //   setZeroAndSignFlagsOn16BitResult(registers.HL);
      //   break;

      // case 0x43: // LD (nn), BC
      // case 0x53: // LD (nn), DE
      // case 0x63: // LD (nn), HL
      // case 0x73: // LD (nn), SP
      //   int r16 = r16SPTable[(opcode & 0x30) >> 4];
      //   this.memory.poke2(fetch2(), getReg2(r16));
      //   break;

      // case 0x4B: // LD BC, (nn)
      // case 0x5B: // LD DE, (nn)
      // case 0x6B: // LD HL, (nn)
      // case 0x7B: // LD SP, (nn)
      //   int r16 = r16SPTable[(opcode & 0x30) >> 4];
      //   var a = fetch2();
      //   setReg2(r16, this.memory.peek2(a));
      //   break;

      // case 0x44: // NEG
      // case 0x54: // NEG
      // case 0x64: // NEG
      // case 0x74: // NEG
      // case 0x4C: // NEG
      // case 0x5C: // NEG
      // case 0x6C: // NEG
      // case 0x7C: // NEG
      //   registers.carryFlag = registers.A != 0;
      //   registers.parityOverflowFlag = registers.A == 0x80;
      //   registers.halfCarryFlag = registers.A != 0;
      //   registers.addSubtractFlag = true;
      //   var result = byte(0 - registers.A);
      //   registers.A = result;
      //   setZeroAndSignFlagsOn8BitResult(result);
      //   break;

      default:
        // processed = false;
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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
        int r8 = r8Table[opcode & 0x07];
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

  OpcodeResult processOpcode(int opcode, Z80Instructions z80Instructions) {
    return z80Instructions.execute(opcode);
  }

  OpcodeResult nop({int opcode}) {
    return OpcodeResult.processed(4);
  }

  OpcodeResult addAR8({int opcode}) {
    int r8 = r8Table[opcode & 0x07];
    registers.A = addA(getReg(r8));
    return OpcodeResult.processed(4);
  }

  OpcodeResult adcAR8({int opcode}) {
    int r8 = r8Table[opcode & 0x07];
    registers.A = adcA(getReg(r8));
    return OpcodeResult.processed(4);
  }

  OpcodeResult subAR8({int opcode}) {
    int r8 = r8Table[opcode & 0x07];
    registers.A = subA(getReg(r8));
    return OpcodeResult.processed(4);
  }

  OpcodeResult inR8C({int opcode}) {
    int r8 = r8Table[(opcode & 0x38) >> 3];
    var result = this.ports.inPort(registers.C);
    setReg(r8, result);
    setZeroAndSignFlagsOn8BitResult(result);
    registers.parityOverflowFlag = parity(result);
    registers.addSubtractFlag = false;
    registers.halfCarryFlag = false;
    return OpcodeResult.processed(12);
  }

  OpcodeResult outCR8({int opcode}) {
    int r8 = r8Table[(opcode & 0x38) >> 3];
    this.ports.outPort(registers.C, getReg(r8));
    return OpcodeResult.processed(12);
  }

  OpcodeResult sbcHLR16({int opcode}) {
    int r16 = r16SPTable[(opcode & 0x30) >> 4];
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
    return OpcodeResult.processed(15);
  }

  OpcodeResult adcHLR16({int opcode}) {
    int r16 = r16SPTable[(opcode & 0x30) >> 4];
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
    return OpcodeResult.processed(15);
  }

  OpcodeResult ldMNNR16({int opcode}) {
    int r16 = r16SPTable[(opcode & 0x30) >> 4];
    this.memory.poke2(fetch2(), getReg2(r16));
    return OpcodeResult.processed(20);
  }

  OpcodeResult ldR16MNN({int opcode}) {
    int r16 = r16SPTable[(opcode & 0x30) >> 4];
    var a = fetch2();
    setReg2(r16, this.memory.peek2(a));
    return OpcodeResult.processed(20);
  }

  OpcodeResult neg({int opcode}) {
    registers.carryFlag = registers.A != 0;
    registers.parityOverflowFlag = registers.A == 0x80;
    registers.halfCarryFlag = registers.A != 0;
    registers.addSubtractFlag = true;
    var result = byte(0 - registers.A);
    registers.A = result;
    setZeroAndSignFlagsOn8BitResult(result);
    return OpcodeResult.processed(8);
  }

  OpcodeResult extended({int opcode}) {
    return processOpcode(fetch(), extendedOpcodes);
  }

  void buildUnprefixedOpcodes() {
    unPrefixedOpcodes = Z80Instructions();

    unPrefixedOpcodes.add(EXTENDED_OPCODES, "", extended, 0);

    unPrefixedOpcodes.add(0x00, "NOP", nop, 4);
    unPrefixedOpcodes.addR8(0x80, "ADD A, [r8]", addAR8, 4);
    unPrefixedOpcodes.addR8(0x88, "ADC A, [r8]", adcAR8, 4);
    unPrefixedOpcodes.addR8(0x90, "SUB [r8]", subAR8, 4);
  }

  void buildExtendedOpcodes() {
    extendedOpcodes = Z80Instructions();
    extendedOpcodes.addR8(0x40, "IN [r8], C", inR8C, 12, multiplier: 8);
    extendedOpcodes.addR8(0x41, "OUT C, [r8]", outCR8, 12, multiplier: 8);
    extendedOpcodes.addR16(0x42, "SBC HL, [r16]", sbcHLR16, 15, multiplier: 16);
    extendedOpcodes.addR16(0x4A, "ADC HL, [r16]", adcHLR16, 15, multiplier: 16);
    extendedOpcodes.addR16(0x43, "LD (NN), [r16]", ldMNNR16, 20,
        multiplier: 16);
    extendedOpcodes.addR16(0x4B, "LD [R16], (NN)", ldR16MNN, 20,
        multiplier: 16);
    extendedOpcodes.addMultiple(0x44, 4, "NEG", neg, 8, multiplier: 16);
    extendedOpcodes.addMultiple(0x4C, 4, "NEG", neg, 8, multiplier: 16);
  }
}
