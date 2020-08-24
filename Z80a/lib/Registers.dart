import 'package:Z80a/Z80a.dart';

import 'Util.dart';

// ignore_for_file: non_constant_identifier_names

class Registers {
  static const r8Names = {
    R_A: "A",
    R_F: "F",
    R_B: "B",
    R_C: "C",
    R_D: "D",
    R_E: "E",
    R_H: "H",
    R_L: "L",
    Z80a.R_MHL: "(HL)",
    R_S: "S",
    R_P: "P",
    R_IX_L: "IX_l",
    R_IX_H: "IX_h",
    R_IY_L: "IY_l",
    R_IY_H: "IY_h",
    R_At: "A'",
    R_Ft: "F'",
    R_Bt: "B'",
    R_Ct: "C'",
    R_Dt: "D'",
    R_Et: "E'",
    R_Ht: "H'",
    R_Lt: "L'",
  };

  static const r16Names = {
    R_AF: "AF",
    R_BC: "BC",
    R_DE: "DE",
    R_HL: "HL",
    R_SP: "SP",
    R_IX: "IX",
    R_IY: "IY",
    R_AFt: "AF'",
    R_BCt: "BC'",
    R_DEt: "DE'",
    R_HLt: "HL'",
  };

  static const flagNames = {
    F_SIGN: "S",
    F_ZERO: "Z",
    F_HALF_CARRY: "H",
    F_PARITY: "P",
    F_ADD_SUB: "N",
    F_CARRY: "C",
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
  static const R_At = 14;
  static const R_Ft = 15;
  static const R_Bt = 16;
  static const R_Ct = 17;
  static const R_Dt = 18;
  static const R_Et = 19;
  static const R_Ht = 20;
  static const R_Lt = 21;

  static const R_COUNT = 22;

  static const R_AF = R_A;
  static const R_BC = R_B;
  static const R_DE = R_D;
  static const R_HL = R_H;
  static const R_SP = R_S;
  static const R_IX = R_IX_H;
  static const R_IY = R_IY_H;
  static const R_AFt = R_At;
  static const R_BCt = R_Bt;
  static const R_DEt = R_Dt;
  static const R_HLt = R_Ht;

  static const F_CARRY = 0x01;
  static const F_ADD_SUB = 0x02;
  static const F_PARITY = 0x04;
  static const F_HALF_CARRY = 0x08;
  static const F_ZERO = 0x10;
  static const F_SIGN = 0x20;

  List<int> registers;

  Registers() {
    registers = List<int>.filled(R_COUNT, 0);
  }

  operator [](int i) => registers[i];
  operator []=(int i, int value) => registers[i] = value;

  int gw(int r) => 256 * registers[r] + registers[r + 1];
  void sw(int r, int w) {
    registers[r] = hi(w);
    registers[r + 1] = lo(w);
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
  int get AFt => gw(R_At);
  int get BCt => gw(R_Bt);
  int get DEt => gw(R_Dt);
  int get HLt => gw(R_Ht);

  set AF(int w) => sw(R_A, w);
  set BC(int w) => sw(R_B, w);
  set DE(int w) => sw(R_D, w);
  set HL(int w) => sw(R_H, w);
  set SP(int w) => sw(R_S, w);
  set IX(int w) => sw(R_IX_H, w);
  set IY(int w) => sw(R_IY_H, w);
  set AFt(int w) => sw(R_At, w);
  set BCt(int w) => sw(R_Bt, w);
  set DEt(int w) => sw(R_Dt, w);
  set HLt(int w) => sw(R_Ht, w);

  bool get carryFlag => F & F_CARRY != 0;
  bool get addSubtractFlag => F & F_ADD_SUB != 0;
  bool get parityOverflowFlag => F & F_PARITY != 0;
  bool get halfCarryFlag => F & F_HALF_CARRY != 0;
  bool get zeroFlag => F & F_ZERO != 0;
  bool get signFlag => F & F_SIGN != 0;

  set carryFlag(bool b) => F = b ? F | F_CARRY : F & ~F_CARRY;
  set addSubtractFlag(bool b) => F = b ? F | F_ADD_SUB : F & ~F_ADD_SUB;
  set parityOverflowFlag(bool b) => F = b ? F | F_PARITY : F & ~F_PARITY;
  set halfCarryFlag(bool b) => F = b ? F | F_HALF_CARRY : F & ~F_HALF_CARRY;
  set zeroFlag(bool b) => F = b ? F | F_ZERO : F & ~F_ZERO;
  set signFlag(bool b) => F = b ? F | F_SIGN : F & ~F_SIGN;
}
