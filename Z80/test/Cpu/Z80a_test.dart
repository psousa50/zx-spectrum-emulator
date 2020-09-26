import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:Z80/Cpu/Registers.dart';
import 'package:Z80/Cpu/Z80Assembler.dart';
import 'package:Z80/Util.dart';
import 'package:Z80/Cpu/Z80.dart';
import '../MemoryTest.dart';
import '../PortsTest.dart';
import '../Scenarios.dart';

var allScenarios = [
  ...nop(0x00),
  ...ldR16A(0x02, Registers.R_BC),
  ...ldR16A(0x12, Registers.R_DE),
  ...ldAR16(0x0A, Registers.R_BC),
  ...ldAR16(0x1A, Registers.R_DE),
  ...exAFAFt(0x08),
  ...ldR8N(0x06, Registers.R_B),
  ...ldR8N(0x0E, Registers.R_C),
  ...ldR8N(0x16, Registers.R_D),
  ...ldR8N(0x1E, Registers.R_E),
  ...ldR8N(0x26, Registers.R_H),
  ...ldR8N(0x2E, Registers.R_L),
  ...ldR8N(0x3E, Registers.R_A),
  ...ldR8MHL(0x46, Registers.R_B),
  ...ldR8MHL(0x4E, Registers.R_C),
  ...ldR8MHL(0x56, Registers.R_D),
  ...ldR8MHL(0x5E, Registers.R_E),
  ...ldR8MHL(0x66, Registers.R_H),
  ...ldR8MHL(0x6E, Registers.R_L),
  ...ldR8MHL(0x7E, Registers.R_A),
  ...ldMHLR8(0x70, Registers.R_B),
  ...ldMHLR8(0x70, Registers.R_B),
  ...ldMHLR8(0x71, Registers.R_C),
  ...ldMHLR8(0x72, Registers.R_D),
  ...ldMHLR8(0x73, Registers.R_E),
  ...ldMHLH(0x74),
  ...ldMHLL(0x75),
  ...ldMHLR8(0x77, Registers.R_A),
  ...ldMNNR16(0x22, Registers.R_HL),
  ...ldR16MNN(0x2A, Registers.R_HL),
  ...ldMNNA(0x32),
  ...ldAMNN(0x3A),
  ...ldMHLN(0x36),
  ...ldR16NN(0x01, Registers.R_BC),
  ...ldR16NN(0x11, Registers.R_DE),
  ...ldR16NN(0x21, Registers.R_HL),
  ...ldR16NN(0x31, Registers.R_SP),
  ...addHLR16(0x09, Registers.R_HL, Registers.R_BC),
  ...addHLR16(0x19, Registers.R_HL, Registers.R_DE),
  ...addHLHL(0x29, Registers.R_HL),
  ...addHLR16(0x39, Registers.R_HL, Registers.R_SP),
  ...incR16(0x03, Registers.R_BC),
  ...incR16(0x13, Registers.R_DE),
  ...incR16(0x23, Registers.R_HL),
  ...incR16(0x33, Registers.R_SP),
  ...decR16(0x0B, Registers.R_BC),
  ...decR16(0x1B, Registers.R_DE),
  ...decR16(0x2B, Registers.R_HL),
  ...decR16(0x3B, Registers.R_SP),
  ...incR8(0x04, Registers.R_B),
  ...incR8(0x0C, Registers.R_C),
  ...incR8(0x14, Registers.R_D),
  ...incR8(0x1C, Registers.R_E),
  ...incR8(0x24, Registers.R_H),
  ...incR8(0x2C, Registers.R_L),
  ...incR8(0x34, Registers.R_MHL),
  ...incR8(0x3C, Registers.R_A),
  ...decR8(0x05, Registers.R_B),
  ...decR8(0x0D, Registers.R_C),
  ...decR8(0x15, Registers.R_D),
  ...decR8(0x1D, Registers.R_E),
  ...decR8(0x25, Registers.R_H),
  ...decR8(0x2D, Registers.R_L),
  ...decR8(0x35, Registers.R_MHL),
  ...decR8(0x3D, Registers.R_A),
  ...rlca(0x07),
  ...rrca(0x0F),
  ...rla(0x17),
  ...rra(0x1F),
  ...cpl(0x2F),
  ...scf(0x37),
  ...ccf(0x3F),
  ...ldR8R8(0x40, Registers.R_B, Registers.R_B),
  ...ldR8R8(0x41, Registers.R_B, Registers.R_C),
  ...ldR8R8(0x42, Registers.R_B, Registers.R_D),
  ...ldR8R8(0x43, Registers.R_B, Registers.R_E),
  ...ldR8R8(0x44, Registers.R_B, Registers.R_H),
  ...ldR8R8(0x45, Registers.R_B, Registers.R_L),
  ...ldR8R8(0x47, Registers.R_B, Registers.R_A),
  ...ldR8R8(0x48, Registers.R_C, Registers.R_B),
  ...ldR8R8(0x49, Registers.R_C, Registers.R_C),
  ...ldR8R8(0x4A, Registers.R_C, Registers.R_D),
  ...ldR8R8(0x4B, Registers.R_C, Registers.R_E),
  ...ldR8R8(0x4C, Registers.R_C, Registers.R_H),
  ...ldR8R8(0x4D, Registers.R_C, Registers.R_L),
  ...ldR8R8(0x4F, Registers.R_C, Registers.R_A),
  ...ldR8R8(0x50, Registers.R_D, Registers.R_B),
  ...ldR8R8(0x51, Registers.R_D, Registers.R_C),
  ...ldR8R8(0x52, Registers.R_D, Registers.R_D),
  ...ldR8R8(0x53, Registers.R_D, Registers.R_E),
  ...ldR8R8(0x54, Registers.R_D, Registers.R_H),
  ...ldR8R8(0x55, Registers.R_D, Registers.R_L),
  ...ldR8R8(0x57, Registers.R_D, Registers.R_A),
  ...ldR8R8(0x58, Registers.R_E, Registers.R_B),
  ...ldR8R8(0x59, Registers.R_E, Registers.R_C),
  ...ldR8R8(0x5A, Registers.R_E, Registers.R_D),
  ...ldR8R8(0x5B, Registers.R_E, Registers.R_E),
  ...ldR8R8(0x5C, Registers.R_E, Registers.R_H),
  ...ldR8R8(0x5D, Registers.R_E, Registers.R_L),
  ...ldR8R8(0x5F, Registers.R_E, Registers.R_A),
  ...ldR8R8(0x60, Registers.R_H, Registers.R_B),
  ...ldR8R8(0x61, Registers.R_H, Registers.R_C),
  ...ldR8R8(0x62, Registers.R_H, Registers.R_D),
  ...ldR8R8(0x63, Registers.R_H, Registers.R_E),
  ...ldR8R8(0x64, Registers.R_H, Registers.R_H),
  ...ldR8R8(0x65, Registers.R_H, Registers.R_L),
  ...ldR8R8(0x67, Registers.R_H, Registers.R_A),
  ...ldR8R8(0x68, Registers.R_L, Registers.R_B),
  ...ldR8R8(0x69, Registers.R_L, Registers.R_C),
  ...ldR8R8(0x6A, Registers.R_L, Registers.R_D),
  ...ldR8R8(0x6B, Registers.R_L, Registers.R_E),
  ...ldR8R8(0x6C, Registers.R_L, Registers.R_H),
  ...ldR8R8(0x6D, Registers.R_L, Registers.R_L),
  ...ldR8R8(0x6F, Registers.R_L, Registers.R_A),
  ...ldR8R8(0x78, Registers.R_A, Registers.R_B),
  ...ldR8R8(0x79, Registers.R_A, Registers.R_C),
  ...ldR8R8(0x7A, Registers.R_A, Registers.R_D),
  ...ldR8R8(0x7B, Registers.R_A, Registers.R_E),
  ...ldR8R8(0x7C, Registers.R_A, Registers.R_H),
  ...ldR8R8(0x7D, Registers.R_A, Registers.R_L),
  ...ldR8R8(0x7F, Registers.R_A, Registers.R_A),
  ...addAR8(0x80, Registers.R_B),
  ...addAR8(0x81, Registers.R_C),
  ...addAR8(0x82, Registers.R_D),
  ...addAR8(0x83, Registers.R_E),
  ...addAR8(0x84, Registers.R_H),
  ...addAR8(0x85, Registers.R_L),
  ...addAR8(0x86, Registers.R_MHL),
  ...addAR8(0x87, Registers.R_A),
  ...adcAR8(0x88, Registers.R_B),
  ...adcAR8(0x89, Registers.R_C),
  ...adcAR8(0x8A, Registers.R_D),
  ...adcAR8(0x8B, Registers.R_E),
  ...adcAR8(0x8C, Registers.R_H),
  ...adcAR8(0x8D, Registers.R_L),
  ...adcAR8(0x8E, Registers.R_MHL),
  ...adcAR8(0x8F, Registers.R_A),
  ...subAR8(0x90, Registers.R_B),
  ...subAR8(0x91, Registers.R_C),
  ...subAR8(0x92, Registers.R_D),
  ...subAR8(0x93, Registers.R_E),
  ...subAR8(0x94, Registers.R_H),
  ...subAR8(0x95, Registers.R_L),
  ...subAR8(0x96, Registers.R_MHL),
  ...subAR8(0x97, Registers.R_A),
  ...sbcAR8(0x98, Registers.R_B),
  ...sbcAR8(0x99, Registers.R_C),
  ...sbcAR8(0x9A, Registers.R_D),
  ...sbcAR8(0x9B, Registers.R_E),
  ...sbcAR8(0x9C, Registers.R_H),
  ...sbcAR8(0x9D, Registers.R_L),
  ...sbcAR8(0x9E, Registers.R_MHL),
  ...sbcAR8(0x9F, Registers.R_A),
  ...andR8(0xA0, Registers.R_B),
  ...andR8(0xA1, Registers.R_C),
  ...andR8(0xA2, Registers.R_D),
  ...andR8(0xA3, Registers.R_E),
  ...andR8(0xA4, Registers.R_H),
  ...andR8(0xA5, Registers.R_L),
  ...andR8(0xA6, Registers.R_MHL),
  ...andR8(0xA7, Registers.R_A),
  ...xorR8(0xA8, Registers.R_B),
  ...xorR8(0xA9, Registers.R_C),
  ...xorR8(0xAA, Registers.R_D),
  ...xorR8(0xAB, Registers.R_E),
  ...xorR8(0xAC, Registers.R_H),
  ...xorR8(0xAD, Registers.R_L),
  ...xorR8(0xAE, Registers.R_MHL),
  ...xorR8(0xAF, Registers.R_A),
  ...orR8(0xB0, Registers.R_B),
  ...orR8(0xB1, Registers.R_C),
  ...orR8(0xB2, Registers.R_D),
  ...orR8(0xB3, Registers.R_E),
  ...orR8(0xB4, Registers.R_H),
  ...orR8(0xB5, Registers.R_L),
  ...orR8(0xB6, Registers.R_MHL),
  ...andR8(0xA7, Registers.R_A),
  ...cpR8(0xB8, Registers.R_B),
  ...cpR8(0xB9, Registers.R_C),
  ...cpR8(0xBA, Registers.R_D),
  ...cpR8(0xBB, Registers.R_E),
  ...cpR8(0xBC, Registers.R_H),
  ...cpR8(0xBD, Registers.R_L),
  ...cpR8(0xBE, Registers.R_MHL),
  ...cpR8(0xBF, Registers.R_A),
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
  ...pushR16(0xC5, Registers.R_BC),
  ...pushR16(0xD5, Registers.R_DE),
  ...pushR16(0xE5, Registers.R_HL),
  ...pushR16(0xF5, Registers.R_AF),
  ...popR16(0xC1, Registers.R_BC),
  ...popR16(0xD1, Registers.R_DE),
  ...popR16(0xE1, Registers.R_HL),
  ...popR16(0xF1, Registers.R_AF),
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
  ...exMSPHL(0xE3, Registers.R_HL),
  ...jpMHL(0xE9, Registers.R_HL),
  ...exDEHL(0xEB),
  ...ldSPHL(0xF9, Registers.R_HL),
  ...outNA(0xD3),
  ...inAN(0xDB),

// IX IY
  ...incR8(0x24, Registers.R_IX_H),
  ...decR8(0x25, Registers.R_IX_H),

  ...incR8(0x24, Registers.R_IY_H),
  ...decR8(0x25, Registers.R_IY_H),

  ...ldR8N(0x26, Registers.R_IX_H),
  ...ldR8N(0x26, Registers.R_IY_H),

  ...incR8(0x2C, Registers.R_IX_L),
  ...decR8(0x2D, Registers.R_IX_L),

  ...ldR8N(0x2E, Registers.R_IX_L),
  ...ldR8N(0x2E, Registers.R_IY_L),

  ...incR8(0x34, Registers.R_MIXd),
  ...incR8(0x34, Registers.R_MIYd),
  ...decR8(0x35, Registers.R_MIXd),
  ...decR8(0x35, Registers.R_MIYd),
  ...addHLR16(0x09, Registers.R_IX, Registers.R_BC),
  ...addHLR16(0x19, Registers.R_IX, Registers.R_DE),
  ...addHLHL(0x29, Registers.R_IX),
  ...addHLR16(0x39, Registers.R_IX, Registers.R_SP),
  ...addHLR16(0x09, Registers.R_IY, Registers.R_BC),
  ...addHLR16(0x19, Registers.R_IY, Registers.R_DE),
  ...addHLHL(0x29, Registers.R_IY),
  ...addHLR16(0x39, Registers.R_IY, Registers.R_SP),
  ...ldIXYNN(0x21, Registers.R_IX),
  ...ldIXYNN(0x21, Registers.R_IY),
  ...ldMNNIXY(0x22, Registers.R_IX),
  ...ldMNNIXY(0x22, Registers.R_IY),
  ...incR16(0x23, Registers.R_IX),
  ...incR16(0x23, Registers.R_IY),
  ...decR16(0x2B, Registers.R_IX),
  ...decR16(0x2B, Registers.R_IY),
  ...ldIXYMN(0x2A, Registers.R_IX),
  ...ldIXYMN(0x2A, Registers.R_IY),
  ...ldMIXYdN(0x36, Registers.R_IX),
  ...ldMIXYdN(0x36, Registers.R_IY),

  ...ldR8R8(0x44, Registers.R_B, Registers.R_IX_H),
  ...ldR8R8(0x4C, Registers.R_C, Registers.R_IX_H),
  ...ldR8R8(0x54, Registers.R_D, Registers.R_IX_H),
  ...ldR8R8(0x5C, Registers.R_E, Registers.R_IX_H),
  ...ldR8R8(0x64, Registers.R_IX_H, Registers.R_IX_H),
  ...ldR8R8(0x6C, Registers.R_IX_L, Registers.R_IX_H),

  ...ldR8R8(0x45, Registers.R_B, Registers.R_IX_L),
  ...ldR8R8(0x4D, Registers.R_C, Registers.R_IX_L),
  ...ldR8R8(0x55, Registers.R_D, Registers.R_IX_L),
  ...ldR8R8(0x5D, Registers.R_E, Registers.R_IX_L),
  ...ldR8R8(0x65, Registers.R_IX_H, Registers.R_IX_L),
  ...ldR8R8(0x6D, Registers.R_IX_L, Registers.R_IX_L),

  ...ldR8R8(0x60, Registers.R_IX_H, Registers.R_B),
  ...ldR8R8(0x61, Registers.R_IX_H, Registers.R_C),
  ...ldR8R8(0x62, Registers.R_IX_H, Registers.R_D),
  ...ldR8R8(0x63, Registers.R_IX_H, Registers.R_E),
  ...ldR8R8(0x64, Registers.R_IX_H, Registers.R_IX_H),
  ...ldR8R8(0x65, Registers.R_IX_H, Registers.R_IX_L),
  ...ldR8R8(0x67, Registers.R_IX_H, Registers.R_A),

  ...ldR8R8(0x44, Registers.R_B, Registers.R_IY_H),
  ...ldR8R8(0x4C, Registers.R_C, Registers.R_IY_H),
  ...ldR8R8(0x54, Registers.R_D, Registers.R_IY_H),
  ...ldR8R8(0x5C, Registers.R_E, Registers.R_IY_H),
  ...ldR8R8(0x64, Registers.R_IY_H, Registers.R_IY_H),
  ...ldR8R8(0x6C, Registers.R_IY_L, Registers.R_IY_H),

  ...ldR8R8(0x45, Registers.R_B, Registers.R_IY_L),
  ...ldR8R8(0x4D, Registers.R_C, Registers.R_IY_L),
  ...ldR8R8(0x55, Registers.R_D, Registers.R_IY_L),
  ...ldR8R8(0x5D, Registers.R_E, Registers.R_IY_L),
  ...ldR8R8(0x65, Registers.R_IY_H, Registers.R_IY_L),
  ...ldR8R8(0x6D, Registers.R_IY_L, Registers.R_IY_L),

  ...ldR8R8(0x60, Registers.R_IY_H, Registers.R_B),
  ...ldR8R8(0x61, Registers.R_IY_H, Registers.R_C),
  ...ldR8R8(0x62, Registers.R_IY_H, Registers.R_D),
  ...ldR8R8(0x63, Registers.R_IY_H, Registers.R_E),
  ...ldR8R8(0x64, Registers.R_IY_H, Registers.R_IY_H),
  ...ldR8R8(0x65, Registers.R_IY_H, Registers.R_IY_L),
  ...ldR8R8(0x67, Registers.R_IY_H, Registers.R_A),

  ...ldR8R8(0x68, Registers.R_IX_L, Registers.R_B),
  ...ldR8R8(0x69, Registers.R_IX_L, Registers.R_C),
  ...ldR8R8(0x6A, Registers.R_IX_L, Registers.R_D),
  ...ldR8R8(0x6B, Registers.R_IX_L, Registers.R_E),
  ...ldR8R8(0x6C, Registers.R_IX_L, Registers.R_IX_H),
  ...ldR8R8(0x6D, Registers.R_IX_L, Registers.R_IX_L),
  ...ldR8R8(0x6F, Registers.R_IX_L, Registers.R_A),

  ...ldR8R8(0x7C, Registers.R_A, Registers.R_IX_H),
  ...ldR8R8(0x7D, Registers.R_A, Registers.R_IX_L),

  ...ldR8R8(0x7C, Registers.R_A, Registers.R_IY_H),
  ...ldR8R8(0x7D, Registers.R_A, Registers.R_IY_L),

  ...ldR8MIXYd(0x46, Registers.R_B, Registers.R_IX),
  ...ldR8MIXYd(0x4E, Registers.R_C, Registers.R_IX),
  ...ldR8MIXYd(0x56, Registers.R_D, Registers.R_IX),
  ...ldR8MIXYd(0x5E, Registers.R_E, Registers.R_IX),
  ...ldR8MIXYd(0x66, Registers.R_H, Registers.R_IX),
  ...ldR8MIXYd(0x6E, Registers.R_L, Registers.R_IX),
  ...ldR8MIXYd(0x7E, Registers.R_A, Registers.R_IX),
  ...ldR8MIXYd(0x46, Registers.R_B, Registers.R_IY),
  ...ldR8MIXYd(0x4E, Registers.R_C, Registers.R_IY),
  ...ldR8MIXYd(0x56, Registers.R_D, Registers.R_IY),
  ...ldR8MIXYd(0x5E, Registers.R_E, Registers.R_IY),
  ...ldR8MIXYd(0x66, Registers.R_H, Registers.R_IY),
  ...ldR8MIXYd(0x6E, Registers.R_L, Registers.R_IY),
  ...ldR8MIXYd(0x7E, Registers.R_A, Registers.R_IY),
  ...ldMIXYdR8(0x70, Registers.R_B, Registers.R_IX),
  ...ldMIXYdR8(0x71, Registers.R_C, Registers.R_IX),
  ...ldMIXYdR8(0x72, Registers.R_D, Registers.R_IX),
  ...ldMIXYdR8(0x73, Registers.R_E, Registers.R_IX),
  ...ldMIXYdR8(0x74, Registers.R_H, Registers.R_IX),
  ...ldMIXYdR8(0x75, Registers.R_L, Registers.R_IX),
  ...ldMIXYdR8(0x77, Registers.R_A, Registers.R_IX),
  ...ldMIXYdR8(0x70, Registers.R_B, Registers.R_IY),
  ...ldMIXYdR8(0x71, Registers.R_C, Registers.R_IY),
  ...ldMIXYdR8(0x72, Registers.R_D, Registers.R_IY),
  ...ldMIXYdR8(0x73, Registers.R_E, Registers.R_IY),
  ...ldMIXYdR8(0x74, Registers.R_H, Registers.R_IY),
  ...ldMIXYdR8(0x75, Registers.R_L, Registers.R_IY),
  ...ldMIXYdR8(0x77, Registers.R_A, Registers.R_IY),

  ...addAR8(0x84, Registers.R_IX_H),
  ...addAR8(0x85, Registers.R_IX_L),
  ...addAR8(0x86, Registers.R_MIXd),

  ...adcAR8(0x8C, Registers.R_IX_H),
  ...adcAR8(0x8D, Registers.R_IX_L),
  ...adcAR8(0x8E, Registers.R_MIXd),

  ...subAR8(0x94, Registers.R_IX_H),
  ...subAR8(0x95, Registers.R_IX_L),
  ...subAR8(0x96, Registers.R_MIXd),

  ...sbcAR8(0x9C, Registers.R_IX_H),
  ...sbcAR8(0x9D, Registers.R_IX_L),
  ...sbcAR8(0x9E, Registers.R_MIXd),

  ...andR8(0xA4, Registers.R_IX_H),
  ...andR8(0xA5, Registers.R_IX_L),
  ...andR8(0xA6, Registers.R_MIXd),

  ...xorR8(0xAC, Registers.R_IX_H),
  ...xorR8(0xAD, Registers.R_IX_L),
  ...xorR8(0xAE, Registers.R_MIXd),

  ...orR8(0xB4, Registers.R_IX_H),
  ...orR8(0xB5, Registers.R_IX_L),
  ...orR8(0xB6, Registers.R_MIXd),

  ...cpR8(0xBC, Registers.R_IX_H),
  ...cpR8(0xBD, Registers.R_IX_L),
  ...cpR8(0xBE, Registers.R_MIXd),

  ...addAR8(0x86, Registers.R_MIYd),
  ...adcAR8(0x8E, Registers.R_MIYd),
  ...subAR8(0x96, Registers.R_MIYd),
  ...sbcAR8(0x9E, Registers.R_MIYd),
  ...andR8(0xA6, Registers.R_MIYd),
  ...xorR8(0xAE, Registers.R_MIYd),
  ...orR8(0xB6, Registers.R_MIYd),
  ...cpR8(0xBE, Registers.R_MIYd),

  ...popR16(0xE1, Registers.R_IX),
  ...popR16(0xE1, Registers.R_IY),
  ...pushR16(0xE5, Registers.R_IX),
  ...pushR16(0xE5, Registers.R_IY),
  ...jpMHL(0xE9, Registers.R_IX),
  ...jpMHL(0xE9, Registers.R_IY),
  ...exMSPHL(0xE3, Registers.R_IX),
  ...exMSPHL(0xE3, Registers.R_IY),
  ...ldSPHL(0xF9, Registers.R_IX),
  ...ldSPHL(0xF9, Registers.R_IY),

  // Extended

  ...inR8C(0x40, Registers.R_B),
  ...inR8C(0x48, Registers.R_C),
  ...inR8C(0x50, Registers.R_D),
  ...inR8C(0x58, Registers.R_E),
  ...inR8C(0x60, Registers.R_H),
  ...inR8C(0x68, Registers.R_L),
  ...inR8C(0x78, Registers.R_A),
  ...outCR8(0x41, Registers.R_B),
  // ...outCR8(0x49, Registers.R_C),
  // ...outCR8(0x51, Registers.R_D),
  // ...outCR8(0x59, Registers.R_E),
  // ...outCR8(0x61, Registers.R_H),
  // ...outCR8(0x69, Registers.R_L),
  // ...outCR8(0x79, Registers.R_A),
  ...sbcHLR16(0x42, Registers.R_BC),
  ...sbcHLR16(0x52, Registers.R_DE),
  ...sbcHLR16(0x62, Registers.R_HL),
  ...sbcHLR16(0x72, Registers.R_SP),
  ...adcHLR16(0x4A, Registers.R_BC),
  ...adcHLR16(0x5A, Registers.R_DE),
  ...adcHLR16(0x6A, Registers.R_HL),
  ...adcHLR16(0x7A, Registers.R_SP),
  ...ldMNNR16(0x43, Registers.R_BC, prefix: Z80.EXTENDED_OPCODES),
  ...ldMNNR16(0x53, Registers.R_DE, prefix: Z80.EXTENDED_OPCODES),
  ...ldMNNR16(0x63, Registers.R_HL, prefix: Z80.EXTENDED_OPCODES),
  ...ldMNNR16(0x73, Registers.R_SP, prefix: Z80.EXTENDED_OPCODES),
  ...ldR16MNN(0x4B, Registers.R_BC, prefix: Z80.EXTENDED_OPCODES),
  ...ldR16MNN(0x5B, Registers.R_DE, prefix: Z80.EXTENDED_OPCODES),
  ...ldR16MNN(0x6B, Registers.R_HL, prefix: Z80.EXTENDED_OPCODES),
  ...ldR16MNN(0x7B, Registers.R_SP, prefix: Z80.EXTENDED_OPCODES),
  ...neg(0x44),
  ...neg(0x54),
  ...neg(0x64),
  ...neg(0x74),
  ...neg(0x4C),
  ...neg(0x5C),
  ...neg(0x6C),
  ...neg(0x7C),
  ...retn(0x45),
  ...retn(0x55),
  ...retn(0x65),
  ...retn(0x75),
  ...reti(0x4D),
  ...reti(0x5D),
  ...reti(0x6D),
  ...reti(0x7D),
  ...ldIA(0x47),
  ...ldAI(0x57),
  ...ldRA(0x4F),
  ...ldAR(0x5F),
  ...ldi(0xA0),
  ...ldd(0xA8),
  ...cpi(0xA1),
  ...cpd(0xA9),
  ...ini(0xA2),
  ...ind(0xAA),
  ...outi(0xA3),
  ...outd(0xAB),
  ...ldir(0xB0),
  ...lddr(0xB8),
  ...cpir(0xB1),
  ...cpdr(0xB9),
  ...inir(0xB2),
  ...indr(0xBA),
  ...otir(0xB3),
  ...otdr(0xBB),
  ...rrd(0x67),
  ...rld(0x6F),

  // CB

  ...rlcR8(0x00, Registers.R_B),
  ...rlcR8(0x01, Registers.R_C),
  ...rlcR8(0x02, Registers.R_D),
  ...rlcR8(0x03, Registers.R_E),
  ...rlcR8(0x04, Registers.R_H),
  ...rlcR8(0x05, Registers.R_L),
  ...rlcR8(0x06, Registers.R_MHL),
  ...rlcR8(0x06, Registers.R_MIXd),
  ...rlcR8(0x06, Registers.R_MIYd),
  ...rlcR8(0x07, Registers.R_A),

  ...rrcR8(0x08, Registers.R_B),
  ...rrcR8(0x09, Registers.R_C),
  ...rrcR8(0x0A, Registers.R_D),
  ...rrcR8(0x0B, Registers.R_E),
  ...rrcR8(0x0C, Registers.R_H),
  ...rrcR8(0x0D, Registers.R_L),
  ...rrcR8(0x0E, Registers.R_MHL),
  ...rrcR8(0x0E, Registers.R_MIXd),
  ...rrcR8(0x0E, Registers.R_MIYd),
  ...rrcR8(0x0F, Registers.R_A),

  ...rlR8(0x10, Registers.R_B),
  ...rlR8(0x11, Registers.R_C),
  ...rlR8(0x12, Registers.R_D),
  ...rlR8(0x13, Registers.R_E),
  ...rlR8(0x14, Registers.R_H),
  ...rlR8(0x15, Registers.R_L),
  ...rlR8(0x16, Registers.R_MHL),
  ...rlR8(0x16, Registers.R_MIXd),
  ...rlR8(0x16, Registers.R_MIYd),
  ...rlR8(0x17, Registers.R_A),

  ...rrR8(0x18, Registers.R_B),
  ...rrR8(0x19, Registers.R_C),
  ...rrR8(0x1A, Registers.R_D),
  ...rrR8(0x1B, Registers.R_E),
  ...rrR8(0x1C, Registers.R_H),
  ...rrR8(0x1D, Registers.R_L),
  ...rrR8(0x1E, Registers.R_MHL),
  ...rrR8(0x1E, Registers.R_MIXd),
  ...rrR8(0x1E, Registers.R_MIYd),
  ...rrR8(0x1F, Registers.R_A),

  ...slaR8(0x20, Registers.R_B),
  ...slaR8(0x21, Registers.R_C),
  ...slaR8(0x22, Registers.R_D),
  ...slaR8(0x23, Registers.R_E),
  ...slaR8(0x24, Registers.R_H),
  ...slaR8(0x25, Registers.R_L),
  ...slaR8(0x26, Registers.R_MHL),
  ...slaR8(0x26, Registers.R_MIXd),
  ...slaR8(0x26, Registers.R_MIYd),
  ...slaR8(0x27, Registers.R_A),

  ...sraR8(0x28, Registers.R_B),
  ...sraR8(0x29, Registers.R_C),
  ...sraR8(0x2A, Registers.R_D),
  ...sraR8(0x2B, Registers.R_E),
  ...sraR8(0x2C, Registers.R_H),
  ...sraR8(0x2D, Registers.R_L),
  ...sraR8(0x2E, Registers.R_MHL),
  ...sraR8(0x2E, Registers.R_MIXd),
  ...sraR8(0x2E, Registers.R_MIYd),
  ...sraR8(0x2F, Registers.R_A),

  ...srlR8(0x38, Registers.R_B),
  ...srlR8(0x39, Registers.R_C),
  ...srlR8(0x3A, Registers.R_D),
  ...srlR8(0x3B, Registers.R_E),
  ...srlR8(0x3C, Registers.R_H),
  ...srlR8(0x3D, Registers.R_L),
  ...srlR8(0x3E, Registers.R_MHL),
  ...srlR8(0x3E, Registers.R_MIXd),
  ...srlR8(0x3E, Registers.R_MIYd),
  ...srlR8(0x3F, Registers.R_A),

  // BIT n, R8
  ...bit0R8(0x40, Registers.R_B),
  ...bit0R8(0x41, Registers.R_C),
  ...bit0R8(0x42, Registers.R_D),
  ...bit0R8(0x43, Registers.R_E),
  ...bit0R8(0x44, Registers.R_H),
  ...bit0R8(0x45, Registers.R_L),
  ...bit0R8(0x46, Registers.R_MHL),
  ...bit0R8(0x46, Registers.R_MIXd),
  ...bit0R8(0x46, Registers.R_MIYd),
  ...bit0R8(0x47, Registers.R_A),

  ...bit1R8(0x48, Registers.R_B),
  ...bit1R8(0x49, Registers.R_C),
  ...bit1R8(0x4A, Registers.R_D),
  ...bit1R8(0x4B, Registers.R_E),
  ...bit1R8(0x4C, Registers.R_H),
  ...bit1R8(0x4D, Registers.R_L),
  ...bit1R8(0x4E, Registers.R_MHL),
  ...bit1R8(0x4E, Registers.R_MIXd),
  ...bit1R8(0x4E, Registers.R_MIYd),
  ...bit1R8(0x4F, Registers.R_A),

  ...bit2R8(0x50, Registers.R_B),
  ...bit2R8(0x51, Registers.R_C),
  ...bit2R8(0x52, Registers.R_D),
  ...bit2R8(0x53, Registers.R_E),
  ...bit2R8(0x54, Registers.R_H),
  ...bit2R8(0x55, Registers.R_L),
  ...bit2R8(0x56, Registers.R_MHL),
  ...bit2R8(0x56, Registers.R_MIXd),
  ...bit2R8(0x56, Registers.R_MIYd),
  ...bit2R8(0x57, Registers.R_A),

  ...bit3R8(0x58, Registers.R_B),
  ...bit3R8(0x59, Registers.R_C),
  ...bit3R8(0x5A, Registers.R_D),
  ...bit3R8(0x5B, Registers.R_E),
  ...bit3R8(0x5C, Registers.R_H),
  ...bit3R8(0x5D, Registers.R_L),
  ...bit3R8(0x5E, Registers.R_MHL),
  ...bit3R8(0x5E, Registers.R_MIXd),
  ...bit3R8(0x5E, Registers.R_MIYd),
  ...bit3R8(0x5F, Registers.R_A),

  ...bit4R8(0x60, Registers.R_B),
  ...bit4R8(0x61, Registers.R_C),
  ...bit4R8(0x62, Registers.R_D),
  ...bit4R8(0x63, Registers.R_E),
  ...bit4R8(0x64, Registers.R_H),
  ...bit4R8(0x65, Registers.R_L),
  ...bit4R8(0x66, Registers.R_MHL),
  ...bit4R8(0x66, Registers.R_MIXd),
  ...bit4R8(0x66, Registers.R_MIYd),
  ...bit4R8(0x67, Registers.R_A),

  ...bit5R8(0x68, Registers.R_B),
  ...bit5R8(0x69, Registers.R_C),
  ...bit5R8(0x6A, Registers.R_D),
  ...bit5R8(0x6B, Registers.R_E),
  ...bit5R8(0x6C, Registers.R_H),
  ...bit5R8(0x6D, Registers.R_L),
  ...bit5R8(0x6E, Registers.R_MHL),
  ...bit5R8(0x6E, Registers.R_MIXd),
  ...bit5R8(0x6E, Registers.R_MIYd),
  ...bit5R8(0x6F, Registers.R_A),

  ...bit6R8(0x70, Registers.R_B),
  ...bit6R8(0x71, Registers.R_C),
  ...bit6R8(0x72, Registers.R_D),
  ...bit6R8(0x73, Registers.R_E),
  ...bit6R8(0x74, Registers.R_H),
  ...bit6R8(0x75, Registers.R_L),
  ...bit6R8(0x76, Registers.R_MHL),
  ...bit6R8(0x76, Registers.R_MIXd),
  ...bit6R8(0x76, Registers.R_MIYd),
  ...bit6R8(0x77, Registers.R_A),

  ...bit7R8(0x78, Registers.R_B),
  ...bit7R8(0x79, Registers.R_C),
  ...bit7R8(0x7A, Registers.R_D),
  ...bit7R8(0x7B, Registers.R_E),
  ...bit7R8(0x7C, Registers.R_H),
  ...bit7R8(0x7D, Registers.R_L),
  ...bit7R8(0x7E, Registers.R_MHL),
  ...bit7R8(0x7E, Registers.R_MIXd),
  ...bit7R8(0x7E, Registers.R_MIYd),
  ...bit7R8(0x7F, Registers.R_A),

  // RES n, R8
  ...res0R8(0x80, Registers.R_B),
  ...res0R8(0x81, Registers.R_C),
  ...res0R8(0x82, Registers.R_D),
  ...res0R8(0x83, Registers.R_E),
  ...res0R8(0x84, Registers.R_H),
  ...res0R8(0x85, Registers.R_L),
  ...res0R8(0x86, Registers.R_MHL),
  ...res0R8(0x86, Registers.R_MIXd),
  ...res0R8(0x86, Registers.R_MIYd),
  ...res0R8(0x87, Registers.R_A),

  ...res1R8(0x88, Registers.R_B),
  ...res1R8(0x89, Registers.R_C),
  ...res1R8(0x8A, Registers.R_D),
  ...res1R8(0x8B, Registers.R_E),
  ...res1R8(0x8C, Registers.R_H),
  ...res1R8(0x8D, Registers.R_L),
  ...res1R8(0x8E, Registers.R_MHL),
  ...res1R8(0x8E, Registers.R_MIXd),
  ...res1R8(0x8E, Registers.R_MIYd),
  ...res1R8(0x8F, Registers.R_A),

  ...res2R8(0x90, Registers.R_B),
  ...res2R8(0x91, Registers.R_C),
  ...res2R8(0x92, Registers.R_D),
  ...res2R8(0x93, Registers.R_E),
  ...res2R8(0x94, Registers.R_H),
  ...res2R8(0x95, Registers.R_L),
  ...res2R8(0x96, Registers.R_MHL),
  ...res2R8(0x96, Registers.R_MIXd),
  ...res2R8(0x96, Registers.R_MIYd),
  ...res2R8(0x97, Registers.R_A),

  ...res3R8(0x98, Registers.R_B),
  ...res3R8(0x99, Registers.R_C),
  ...res3R8(0x9A, Registers.R_D),
  ...res3R8(0x9B, Registers.R_E),
  ...res3R8(0x9C, Registers.R_H),
  ...res3R8(0x9D, Registers.R_L),
  ...res3R8(0x9E, Registers.R_MHL),
  ...res3R8(0x9E, Registers.R_MIXd),
  ...res3R8(0x9E, Registers.R_MIYd),
  ...res3R8(0x9F, Registers.R_A),

  ...res4R8(0xA0, Registers.R_B),
  ...res4R8(0xA1, Registers.R_C),
  ...res4R8(0xA2, Registers.R_D),
  ...res4R8(0xA3, Registers.R_E),
  ...res4R8(0xA4, Registers.R_H),
  ...res4R8(0xA5, Registers.R_L),
  ...res4R8(0xA6, Registers.R_MHL),
  ...res4R8(0xA6, Registers.R_MIXd),
  ...res4R8(0xA6, Registers.R_MIYd),
  ...res4R8(0xA7, Registers.R_A),

  ...res5R8(0xA8, Registers.R_B),
  ...res5R8(0xA9, Registers.R_C),
  ...res5R8(0xAA, Registers.R_D),
  ...res5R8(0xAB, Registers.R_E),
  ...res5R8(0xAC, Registers.R_H),
  ...res5R8(0xAD, Registers.R_L),
  ...res5R8(0xAE, Registers.R_MHL),
  ...res5R8(0xAE, Registers.R_MIXd),
  ...res5R8(0xAE, Registers.R_MIYd),
  ...res5R8(0xAF, Registers.R_A),

  ...res6R8(0xB0, Registers.R_B),
  ...res6R8(0xB1, Registers.R_C),
  ...res6R8(0xB2, Registers.R_D),
  ...res6R8(0xB3, Registers.R_E),
  ...res6R8(0xB4, Registers.R_H),
  ...res6R8(0xB5, Registers.R_L),
  ...res6R8(0xB6, Registers.R_MHL),
  ...res6R8(0xB6, Registers.R_MIXd),
  ...res6R8(0xB6, Registers.R_MIYd),
  ...res6R8(0xB7, Registers.R_A),

  ...res7R8(0xB8, Registers.R_B),
  ...res7R8(0xB9, Registers.R_C),
  ...res7R8(0xBA, Registers.R_D),
  ...res7R8(0xBB, Registers.R_E),
  ...res7R8(0xBC, Registers.R_H),
  ...res7R8(0xBD, Registers.R_L),
  ...res7R8(0xBE, Registers.R_MHL),
  ...res7R8(0xBE, Registers.R_MIXd),
  ...res7R8(0xBE, Registers.R_MIYd),
  ...res7R8(0xBF, Registers.R_A),

  ...set0R8(0xC0, Registers.R_B),
  ...set0R8(0xC1, Registers.R_C),
  ...set0R8(0xC2, Registers.R_D),
  ...set0R8(0xC3, Registers.R_E),
  ...set0R8(0xC4, Registers.R_H),
  ...set0R8(0xC5, Registers.R_L),
  ...set0R8(0xC6, Registers.R_MHL),
  ...set0R8(0xC6, Registers.R_MIXd),
  ...set0R8(0xC6, Registers.R_MIYd),
  ...set0R8(0xC7, Registers.R_A),

  ...set1R8(0xC8, Registers.R_B),
  ...set1R8(0xC9, Registers.R_C),
  ...set1R8(0xCA, Registers.R_D),
  ...set1R8(0xCB, Registers.R_E),
  ...set1R8(0xCC, Registers.R_H),
  ...set1R8(0xCD, Registers.R_L),
  ...set1R8(0xCE, Registers.R_MHL),
  ...set1R8(0xCE, Registers.R_MIXd),
  ...set1R8(0xCE, Registers.R_MIYd),
  ...set1R8(0xCF, Registers.R_A),

  ...set2R8(0xD0, Registers.R_B),
  ...set2R8(0xD1, Registers.R_C),
  ...set2R8(0xD2, Registers.R_D),
  ...set2R8(0xD3, Registers.R_E),
  ...set2R8(0xD4, Registers.R_H),
  ...set2R8(0xD5, Registers.R_L),
  ...set2R8(0xD6, Registers.R_MHL),
  ...set2R8(0xD6, Registers.R_MIXd),
  ...set2R8(0xD6, Registers.R_MIYd),
  ...set2R8(0xD7, Registers.R_A),

  ...set3R8(0xD8, Registers.R_B),
  ...set3R8(0xD9, Registers.R_C),
  ...set3R8(0xDA, Registers.R_D),
  ...set3R8(0xDB, Registers.R_E),
  ...set3R8(0xDC, Registers.R_H),
  ...set3R8(0xDD, Registers.R_L),
  ...set3R8(0xDE, Registers.R_MHL),
  ...set3R8(0xDE, Registers.R_MIXd),
  ...set3R8(0xDE, Registers.R_MIYd),
  ...set3R8(0xDF, Registers.R_A),

  ...set4R8(0xE0, Registers.R_B),
  ...set4R8(0xE1, Registers.R_C),
  ...set4R8(0xE2, Registers.R_D),
  ...set4R8(0xE3, Registers.R_E),
  ...set4R8(0xE4, Registers.R_H),
  ...set4R8(0xE5, Registers.R_L),
  ...set4R8(0xE6, Registers.R_MHL),
  ...set4R8(0xE6, Registers.R_MIXd),
  ...set4R8(0xE6, Registers.R_MIYd),
  ...set4R8(0xE7, Registers.R_A),

  ...set5R8(0xE8, Registers.R_B),
  ...set5R8(0xE9, Registers.R_C),
  ...set5R8(0xEA, Registers.R_D),
  ...set5R8(0xEB, Registers.R_E),
  ...set5R8(0xEC, Registers.R_H),
  ...set5R8(0xED, Registers.R_L),
  ...set5R8(0xEE, Registers.R_MHL),
  ...set5R8(0xEE, Registers.R_MIXd),
  ...set5R8(0xEE, Registers.R_MIYd),
  ...set5R8(0xEF, Registers.R_A),

  ...set6R8(0xF0, Registers.R_B),
  ...set6R8(0xF1, Registers.R_C),
  ...set6R8(0xF2, Registers.R_D),
  ...set6R8(0xF3, Registers.R_E),
  ...set6R8(0xF4, Registers.R_H),
  ...set6R8(0xF5, Registers.R_L),
  ...set6R8(0xF6, Registers.R_MHL),
  ...set6R8(0xF6, Registers.R_MIXd),
  ...set6R8(0xF6, Registers.R_MIYd),
  ...set6R8(0xF7, Registers.R_A),

  ...set7R8(0xF8, Registers.R_B),
  ...set7R8(0xF9, Registers.R_C),
  ...set7R8(0xFA, Registers.R_D),
  ...set7R8(0xFB, Registers.R_E),
  ...set7R8(0xFC, Registers.R_H),
  ...set7R8(0xFD, Registers.R_L),
  ...set7R8(0xFE, Registers.R_MHL),
  ...set7R8(0xFE, Registers.R_MIXd),
  ...set7R8(0xFE, Registers.R_MIYd),
  ...set7R8(0xFF, Registers.R_A),
];

