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
  ...rra(0x17),
  ...rla(0x1F),
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
  ...exMSPHL(0xE3),
  ...jpMHL(0xE9),
  ...exDEHL(0xEB),
  ...ldSPHL(0xF9),

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
];

void main() {
  const runAll = true;

  test('All Scenarios', () {
    allScenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: !runAll);

  test('One Scenario', () {
    var scenarios = addHLR16(0x09, Z80a.R_IX, Z80a.R_BC);
    scenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: runAll);
}
