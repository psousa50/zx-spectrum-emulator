import 'package:Z80a/Memory.dart';
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
  ...ldMNNHL(0x22),
  ...ldHLMNN(0x2A),
  ...ldMHLN(0x36),
  ...ldR16NN(0x01, Z80a.R_BC),
  ...ldR16NN(0x11, Z80a.R_DE),
  ...ldR16NN(0x21, Z80a.R_HL),
  ...ldR16NN(0x31, Z80a.R_SP),
  ...addHLR16(0x09, Z80a.R_BC),
  ...addHLR16(0x19, Z80a.R_DE),
  ...addHLHL(0x29),
  ...addHLR16(0x39, Z80a.R_SP),
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
  ...incR8(0x3C, Z80a.R_A),
  ...decR8(0x05, Z80a.R_B),
  ...decR8(0x0D, Z80a.R_C),
  ...decR8(0x15, Z80a.R_D),
  ...decR8(0x1D, Z80a.R_E),
  ...decR8(0x25, Z80a.R_H),
  ...decR8(0x2D, Z80a.R_L),
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
];

void main() {
  const runAll = true;

  test('All Scenarios', () {
    allScenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: !runAll);

  test('One Scenario', () {
    var scenarios = ldHLMNN(0x2A);
    scenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: runAll);

  test('All opcodes should be processed', () {
    var z80a = Z80a(Memory(size: 10));
    for (var opcode = 0; opcode < 256; opcode++) {
      if (![0x27].contains(opcode)) {
        z80a.memory.poke(0, opcode);
        z80a.memory.poke(1, 0);
        z80a.memory.poke(2, 0);
        z80a.memory.poke(3, 0);
        z80a.PC = 0;
        expect(z80a.step(), true,
            reason: 'Opcode ${opcode.toRadixString(16)} not processed');
      }
    }
  }, skip: true);
}
