library z80a;

import './Memory.dart';

// ignore_for_file: non_constant_identifier_names

class Z80a {
  static const r8Names = {
    R_A: "A",
    R_F: "F",
    R_B: "B",
    R_C: "C",
    R_D: "D",
    R_E: "E",
    R_H: "H",
    R_L: "L",
  };

  static const r16Names = {
    R_AF: "AF",
    R_BC: "BC",
    R_DE: "DE",
    R_HL: "HL",
    R_SP: "SP",
    R_IX: "IX",
    R_IY: "IY",
  };

  static const R_A = 0;
  static const R_F = 1;
  static const R_B = 2;
  static const R_C = 3;
  static const R_D = 4;
  static const R_E = 5;
  static const R_H = 6;
  static const R_L = 7;
  static const R_S = 8;
  static const R_P = 9;
  static const R_IX_H = 10;
  static const R_IX_L = 11;
  static const R_IY_L = 12;
  static const R_IY_H = 13;

  static const R_COUNT = 14;

  static const R_AF = R_A;
  static const R_BC = R_B;
  static const R_DE = R_D;
  static const R_HL = R_H;
  static const R_SP = R_S;
  static const R_IX = R_IX_H;
  static const R_IY = R_IY_H;

  static const F_CARRY = 0x01;
  static const F_ADD_SUB = 0x02;
  static const F_PARITY = 0x04;
  static const F_HALF_CARRY = 0x08;
  static const F_ZERO = 0x10;
  static const F_SIGN = 0x20;

  final Memory memory;

  Z80a(this.memory);

  var registers = List<int>.filled(R_COUNT, 0);
  var AF_L = 0;
  var BC_L = 0;
  var DE_L = 0;
  var HL_L = 0;
  var PC = 0;

  int gw(int r) => 256 * registers[r] + registers[r + 1];
  void sw(int r, int w) {
    registers[r] = w ~/ 256;
    registers[r + 1] = w % 256;
  }

  int get A => registers[R_A];
  int get F => registers[R_F];
  int get B => registers[R_B];
  int get C => registers[R_C];
  int get D => registers[R_D];
  int get E => registers[R_E];
  int get H => registers[R_H];
  int get L => registers[R_L];
  int get S => registers[R_S];
  int get P => registers[R_P];
  int get IX_L => registers[R_IX_L];
  int get IX_H => registers[R_IX_H];
  int get IY_L => registers[R_IY_L];
  int get IY_H => registers[R_IY_H];

  set A(int b) => registers[R_A] = b;
  set F(int b) => registers[R_F] = b;
  set B(int b) => registers[R_B] = b;
  set C(int b) => registers[R_C] = b;
  set D(int b) => registers[R_D] = b;
  set E(int b) => registers[R_E] = b;
  set H(int b) => registers[R_H] = b;
  set L(int b) => registers[R_L] = b;
  set S(int b) => registers[R_S] = b;
  set P(int b) => registers[R_P] = b;
  set IX_H(int b) => registers[R_IX_H] = b;
  set IX_L(int b) => registers[R_IX_L] = b;
  set IY_H(int b) => registers[R_IY_H] = b;
  set IY_L(int b) => registers[R_IY_L] = b;

  int get AF => gw(R_A);
  int get BC => gw(R_B);
  int get DE => gw(R_D);
  int get HL => gw(R_H);
  int get SP => gw(R_S);
  int get IX => gw(R_IX_H);
  int get IY => gw(R_IY_H);

  set AF(int w) => sw(R_A, w);
  set BC(int w) => sw(R_B, w);
  set DE(int w) => sw(R_D, w);
  set HL(int w) => sw(R_H, w);
  set SP(int w) => sw(R_S, w);
  set IX(int w) => sw(R_IX_H, w);
  set IY(int w) => sw(R_IY_H, w);

  bool get carryFlag => F & F_CARRY != 0;
  bool get addSubtractFlag => F & F_ADD_SUB != 0;
  bool get parityOverflowFlag => F & F_PARITY != 0;
  bool get zeroFlag => F & F_ZERO != 0;
  bool get signFlag => F & F_SIGN != 0;

  set carryFlag(bool b) => F = b ? F | F_CARRY : F & ~F_CARRY;
  set addSubtractFlag(bool b) => F = b ? F | F_ADD_SUB : F & ~F_ADD_SUB;
  set parityOverflowFlag(bool b) => F = b ? F | F_PARITY : F & ~F_PARITY;
  set zeroFlag(bool b) => F = b ? F | F_ZERO : F & ~F_ZERO;
  set signFlag(bool b) => F = b ? F | F_SIGN : F & ~F_SIGN;

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

  int getReg(int r) => registers[r];

  int getReg2(int r) => 256 * registers[r] + registers[r + 1];

  void setReg(int r, int b) => registers[r] = byte(b);

  void setReg2(int r, int w) {
    registers[r] = w ~/ 256;
    registers[r + 1] = w % 256;
  }

