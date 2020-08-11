import 'package:flutter_test/flutter_test.dart';

import '../lib/Z80a.dart';
import './Scenarios.dart';

var allScenarios = [
  ...nop(0x00),
  ...ldR16A(0x02, Z80a.R_BC),
  ...ldR16A(0x12, Z80a.R_DE),
  ...ldAR16(0x0A, Z80a.R_BC),
  ...ldAR16(0x1A, Z80a.R_DE),
  ...exAFAFt(0x08),
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
  ...callNN(0xCD),
  ...ret(0xC9),
];

void main() {
  const runOne = false;

  test('All Scenarios', () {
    allScenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: runOne);

  test('One Scenario', () {
    var scenarios = incR8(0x04, Z80a.R_B);
    scenarios.forEach((scenario) {
      scenario.run();
    });
  }, skip: !runOne);
}
