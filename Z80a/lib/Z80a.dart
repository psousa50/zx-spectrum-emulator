library z80a;

import './Memory.dart';

// ignore_for_file: non_constant_identifier_names

class Z80a {
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

  static const R_AF = R_A;
  static const R_BC = R_B;
  static const R_DE = R_D;
  static const R_HL = R_H;
  static const R_SP = R_S;
  static const R_IX = R_IX_H;
  static const R_IY = R_IY_H;

  final Memory memory;

  Z80a(this.memory);

  var registers = List<int>.filled(14, 0);
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

  void start(int pc) {
    this.PC = pc;
    final opcode = fetch();

    switch (opcode) {
      case 0x01:
        this.BC = fetch2();
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

      case 0x04:
        this.B = byte(this.B + 1);
        break;

      case 0x08:
        final af = AF;
        AF = AF_L;
        AF_L = af;
        break;

      case 0x0C:
        this.memory.poke(DE, A);
        break;
    }
  }
}