  int add(int b1, int b2) {
    int r = b1 + b2;
    carryFlag = r > 255;
    return word(r);
  }

  int addW(int w1, int w2) {
    int r = w1 + w2;
    carryFlag = r > 65535;
    return word(r);
  }

  void setFlagsOnResult(int b) {
    zeroFlag = b == 0;
    signFlag = b > 127;
  }

  void start(int pc) {
    this.PC = pc;
    final opcode = fetch();

    switch (opcode) {
      case 0x00:
        break;

      case 0x01:
        this.BC = fetch2();
        break;

      case 0x11:
        this.DE = fetch2();
        break;

      case 0x21:
        this.HL = fetch2();
        break;

      case 0x31:
        this.SP = fetch2();
        break;

      case 0x02:
        this.memory.poke(BC, A);
        break;

      case 0x03:
        this.BC = word(this.BC + 1);
        break;

      case 0x13:
        this.DE = word(this.DE + 1);
        break;

      case 0x23:
        this.HL = word(this.HL + 1);
        break;

      case 0x33:
        this.SP = word(this.SP + 1);
        break;

      case 0x0B:
        this.BC = word(this.BC - 1);
        break;

      case 0x1B:
        this.DE = word(this.DE - 1);
        break;

      case 0x2B:
        this.HL = word(this.HL - 1);
        break;

      case 0x3B:
        this.SP = word(this.SP - 1);
        break;

      case 0x09:
        this.HL = addW(this.HL, this.BC);
        break;

      case 0x19:
        this.HL = addW(this.HL, this.DE);
        break;

      case 0x29:
        this.HL = word(this.HL + this.HL);
        break;

      case 0x39:
        this.HL = addW(this.HL, this.SP);
        break;

      case 0x04:
        this.parityOverflowFlag = this.B == 0x7F;
        this.B = byte(this.B + 1);
        setFlagsOnResult(B);
        break;

      case 0x0C:
        this.parityOverflowFlag = this.C == 0x7F;

        this.C = byte(this.C + 1);
        setFlagsOnResult(C);
        break;

      case 0x14:
        this.parityOverflowFlag = this.D == 0x7F;
        this.D = byte(this.D + 1);
        setFlagsOnResult(D);
        break;

      case 0x1C:
        this.parityOverflowFlag = this.E == 0x7F;
        this.E = byte(this.E + 1);
        setFlagsOnResult(E);
        break;

      case 0x24:
        this.parityOverflowFlag = this.H == 0x7F;
        this.H = byte(this.H + 1);
        setFlagsOnResult(H);
        break;

      case 0x2C:
        this.parityOverflowFlag = this.L == 0x7F;
        this.L = byte(this.L + 1);
        setFlagsOnResult(L);
        break;

      case 0x34:
        this.parityOverflowFlag = this.memory.peek(this.HL) == 0x7F;
        this.memory.poke(this.HL, byte(this.memory.peek(this.HL) + 1));
        setFlagsOnResult(this.memory.peek(this.HL));
        break;

      case 0x3C:
        this.parityOverflowFlag = this.A == 0x7F;
        this.A = byte(this.A + 1);
        setFlagsOnResult(A);
        break;

      case 0x05:
        this.parityOverflowFlag = this.B == 0x80;
        this.B = byte(this.B - 1);
        setFlagsOnResult(B);
        break;

      case 0x0D:
        this.parityOverflowFlag = this.C == 0x80;
        this.C = byte(this.C - 1);
        setFlagsOnResult(C);
        break;

      case 0x15:
        this.parityOverflowFlag = this.D == 0x80;
        this.D = byte(this.D - 1);
        setFlagsOnResult(D);
        break;

      case 0x1D:
        this.parityOverflowFlag = this.E == 0x80;
        this.E = byte(this.E - 1);
        setFlagsOnResult(E);
        break;

      case 0x25:
        this.parityOverflowFlag = this.H == 0x80;
        this.H = byte(this.H - 1);
        setFlagsOnResult(H);
        break;

      case 0x2D:
        this.parityOverflowFlag = this.L == 0x80;
        this.L = byte(this.L - 1);
        setFlagsOnResult(L);
        break;

      case 0x35:
        this.parityOverflowFlag = this.memory.peek(this.HL) == 0x80;
        this.memory.poke(this.HL, byte(this.memory.peek(this.HL) - 1));
        setFlagsOnResult(this.memory.peek(this.HL));
        break;

      case 0x3D:
        this.parityOverflowFlag = this.A == 0x80;
        this.A = byte(this.A - 1);
        setFlagsOnResult(A);
        break;

      case 0x08:
        final af = AF;
        AF = AF_L;
        AF_L = af;
        break;

      case 0x0A:
        this.A = this.memory.peek(BC);
        break;

      case 0x1A:
        this.A = this.memory.peek(DE);
        break;

      case 0x12:
        this.memory.poke(DE, A);
        break;
    }
  }
}
