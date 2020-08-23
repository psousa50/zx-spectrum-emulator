import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Z80a.dart';
import 'Scenarios.dart';

var allScenarios = [
  ...nop(0x00),
  ...ldR16A(0x02, Z80a.R_BC),
  ...ldR16A(0x12, Z80a.R_DE),
  ...ldAR16(0x0A, Z80a.R_BC),
  ...ldAR16(0x1A, Z80a.R_DE),
  ...exAFAFt(0x08),
  ...ldR8NN(0x06, Z80a.R_B),
  ...ldR8NN(0x0E, Z80a.R_C),
  ...ldR8NN(0x16, Z80a.R_D),
  ...ldR8NN(0x1E, Z80a.R_E),
  ...ldR8NN(0x26, Z80a.R_H),
  ...ldR8NN(0x2E, Z80a.R_L),
  ...ldR8NN(0x3E, Z80a.R_A),
  ...ldR8MHL(0x46, Z80a.R_B),
  ...ldR8MHL(0x4E, Z80a.R_C),
  ...ldR8MHL(0x56, Z80a.R_D),
  ...ldR8MHL(0x5E, Z80a.R_E),
  ...ldR8MHL(0x66, Z80a.R_H),
  ...ldR8MHL(0x6E, Z80a.R_L),
  ...ldR8MHL(0x7E, Z80a.R_A),
  ...ldMHLR8(0x70, Z80a.R_B),
  ...ldMHLR8(0x70, Z80a.R_B),
  ...ldMHLR8(0x71, Z80a.R_C),
  ...ldMHLR8(0x72, Z80a.R_D),
  ...ldMHLR8(0x73, Z80a.R_E),
  ...ldMHLH(0x74),
  ...ldMHLL(0x75),
  ...ldMHLR8(0x77, Z80a.R_A),
  ...ldMNNHL(0x22),
  ...ldHLMNN(0x2A),
  ...ldMNNA(0x32),
  ...ldAMNN(0x3A),
  ...ldMHLN(0x36),
  ...ldR16NN(0x01, Z80a.R_BC),
  ...ldR16NN(0x11, Z80a.R_DE),
  ...ldR16NN(0x21, Z80a.R_HL),
  ...ldR16NN(0x31, Z80a.R_SP),
  ...addHLR16(0x09, Z80a.R_HL, Z80a.R_BC),
  ...addHLR16(0x19, Z80a.R_HL, Z80a.R_DE),
  ...addHLHL(0x29, Z80a.R_HL),
  ...addHLR16(0x39, Z80a.R_HL, Z80a.R_SP),
  ...incR16(0x03, Z80a.R_BC),
  ...incR16(0x13, Z80a.R_DE),
  ...incR16(0x23, Z80a.R_HL),
  ...incR16(0x33, Z80a.R_SP),
  ...decR16(0x0B, Z80a.R_BC),
  ...decR16(0x1B, Z80a.R_DE),
  ...decR16(0x2B, Z80a.R_HL),
  ...decR16(0x3B, Z80a.R_SP),
  ...incR8(0x04, Z80a.R_B),
  ...incR8(0x0C, Z80a.R_C),
  ...incR8(0x14, Z80a.R_D),
  ...incR8(0x1C, Z80a.R_E),
  ...incR8(0x24, Z80a.R_H),
  ...incR8(0x2C, Z80a.R_L),
  ...incR8(0x34, Z80a.R_MHL),
  ...incR8(0x3C, Z80a.R_A),
  ...decR8(0x05, Z80a.R_B),
  ...decR8(0x0D, Z80a.R_C),
  ...decR8(0x15, Z80a.R_D),
  ...decR8(0x1D, Z80a.R_E),
  ...decR8(0x25, Z80a.R_H),
  ...decR8(0x2D, Z80a.R_L),
  ...decR8(0x35, Z80a.R_MHL),
  ...decR8(0x3D, Z80a.R_A),
  ...rlca(0x07),
  ...rrca(0x0F),
  ...rla(0x17),
  ...rra(0x1F),
  ...cpl(0x2F),
  ...scf(0x37),
  ...ccf(0x3F),
  ...ldR8R8(0x40, Z80a.R_B, Z80a.R_B),
  ...ldR8R8(0x41, Z80a.R_B, Z80a.R_C),
  ...ldR8R8(0x42, Z80a.R_B, Z80a.R_D),
  ...ldR8R8(0x43, Z80a.R_B, Z80a.R_E),
  ...ldR8R8(0x44, Z80a.R_B, Z80a.R_H),
  ...ldR8R8(0x45, Z80a.R_B, Z80a.R_L),
  ...ldR8R8(0x47, Z80a.R_B, Z80a.R_A),
  ...ldR8R8(0x48, Z80a.R_C, Z80a.R_B),
  ...ldR8R8(0x49, Z80a.R_C, Z80a.R_C),
  ...ldR8R8(0x4A, Z80a.R_C, Z80a.R_D),
  ...ldR8R8(0x4B, Z80a.R_C, Z80a.R_E),
  ...ldR8R8(0x4C, Z80a.R_C, Z80a.R_H),
  ...ldR8R8(0x4D, Z80a.R_C, Z80a.R_L),
  ...ldR8R8(0x4F, Z80a.R_C, Z80a.R_A),
  ...ldR8R8(0x50, Z80a.R_D, Z80a.R_B),
  ...ldR8R8(0x51, Z80a.R_D, Z80a.R_C),
  ...ldR8R8(0x52, Z80a.R_D, Z80a.R_D),
  ...ldR8R8(0x53, Z80a.R_D, Z80a.R_E),
  ...ldR8R8(0x54, Z80a.R_D, Z80a.R_H),
  ...ldR8R8(0x55, Z80a.R_D, Z80a.R_L),
  ...ldR8R8(0x57, Z80a.R_D, Z80a.R_A),
  ...ldR8R8(0x58, Z80a.R_E, Z80a.R_B),
  ...ldR8R8(0x59, Z80a.R_E, Z80a.R_C),
  ...ldR8R8(0x5A, Z80a.R_E, Z80a.R_D),
  ...ldR8R8(0x5B, Z80a.R_E, Z80a.R_E),
  ...ldR8R8(0x5C, Z80a.R_E, Z80a.R_H),
  ...ldR8R8(0x5D, Z80a.R_E, Z80a.R_L),
  ...ldR8R8(0x5F, Z80a.R_E, Z80a.R_A),
  ...ldR8R8(0x60, Z80a.R_H, Z80a.R_B),
  ...ldR8R8(0x61, Z80a.R_H, Z80a.R_C),
  ...ldR8R8(0x62, Z80a.R_H, Z80a.R_D),
  ...ldR8R8(0x63, Z80a.R_H, Z80a.R_E),
  ...ldR8R8(0x64, Z80a.R_H, Z80a.R_H),
  ...ldR8R8(0x65, Z80a.R_H, Z80a.R_L),
  ...ldR8R8(0x67, Z80a.R_H, Z80a.R_A),
  ...ldR8R8(0x68, Z80a.R_L, Z80a.R_B),
  ...ldR8R8(0x69, Z80a.R_L, Z80a.R_C),
  ...ldR8R8(0x6A, Z80a.R_L, Z80a.R_D),
  ...ldR8R8(0x6B, Z80a.R_L, Z80a.R_E),
  ...ldR8R8(0x6C, Z80a.R_L, Z80a.R_H),
  ...ldR8R8(0x6D, Z80a.R_L, Z80a.R_L),
  ...ldR8R8(0x6F, Z80a.R_L, Z80a.R_A),
  ...ldR8R8(0x78, Z80a.R_A, Z80a.R_B),
  ...ldR8R8(0x79, Z80a.R_A, Z80a.R_C),
  ...ldR8R8(0x7A, Z80a.R_A, Z80a.R_D),
  ...ldR8R8(0x7B, Z80a.R_A, Z80a.R_E),
  ...ldR8R8(0x7C, Z80a.R_A, Z80a.R_H),
  ...ldR8R8(0x7D, Z80a.R_A, Z80a.R_L),
  ...ldR8R8(0x7F, Z80a.R_A, Z80a.R_A),
  ...addAR8(0x80, Z80a.R_B),
  ...addAR8(0x81, Z80a.R_C),
  ...addAR8(0x82, Z80a.R_D),
  ...addAR8(0x83, Z80a.R_E),
  ...addAR8(0x84, Z80a.R_H),
  ...addAR8(0x85, Z80a.R_L),
  ...addAR8(0x86, Z80a.R_MHL),
  ...addAR8(0x87, Z80a.R_A),
  ...adcAR8(0x88, Z80a.R_B),
  ...adcAR8(0x89, Z80a.R_C),
  ...adcAR8(0x8A, Z80a.R_D),
  ...adcAR8(0x8B, Z80a.R_E),
  ...adcAR8(0x8C, Z80a.R_H),
  ...adcAR8(0x8D, Z80a.R_L),
  ...adcAR8(0x8E, Z80a.R_MHL),
  ...adcAR8(0x8F, Z80a.R_A),
  ...subAR8(0x90, Z80a.R_B),
  ...subAR8(0x91, Z80a.R_C),
  ...subAR8(0x92, Z80a.R_D),
  ...subAR8(0x93, Z80a.R_E),
  ...subAR8(0x94, Z80a.R_H),
  ...subAR8(0x95, Z80a.R_L),
  ...subAR8(0x96, Z80a.R_MHL),
  ...subAR8(0x97, Z80a.R_A),
  ...sbcAR8(0x98, Z80a.R_B),
  ...sbcAR8(0x99, Z80a.R_C),
  ...sbcAR8(0x9A, Z80a.R_D),
  ...sbcAR8(0x9B, Z80a.R_E),
  ...sbcAR8(0x9C, Z80a.R_H),
  ...sbcAR8(0x9D, Z80a.R_L),
  ...sbcAR8(0x9E, Z80a.R_MHL),
  ...sbcAR8(0x9F, Z80a.R_A),
  ...andR8(0xA0, Z80a.R_B),
  ...andR8(0xA1, Z80a.R_C),
  ...andR8(0xA2, Z80a.R_D),
  ...andR8(0xA3, Z80a.R_E),
  ...andR8(0xA4, Z80a.R_H),
  ...andR8(0xA5, Z80a.R_L),
  ...andR8(0xA6, Z80a.R_MHL),
  ...andR8(0xA7, Z80a.R_A),
  ...xorR8(0xA8, Z80a.R_B),
  ...xorR8(0xA9, Z80a.R_C),
  ...xorR8(0xAA, Z80a.R_D),
  ...xorR8(0xAB, Z80a.R_E),
  ...xorR8(0xAC, Z80a.R_H),
  ...xorR8(0xAD, Z80a.R_L),
  ...xorR8(0xAE, Z80a.R_MHL),
  ...xorR8(0xAF, Z80a.R_A),
  ...orR8(0xB0, Z80a.R_B),
  ...orR8(0xB1, Z80a.R_C),
  ...orR8(0xB2, Z80a.R_D),
  ...orR8(0xB3, Z80a.R_E),
  ...orR8(0xB4, Z80a.R_H),
  ...orR8(0xB5, Z80a.R_L),
  ...orR8(0xB6, Z80a.R_MHL),
  ...andR8(0xA7, Z80a.R_A),
  ...cpR8(0xB8, Z80a.R_B),
  ...cpR8(0xB9, Z80a.R_C),
  ...cpR8(0xBA, Z80a.R_D),
  ...cpR8(0xBB, Z80a.R_E),
  ...cpR8(0xBC, Z80a.R_H),
  ...cpR8(0xBD, Z80a.R_L),
  ...cpR8(0xBE, Z80a.R_MHL),
  ...cpR8(0xBF, Z80a.R_A),
  ...addAN(0xC6),
  ...adcAN(0xCE),
  ...subAN(0xD6),
  ...sbcAN(0xDE),
  ...andAN(0xE6),
  ...xorN(0xEE),
  ...orN(0xF6),
  ...cpN(0xFE),
  ...callNN(0xCD),
  ...callCCNN(0xC4, "Z", false),
  ...callCCNN(0xCC, "Z", true),
  ...callCCNN(0xD4, "C", false),
  ...callCCNN(0xDC, "C", true),
  ...callCCNN(0xE4, "P", false),
  ...callCCNN(0xEC, "P", true),
  ...callCCNN(0xF4, "S", false),
  ...callCCNN(0xFC, "S", true),
  ...ret(0xC9),
  ...retCC(0xC0, "Z", false),
  ...retCC(0xC8, "Z", true),
  ...retCC(0xD0, "C", false),
  ...retCC(0xD8, "C", true),
  ...retCC(0xE0, "P", false),
  ...retCC(0xE8, "P", true),
  ...retCC(0xF0, "S", false),
  ...retCC(0xF8, "S", true),
  ...jpCCNN(0xC2, "Z", false),
  ...jpCCNN(0xCA, "Z", true),
  ...jpCCNN(0xD2, "C", false),
  ...jpCCNN(0xDA, "C", true),
  ...jpCCNN(0xE2, "P", false),
  ...jpCCNN(0xEA, "P", true),
  ...jpCCNN(0xF2, "S", false),
  ...jpCCNN(0xFA, "S", true),
  ...jpNN(0xC3),
  ...pushR16(0xC5, Z80a.R_BC),
  ...pushR16(0xD5, Z80a.R_DE),
  ...pushR16(0xE5, Z80a.R_HL),
  ...pushR16(0xF5, Z80a.R_AF),
  ...popR16(0xC1, Z80a.R_BC),
  ...popR16(0xD1, Z80a.R_DE),
  ...popR16(0xE1, Z80a.R_HL),
  ...popR16(0xF1, Z80a.R_AF),
  ...rstNN(0xC7, 00),
  ...rstNN(0xCF, 08),
  ...rstNN(0xD7, 16),
  ...rstNN(0xDF, 24),
  ...rstNN(0xE7, 32),
  ...rstNN(0xEF, 40),
  ...rstNN(0xF7, 48),
  ...rstNN(0xFF, 56),
  ...exx(0xD9),
  ...djnzN(0x10),
  ...jrN(0x18),
  ...jrCCNN(0x20, "Z", false),
  ...jrCCNN(0x28, "Z", true),
  ...jrCCNN(0x30, "C", false),
  ...jrCCNN(0x38, "C", true),
  ...exMSPHL(0xE3, Z80a.R_HL),
  ...jpMHL(0xE9, Z80a.R_HL),
  ...exDEHL(0xEB),
  ...ldSPHL(0xF9, Z80a.R_HL),
  ...outNA(0xD3),
  ...inAN(0xDB),

// IX IY
  ...incR8(0x34, Z80a.R_MIXd),
  ...incR8(0x34, Z80a.R_MIYd),
  ...decR8(0x35, Z80a.R_MIXd),
  ...decR8(0x35, Z80a.R_MIYd),
  ...addHLR16(0x09, Z80a.R_IX, Z80a.R_BC),
  ...addHLR16(0x19, Z80a.R_IX, Z80a.R_DE),
  ...addHLHL(0x29, Z80a.R_IX),
  ...addHLR16(0x39, Z80a.R_IX, Z80a.R_SP),
  ...addHLR16(0x09, Z80a.R_IY, Z80a.R_BC),
  ...addHLR16(0x19, Z80a.R_IY, Z80a.R_DE),
  ...addHLHL(0x29, Z80a.R_IY),
  ...addHLR16(0x39, Z80a.R_IY, Z80a.R_SP),
  ...ldIXYNN(0x21, Z80a.R_IX),
  ...ldIXYNN(0x21, Z80a.R_IY),
  ...ldMNNIXY(0x22, Z80a.R_IX),
  ...ldMNNIXY(0x22, Z80a.R_IY),
  ...incR16(0x23, Z80a.R_IX),
  ...incR16(0x23, Z80a.R_IY),
  ...decR16(0x2B, Z80a.R_IX),
  ...decR16(0x2B, Z80a.R_IY),
  ...ldIXYMN(0x2A, Z80a.R_IX),
  ...ldIXYMN(0x2A, Z80a.R_IY),
  ...ldMIXYdN(0x36, Z80a.R_IX),
  ...ldMIXYdN(0x36, Z80a.R_IY),
  ...ldR8MIXYd(0x46, Z80a.R_B, Z80a.R_IX),
  ...ldR8MIXYd(0x4E, Z80a.R_C, Z80a.R_IX),
  ...ldR8MIXYd(0x56, Z80a.R_D, Z80a.R_IX),
  ...ldR8MIXYd(0x5E, Z80a.R_E, Z80a.R_IX),
  ...ldR8MIXYd(0x66, Z80a.R_H, Z80a.R_IX),
  ...ldR8MIXYd(0x6E, Z80a.R_L, Z80a.R_IX),
  ...ldR8MIXYd(0x46, Z80a.R_B, Z80a.R_IY),
  ...ldR8MIXYd(0x4E, Z80a.R_C, Z80a.R_IY),
  ...ldR8MIXYd(0x56, Z80a.R_D, Z80a.R_IY),
  ...ldR8MIXYd(0x5E, Z80a.R_E, Z80a.R_IY),
  ...ldR8MIXYd(0x66, Z80a.R_H, Z80a.R_IY),
  ...ldR8MIXYd(0x6E, Z80a.R_L, Z80a.R_IY),
  ...ldMIXYdR8(0x70, Z80a.R_B, Z80a.R_IX),
  ...ldMIXYdR8(0x71, Z80a.R_C, Z80a.R_IX),
  ...ldMIXYdR8(0x72, Z80a.R_D, Z80a.R_IX),
  ...ldMIXYdR8(0x73, Z80a.R_E, Z80a.R_IX),
  ...ldMIXYdR8(0x74, Z80a.R_H, Z80a.R_IX),
  ...ldMIXYdR8(0x75, Z80a.R_L, Z80a.R_IX),
  ...ldMIXYdR8(0x77, Z80a.R_A, Z80a.R_IX),
  ...ldMIXYdR8(0x70, Z80a.R_B, Z80a.R_IY),
  ...ldMIXYdR8(0x71, Z80a.R_C, Z80a.R_IY),
  ...ldMIXYdR8(0x72, Z80a.R_D, Z80a.R_IY),
  ...ldMIXYdR8(0x73, Z80a.R_E, Z80a.R_IY),
  ...ldMIXYdR8(0x74, Z80a.R_H, Z80a.R_IY),
  ...ldMIXYdR8(0x75, Z80a.R_L, Z80a.R_IY),
  ...ldMIXYdR8(0x77, Z80a.R_A, Z80a.R_IY),
  ...addAR8(0x86, Z80a.R_MIXd),
  ...addAR8(0x86, Z80a.R_MIYd),
  ...adcAR8(0x8E, Z80a.R_MIXd),
  ...adcAR8(0x8E, Z80a.R_MIYd),
  ...subAR8(0x96, Z80a.R_MIXd),
  ...subAR8(0x96, Z80a.R_MIYd),
  ...sbcAR8(0x9E, Z80a.R_MIXd),
  ...sbcAR8(0x9E, Z80a.R_MIYd),
  ...andR8(0xA6, Z80a.R_MIXd),
  ...andR8(0xA6, Z80a.R_MIYd),
  ...xorR8(0xAE, Z80a.R_MIXd),
  ...xorR8(0xAE, Z80a.R_MIYd),
  ...orR8(0xB6, Z80a.R_MIXd),
  ...orR8(0xB6, Z80a.R_MIYd),
  ...cpR8(0xBE, Z80a.R_MIXd),
  ...cpR8(0xBE, Z80a.R_MIYd),
  ...popR16(0xE1, Z80a.R_IX),
  ...popR16(0xE1, Z80a.R_IY),
  ...pushR16(0xE5, Z80a.R_IX),
  ...pushR16(0xE5, Z80a.R_IY),
  ...jpMHL(0xE9, Z80a.R_IX),
  ...jpMHL(0xE9, Z80a.R_IY),
  ...exMSPHL(0xE3, Z80a.R_IX),
  ...exMSPHL(0xE3, Z80a.R_IY),
  ...ldSPHL(0xF9, Z80a.R_IX),
  ...ldSPHL(0xF9, Z80a.R_IY),

  // Extended

  ...inR8C(0x40, Z80a.R_B),
  ...inR8C(0x48, Z80a.R_C),
  ...inR8C(0x50, Z80a.R_D),
  ...inR8C(0x58, Z80a.R_E),
  ...inR8C(0x60, Z80a.R_H),
  ...inR8C(0x68, Z80a.R_L),
  ...inR8C(0x78, Z80a.R_A),
  ...outCR8(0x41, Z80a.R_B),
  ...outCR8(0x49, Z80a.R_C),
  ...outCR8(0x51, Z80a.R_D),
  ...outCR8(0x59, Z80a.R_E),
  ...outCR8(0x61, Z80a.R_H),
  ...outCR8(0x69, Z80a.R_L),
  ...outCR8(0x79, Z80a.R_A),
  ...sbcHLR16(0x42, Z80a.R_BC),
  ...sbcHLR16(0x52, Z80a.R_DE),
  ...sbcHLR16(0x62, Z80a.R_HL),
  ...sbcHLR16(0x72, Z80a.R_SP),
  ...adcHLR16(0x4A, Z80a.R_BC),
  ...adcHLR16(0x5A, Z80a.R_DE),
  ...adcHLR16(0x6A, Z80a.R_HL),
  ...adcHLR16(0x7A, Z80a.R_SP),

  // CB

  ...rlcR8(0x00, Z80a.R_B),
  ...rlcR8(0x01, Z80a.R_C),
  ...rlcR8(0x02, Z80a.R_D),
  ...rlcR8(0x03, Z80a.R_E),
  ...rlcR8(0x04, Z80a.R_H),
  ...rlcR8(0x05, Z80a.R_L),
  ...rlcR8(0x06, Z80a.R_MHL),
  ...rlcR8(0x07, Z80a.R_A),

  ...rrcR8(0x08, Z80a.R_B),
  ...rrcR8(0x09, Z80a.R_C),
  ...rrcR8(0x0A, Z80a.R_D),
  ...rrcR8(0x0B, Z80a.R_E),
  ...rrcR8(0x0C, Z80a.R_H),
  ...rrcR8(0x0D, Z80a.R_L),
  ...rrcR8(0x0E, Z80a.R_MHL),
  ...rrcR8(0x0F, Z80a.R_A),

  ...rlR8(0x10, Z80a.R_B),
  ...rlR8(0x11, Z80a.R_C),
  ...rlR8(0x12, Z80a.R_D),
  ...rlR8(0x13, Z80a.R_E),
  ...rlR8(0x14, Z80a.R_H),
  ...rlR8(0x15, Z80a.R_L),
  ...rlR8(0x16, Z80a.R_MHL),
  ...rlR8(0x17, Z80a.R_A),

  ...rrR8(0x18, Z80a.R_B),
  ...rrR8(0x19, Z80a.R_C),
  ...rrR8(0x1A, Z80a.R_D),
  ...rrR8(0x1B, Z80a.R_E),
  ...rrR8(0x1C, Z80a.R_H),
  ...rrR8(0x1D, Z80a.R_L),
  ...rrR8(0x1E, Z80a.R_MHL),
  ...rrR8(0x1F, Z80a.R_A),

  ...slaR8(0x20, Z80a.R_B),
  ...slaR8(0x21, Z80a.R_C),
  ...slaR8(0x22, Z80a.R_D),
  ...slaR8(0x23, Z80a.R_E),
  ...slaR8(0x24, Z80a.R_H),
  ...slaR8(0x25, Z80a.R_L),
  ...slaR8(0x26, Z80a.R_MHL),
  ...slaR8(0x27, Z80a.R_A),

  ...sraR8(0x28, Z80a.R_B),
  ...sraR8(0x29, Z80a.R_C),
  ...sraR8(0x2A, Z80a.R_D),
  ...sraR8(0x2B, Z80a.R_E),
  ...sraR8(0x2C, Z80a.R_H),
  ...sraR8(0x2D, Z80a.R_L),
  ...sraR8(0x2E, Z80a.R_MHL),
  ...sraR8(0x2F, Z80a.R_A),

  ...srlR8(0x38, Z80a.R_B),
  ...srlR8(0x39, Z80a.R_C),
  ...srlR8(0x3A, Z80a.R_D),
  ...srlR8(0x3B, Z80a.R_E),
  ...srlR8(0x3C, Z80a.R_H),
  ...srlR8(0x3D, Z80a.R_L),
  ...srlR8(0x3E, Z80a.R_MHL),
  ...srlR8(0x3F, Z80a.R_A),

  // BIT n, R8
  ...bit0R8(0x40, Z80a.R_B),
  ...bit0R8(0x41, Z80a.R_C),
  ...bit0R8(0x42, Z80a.R_D),
  ...bit0R8(0x43, Z80a.R_E),
  ...bit0R8(0x44, Z80a.R_H),
  ...bit0R8(0x45, Z80a.R_L),
  ...bit0R8(0x46, Z80a.R_MHL),
  ...bit0R8(0x46, Z80a.R_MIXd),
  ...bit0R8(0x46, Z80a.R_MIYd),
  ...bit0R8(0x47, Z80a.R_A),

  ...bit1R8(0x48, Z80a.R_B),
  ...bit1R8(0x49, Z80a.R_C),
  ...bit1R8(0x4A, Z80a.R_D),
  ...bit1R8(0x4B, Z80a.R_E),
  ...bit1R8(0x4C, Z80a.R_H),
  ...bit1R8(0x4D, Z80a.R_L),
  ...bit1R8(0x4E, Z80a.R_MHL),
  ...bit1R8(0x4E, Z80a.R_MIXd),
  ...bit1R8(0x4E, Z80a.R_MIYd),
  ...bit1R8(0x4F, Z80a.R_A),

  ...bit2R8(0x50, Z80a.R_B),
  ...bit2R8(0x51, Z80a.R_C),
  ...bit2R8(0x52, Z80a.R_D),
  ...bit2R8(0x53, Z80a.R_E),
  ...bit2R8(0x54, Z80a.R_H),
  ...bit2R8(0x55, Z80a.R_L),
  ...bit2R8(0x56, Z80a.R_MHL),
  ...bit2R8(0x56, Z80a.R_MIXd),
  ...bit2R8(0x56, Z80a.R_MIYd),
  ...bit2R8(0x57, Z80a.R_A),

  ...bit3R8(0x58, Z80a.R_B),
  ...bit3R8(0x59, Z80a.R_C),
  ...bit3R8(0x5A, Z80a.R_D),
  ...bit3R8(0x5B, Z80a.R_E),
  ...bit3R8(0x5C, Z80a.R_H),
  ...bit3R8(0x5D, Z80a.R_L),
  ...bit3R8(0x5E, Z80a.R_MHL),
  ...bit3R8(0x5E, Z80a.R_MIXd),
  ...bit3R8(0x5E, Z80a.R_MIYd),
  ...bit3R8(0x5F, Z80a.R_A),

  ...bit4R8(0x60, Z80a.R_B),
  ...bit4R8(0x61, Z80a.R_C),
  ...bit4R8(0x62, Z80a.R_D),
  ...bit4R8(0x63, Z80a.R_E),
  ...bit4R8(0x64, Z80a.R_H),
  ...bit4R8(0x65, Z80a.R_L),
  ...bit4R8(0x66, Z80a.R_MHL),
  ...bit4R8(0x66, Z80a.R_MIXd),
  ...bit4R8(0x66, Z80a.R_MIYd),
  ...bit4R8(0x67, Z80a.R_A),

  ...bit5R8(0x68, Z80a.R_B),
  ...bit5R8(0x69, Z80a.R_C),
  ...bit5R8(0x6A, Z80a.R_D),
  ...bit5R8(0x6B, Z80a.R_E),
  ...bit5R8(0x6C, Z80a.R_H),
  ...bit5R8(0x6D, Z80a.R_L),
  ...bit5R8(0x6E, Z80a.R_MHL),
  ...bit5R8(0x6E, Z80a.R_MIXd),
  ...bit5R8(0x6E, Z80a.R_MIYd),
  ...bit5R8(0x6F, Z80a.R_A),

  ...bit6R8(0x70, Z80a.R_B),
  ...bit6R8(0x71, Z80a.R_C),
  ...bit6R8(0x72, Z80a.R_D),
  ...bit6R8(0x73, Z80a.R_E),
  ...bit6R8(0x74, Z80a.R_H),
  ...bit6R8(0x75, Z80a.R_L),
  ...bit6R8(0x76, Z80a.R_MHL),
  ...bit6R8(0x76, Z80a.R_MIXd),
  ...bit6R8(0x76, Z80a.R_MIYd),
  ...bit6R8(0x77, Z80a.R_A),

  ...bit7R8(0x78, Z80a.R_B),
  ...bit7R8(0x79, Z80a.R_C),
  ...bit7R8(0x7A, Z80a.R_D),
  ...bit7R8(0x7B, Z80a.R_E),
  ...bit7R8(0x7C, Z80a.R_H),
  ...bit7R8(0x7D, Z80a.R_L),
  ...bit7R8(0x7E, Z80a.R_MHL),
  ...bit7R8(0x7E, Z80a.R_MIXd),
  ...bit7R8(0x7E, Z80a.R_MIYd),
  ...bit7R8(0x7F, Z80a.R_A),

  // RES n, R8
  ...res0R8(0x80, Z80a.R_B),
  ...res0R8(0x81, Z80a.R_C),
  ...res0R8(0x82, Z80a.R_D),
  ...res0R8(0x83, Z80a.R_E),
  ...res0R8(0x84, Z80a.R_H),
  ...res0R8(0x85, Z80a.R_L),
  ...res0R8(0x86, Z80a.R_MHL),
  ...res0R8(0x86, Z80a.R_MIXd),
  ...res0R8(0x86, Z80a.R_MIYd),
  ...res0R8(0x87, Z80a.R_A),

  ...res1R8(0x88, Z80a.R_B),
  ...res1R8(0x89, Z80a.R_C),
  ...res1R8(0x8A, Z80a.R_D),
  ...res1R8(0x8B, Z80a.R_E),
  ...res1R8(0x8C, Z80a.R_H),
  ...res1R8(0x8D, Z80a.R_L),
  ...res1R8(0x8E, Z80a.R_MHL),
  ...res1R8(0x8E, Z80a.R_MIXd),
  ...res1R8(0x8E, Z80a.R_MIYd),
  ...res1R8(0x8F, Z80a.R_A),

  ...res2R8(0x90, Z80a.R_B),
  ...res2R8(0x91, Z80a.R_C),
  ...res2R8(0x92, Z80a.R_D),
  ...res2R8(0x93, Z80a.R_E),
  ...res2R8(0x94, Z80a.R_H),
  ...res2R8(0x95, Z80a.R_L),
  ...res2R8(0x96, Z80a.R_MHL),
  ...res2R8(0x96, Z80a.R_MIXd),
  ...res2R8(0x96, Z80a.R_MIYd),
  ...res2R8(0x97, Z80a.R_A),

  ...res3R8(0x98, Z80a.R_B),
  ...res3R8(0x99, Z80a.R_C),
  ...res3R8(0x9A, Z80a.R_D),
  ...res3R8(0x9B, Z80a.R_E),
  ...res3R8(0x9C, Z80a.R_H),
  ...res3R8(0x9D, Z80a.R_L),
  ...res3R8(0x9E, Z80a.R_MHL),
  ...res3R8(0x9E, Z80a.R_MIXd),
  ...res3R8(0x9E, Z80a.R_MIYd),
  ...res3R8(0x9F, Z80a.R_A),

  ...res4R8(0xA0, Z80a.R_B),
  ...res4R8(0xA1, Z80a.R_C),
  ...res4R8(0xA2, Z80a.R_D),
  ...res4R8(0xA3, Z80a.R_E),
  ...res4R8(0xA4, Z80a.R_H),
  ...res4R8(0xA5, Z80a.R_L),
  ...res4R8(0xA6, Z80a.R_MHL),
  ...res4R8(0xA6, Z80a.R_MIXd),
  ...res4R8(0xA6, Z80a.R_MIYd),
  ...res4R8(0xA7, Z80a.R_A),

  ...res5R8(0xA8, Z80a.R_B),
  ...res5R8(0xA9, Z80a.R_C),
  ...res5R8(0xAA, Z80a.R_D),
  ...res5R8(0xAB, Z80a.R_E),
  ...res5R8(0xAC, Z80a.R_H),
  ...res5R8(0xAD, Z80a.R_L),
  ...res5R8(0xAE, Z80a.R_MHL),
  ...res5R8(0xAE, Z80a.R_MIXd),
  ...res5R8(0xAE, Z80a.R_MIYd),
  ...res5R8(0xAF, Z80a.R_A),

  ...res6R8(0xB0, Z80a.R_B),
  ...res6R8(0xB1, Z80a.R_C),
  ...res6R8(0xB2, Z80a.R_D),
  ...res6R8(0xB3, Z80a.R_E),
  ...res6R8(0xB4, Z80a.R_H),
  ...res6R8(0xB5, Z80a.R_L),
  ...res6R8(0xB6, Z80a.R_MHL),
  ...res6R8(0xB6, Z80a.R_MIXd),
  ...res6R8(0xB6, Z80a.R_MIYd),
  ...res6R8(0xB7, Z80a.R_A),

  ...res7R8(0xB8, Z80a.R_B),
  ...res7R8(0xB9, Z80a.R_C),
  ...res7R8(0xBA, Z80a.R_D),
  ...res7R8(0xBB, Z80a.R_E),
  ...res7R8(0xBC, Z80a.R_H),
  ...res7R8(0xBD, Z80a.R_L),
  ...res7R8(0xBE, Z80a.R_MHL),
  ...res7R8(0xBE, Z80a.R_MIXd),
  ...res7R8(0xBE, Z80a.R_MIYd),
  ...res7R8(0xBF, Z80a.R_A),

  // SET n, R8
  ...set0R8(0xC0, Z80a.R_B),
  ...set0R8(0xC1, Z80a.R_C),
  ...set0R8(0xC2, Z80a.R_D),
  ...set0R8(0xC3, Z80a.R_E),
  ...set0R8(0xC4, Z80a.R_H),
  ...set0R8(0xC5, Z80a.R_L),
  ...set0R8(0xC6, Z80a.R_MHL),
  ...set0R8(0xC6, Z80a.R_MIXd),
  ...set0R8(0xC6, Z80a.R_MIYd),
  ...set0R8(0xC7, Z80a.R_A),

  ...set1R8(0xC8, Z80a.R_B),
  ...set1R8(0xC9, Z80a.R_C),
  ...set1R8(0xCA, Z80a.R_D),
  ...set1R8(0xCB, Z80a.R_E),
  ...set1R8(0xCC, Z80a.R_H),
  ...set1R8(0xCD, Z80a.R_L),
  ...set1R8(0xCE, Z80a.R_MHL),
  ...set1R8(0xCE, Z80a.R_MIXd),
  ...set1R8(0xCE, Z80a.R_MIYd),
  ...set1R8(0xCF, Z80a.R_A),

  ...set2R8(0xD0, Z80a.R_B),
  ...set2R8(0xD1, Z80a.R_C),
  ...set2R8(0xD2, Z80a.R_D),
  ...set2R8(0xD3, Z80a.R_E),
  ...set2R8(0xD4, Z80a.R_H),
  ...set2R8(0xD5, Z80a.R_L),
  ...set2R8(0xD6, Z80a.R_MHL),
  ...set2R8(0xD6, Z80a.R_MIXd),
  ...set2R8(0xD6, Z80a.R_MIYd),
  ...set2R8(0xD7, Z80a.R_A),

  ...set3R8(0xD8, Z80a.R_B),
  ...set3R8(0xD9, Z80a.R_C),
  ...set3R8(0xDA, Z80a.R_D),
  ...set3R8(0xDB, Z80a.R_E),
  ...set3R8(0xDC, Z80a.R_H),
  ...set3R8(0xDD, Z80a.R_L),
  ...set3R8(0xDE, Z80a.R_MHL),
  ...set3R8(0xDE, Z80a.R_MIXd),
  ...set3R8(0xDE, Z80a.R_MIYd),
  ...set3R8(0xDF, Z80a.R_A),

  ...set4R8(0xE0, Z80a.R_B),
  ...set4R8(0xE1, Z80a.R_C),
  ...set4R8(0xE2, Z80a.R_D),
  ...set4R8(0xE3, Z80a.R_E),
  ...set4R8(0xE4, Z80a.R_H),
  ...set4R8(0xE5, Z80a.R_L),
  ...set4R8(0xE6, Z80a.R_MHL),
  ...set4R8(0xE6, Z80a.R_MIXd),
  ...set4R8(0xE6, Z80a.R_MIYd),
  ...set4R8(0xE7, Z80a.R_A),

  ...set5R8(0xE8, Z80a.R_B),
  ...set5R8(0xE9, Z80a.R_C),
  ...set5R8(0xEA, Z80a.R_D),
  ...set5R8(0xEB, Z80a.R_E),
  ...set5R8(0xEC, Z80a.R_H),
  ...set5R8(0xED, Z80a.R_L),
  ...set5R8(0xEE, Z80a.R_MHL),
  ...set5R8(0xEE, Z80a.R_MIXd),
  ...set5R8(0xEE, Z80a.R_MIYd),
  ...set5R8(0xEF, Z80a.R_A),

  ...set6R8(0xF0, Z80a.R_B),
  ...set6R8(0xF1, Z80a.R_C),
  ...set6R8(0xF2, Z80a.R_D),
  ...set6R8(0xF3, Z80a.R_E),
  ...set6R8(0xF4, Z80a.R_H),
  ...set6R8(0xF5, Z80a.R_L),
  ...set6R8(0xF6, Z80a.R_MHL),
  ...set6R8(0xF6, Z80a.R_MIXd),
  ...set6R8(0xF6, Z80a.R_MIYd),
  ...set6R8(0xF7, Z80a.R_A),

  ...set7R8(0xF8, Z80a.R_B),
  ...set7R8(0xF9, Z80a.R_C),
  ...set7R8(0xFA, Z80a.R_D),
  ...set7R8(0xFB, Z80a.R_E),
  ...set7R8(0xFC, Z80a.R_H),
  ...set7R8(0xFD, Z80a.R_L),
  ...set7R8(0xFE, Z80a.R_MHL),
  ...set7R8(0xFE, Z80a.R_MIXd),
  ...set7R8(0xFE, Z80a.R_MIYd),
  ...set7R8(0xFF, Z80a.R_A),
];

void main() {
  const runAll = true;

  test('All Scenarios', () {
    allScenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: !runAll);

  test('One Scenario', () {
    print("RUNNING ONLY ONE SCENARIO");
    var scenarios = adcHLR16(0x4A, Z80a.R_BC);
    scenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: runAll);
}