Z80 newCPU() {
  var z80 = Z80(MemoryTest(size: 1024), PortsTest());
  z80.registers.SP = 256;
  return z80;
}

void main() {
  const runAll = true;

  test("All Scenarios", () {
    allScenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: !runAll);

  test("One Scenario", () {
    print("RUNNING ONLY ONE SCENARIO");
    var scenarios = ldR8R8(0x60, Registers.R_IX_H, Registers.R_B);
    scenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: runAll);

  void testDAA(String op, int a, int n, int result) {
    var z80 = newCPU();
    z80.registers.A = a;
    var opcode = op == "ADD" ? 0xC6 : 0xD6;
    z80.memory.poke(0, opcode);
    z80.memory.poke(1, n);
    z80.memory.poke(2, 0x27);
    z80.step();
    z80.step();
    expect(z80.registers.A, result,
        reason:
            "A has wrong value after DAA (${toHex(a)} + ${toHex(n)} = ${toHex(result)})");
  }

  test("DAA", () {
    testDAA("ADD", 0x15, 0x13, 0x28);
    testDAA("ADD", 0x15, 0x27, 0x42);
    testDAA("SUB", 0x28, 0x13, 0x15);
    testDAA("SUB", 0x42, 0x27, 0x15);
  }, skip: false);

  test("Check hi and low register pairs", () {
    var z80 = newCPU();

    z80.registers.A = 200;
    z80.registers.F = 100;
    expect(z80.registers.AF, 256 * 200 + 100, reason: "AF is wrong");

    z80.registers.B = 200;
    z80.registers.C = 100;
    expect(z80.registers.BC, 256 * 200 + 100, reason: "BC is wrong");

    z80.registers.D = 200;
    z80.registers.E = 100;
    expect(z80.registers.DE, 256 * 200 + 100, reason: "DE is wrong");

    z80.registers.H = 200;
    z80.registers.L = 100;
    expect(z80.registers.HL, 256 * 200 + 100, reason: "HL is wrong");

    z80.registers.IX_H = 200;
    z80.registers.IX_L = 100;
    expect(z80.registers.IX, 256 * 200 + 100, reason: "IX is wrong");

    z80.registers.IY_H = 200;
    z80.registers.IY_L = 100;
    expect(z80.registers.IY, 256 * 200 + 100, reason: "IY is wrong");
  }, skip: runAll);

  test("DI, EI", () {
    var z80 = newCPU();
    expect(z80.interruptsEnabled, false);
    z80.memory.poke(0, 0xFB);
    z80.step();
    expect(z80.interruptsEnabled, true);
    z80.memory.poke(1, 0xF3);
    z80.step();
    expect(z80.interruptsEnabled, false);
  }, skip: !runAll);

  test("Halt", () {
    var z80 = newCPU();
    z80.memory.poke(0, 0x00);
    z80.step();
    expect(z80.PC, 0x01);
    z80.memory.poke(1, 0x76);
    z80.memory.poke(2, 0x00);
    z80.step();
    z80.step();
    expect(z80.PC, 0x02);
    expect(z80.PC, 0x02);
  }, skip: !runAll);

  test("Instruction returns T states", () {
    var z80 = Z80(MemoryTest(size: 20), PortsTest());
    var tStates = 0;

    z80.PC = 0;
    z80.memory.setRange(0, Z80Assembler.ldR8R8(Registers.R_A, Registers.R_L));
    tStates = z80.step();
    expect(tStates, 4, reason: "LD A, L => T states should be 4");

    z80.PC = 0;
    z80.memory.setRange(0, Z80Assembler.ldR8R8(Registers.R_A, Registers.R_MHL));
    tStates = z80.step();
    expect(tStates, 7, reason: "LD A, (HL) => T states should be 7");

    z80.PC = 0;
    z80.registers.zeroFlag = false;
    z80.memory.poke(0, 0xCC); // CALL Z
    tStates = z80.step();
    expect(tStates, 10, reason: "CALL NZ => On no call T states should be 10");

    z80.PC = 0;
    z80.registers.SP = 10;
    z80.registers.zeroFlag = true;
    z80.memory.poke(0, 0xCC); // CALL Z
    tStates = z80.step();
    expect(tStates, 17, reason: "CALL NZ => On call T states should be 17");
  }, skip: !runAll);

  test("Interrupt mode 0", () {
    var z80 = newCPU();
    z80.memory.setRange(0, Z80Assembler.im0());
    z80.step();
    expect(z80.interruptMode, InterruptMode.im0);
  }, skip: !runAll);

  test("Interrupt mode 1", () {
    var z80 = newCPU();
    z80.memory.setRange(0, Z80Assembler.im1());
    z80.step();
    expect(z80.interruptMode, InterruptMode.im1);
  }, skip: !runAll);

  test("Interrupt mode 2", () {
    var z80 = newCPU();
    z80.memory.setRange(0, Z80Assembler.im2());
    z80.step();
    expect(z80.interruptMode, InterruptMode.im2);
  }, skip: !runAll);

  test("Maskable interrupts - disabled", () {
    var z80 = newCPU();
    z80.PC = 400;
    z80.memory.setRange(z80.PC, Z80Assembler.di());
    z80.step();
    z80.maskableInterrupt();
    expect(z80.PC, 401);
  }, skip: !runAll);

  test("Maskable interrupts - mode 1", () {
    var z80 = newCPU();
    z80.PC = 400;
    z80.registers.SP = 128;
    z80.memory.setRange(z80.PC, Z80Assembler.ei());
    z80.memory.setRange(z80.PC + 1, Z80Assembler.im1());
    z80.step();
    z80.step();
    z80.maskableInterrupt();
    expect(z80.interruptsEnabled, false);
    expect(z80.memory.peek2(128 - 2), 400 + 3);
    expect(z80.registers.SP, 128 - 2);
    expect(z80.PC, 0x38);
  }, skip: !runAll);

  test("Maskable interrupts - mode 2", () {
    var z80 = newCPU();
    z80.PC = 400;
    z80.registers.SP = 128;
    z80.registers.I = 2;
    var address = 256 * z80.registers.I + 254;
    z80.memory.poke2(address, 12345);
    z80.memory.setRange(z80.PC, Z80Assembler.ei());
    z80.memory.setRange(z80.PC + 1, Z80Assembler.im2());
    z80.step();
    z80.step();
    z80.maskableInterrupt();
    expect(z80.interruptsEnabled, false);
    expect(z80.memory.peek2(128 - 2), 400 + 3);
    expect(z80.registers.SP, 128 - 2);
    expect(z80.PC, 12345);
  }, skip: !runAll);

  test("Maskable interrupts disabled 'Halt'", () {
    var z80 = newCPU();
    var program = Uint8List.fromList([
      ...Z80Assembler.im1(),
      ...Z80Assembler.ei(),
      ...Z80Assembler.halt(),
    ]);
    z80.memory.setRange(z80.PC, program);
    z80.step();
    z80.step();
    z80.step();
    expect(z80.halted, true, reason: "CPU should be halted");
    expect(z80.interruptsEnabled, true, reason: "Interrupts should be enabled");
    z80.maskableInterrupt();
    expect(z80.halted, false, reason: "CPU should NOT be halted");
    expect(z80.interruptsEnabled, false,
        reason: "Interrupts should NOT be enabled");
  }, skip: !runAll);

  test("BIT 5, (IY+2)", () {
    var z80 = newCPU();
    var opcodes = Uint8List.fromList([0xFD, 0xCB, 0x02, 0x6E]);
    z80.memory.setRange(z80.PC, opcodes);
    z80.registers.IY = 10;
    z80.memory.poke(z80.registers.IY + 2, binary("11011111"));
    z80.step();
    expect(z80.registers.zeroFlag, true);
  }, skip: !runAll);

  test("LD B, (IY+2)", () {
    var z80 = newCPU();
    var opcodes = Uint8List.fromList([0xFD, 0x46, 0x02]);
    z80.memory.setRange(z80.PC, opcodes);
    z80.registers.IY = 10;
    z80.memory.poke(z80.registers.IY + 2, 123);
    z80.step();
    expect(z80.registers.B, 123);
  }, skip: !runAll);

  group("Refresh Register", () {
    test("Increase by 1 for unprefixed opcodes", () {
      var z80 = newCPU();
      z80.memory.setRange(z80.PC, Z80Assembler.jr(2));
      z80.step();
      expect(z80.registers.R, 1);
    }, skip: !runAll);

    test("Increase by 2 for bit opcodes", () {
      var z80 = newCPU();
      z80.memory.setRange(z80.PC, Z80Assembler.bitBR8(0, Registers.R_B));
      z80.step();
      expect(z80.registers.R, 2);
    }, skip: !runAll);

    test("Increase by 2 for IXY opcodes", () {
      var z80 = newCPU();
      z80.memory.setRange(z80.PC, Z80Assembler.ldIXnn(12345));
      z80.step();
      expect(z80.registers.R, 2);
    }, skip: !runAll);

    test("Increase by 2 for IXY bit opcodes", () {
      var z80 = newCPU();
      z80.memory.setRange(z80.PC, Z80Assembler.bitBIXd(2, 3));
      z80.step();
      expect(z80.registers.R, 2);
    }, skip: !runAll);
  });
}
