import 'package:Z80a/Memory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Z80a.dart';

class State {
  Map<int, int> registerValues = {};
  List<int> memory = [];
  int pc = 0;
  String flags = "";

  State({
    Map<int, int> register8Values = const {},
    Map<int, int> register16Values = const {},
    this.memory = const [],
    this.pc = 1,
    this.flags = "",
  }) {
    register8Values.forEach((r, value) {
      this.registerValues[r] = value;
    });
    register16Values.forEach((r, value) {
      this.registerValues[r] = value ~/ 256;
      this.registerValues[r + 1] = value % 256;
    });
  }
}

class Scenario {
  final String name;
  final List<int> opcodes;
  State initialState;
  State expectedState;

  Scenario(this.name, this.opcodes, this.initialState, this.expectedState);

  String wrongRegister(List<int> opcodes, int r) =>
      '${this.name} ${opcodes.map((e) => e.toRadixString(16))}: ${Z80a.r8Names[r]} as wrong value';

  Map<int, int> zeroRegisterValues() {
    Map<int, int> registerValues = {};
    for (var r = 0; r < Z80a.R_COUNT; r++) {
      registerValues[r] = 0;
    }
    return registerValues;
  }

  Map<int, int> mergeRegisterValues(
      Map<int, int> registerValues1, Map<int, int> registerValues2) {
    var registerValues = Map<int, int>.from(registerValues1);
    registerValues2.forEach((r, value) {
      registerValues[r] = value;
    });
    return registerValues;
  }

  void runWithFlagsSetTo(bool flagsValue) {
    List<int> memory = setupMemory();

    Map<int, int> initialRegisterValues =
        setupInitialRegisterValues(flagsValue);

    Map<int, int> expectedRegisterValues =
        setupExpectedRegisterValues(initialRegisterValues);

    var z80a = Z80a(Memory.withBytes(memory));

    setZ80Registers(z80a, initialRegisterValues);

    z80a.start(0);

    Map<int, int> actualRegisterValues = getZ80Registers(z80a);

    for (var r = 0; r < Z80a.R_COUNT; r++) {
      expect(actualRegisterValues[r], expectedRegisterValues[r],
          reason: wrongRegister(opcodes, r));
    }

    expect(z80a.PC, expectedState.pc, reason: "PC is wrong");
  }

  Map<int, int> getZ80Registers(Z80a z80a) {
    Map<int, int> actualRegisterValues = {};
    for (var r = 0; r < Z80a.R_COUNT; r++) {
      actualRegisterValues[r] = z80a.getReg(r);
    }
    return actualRegisterValues;
  }

  void setZ80Registers(Z80a z80a, Map<int, int> initialRegisterValues) {
    initialRegisterValues.keys.forEach((r) {
      z80a.setReg(r, initialRegisterValues[r]);
    });
  }

  void run() {
    runWithFlagsSetTo(false);
    runWithFlagsSetTo(true);
  }

  List<int> setupMemory() {
    var memory = [
      ...opcodes,
      ...List<int>(10 - opcodes.length),
      ...initialState.memory,
    ];
    return memory;
  }

  Map<int, int> setupInitialRegisterValues(bool flagsValue) {
    var initialRegisterValues =
        mergeRegisterValues(zeroRegisterValues(), initialState.registerValues);
    if (flagsValue) {
      initialRegisterValues[Z80a.R_F] =
          setFlags(initialRegisterValues[Z80a.R_F], "C1 N1 P1 Z1 S1");
    }
    return initialRegisterValues;
  }

  Map<int, int> setupExpectedRegisterValues(
      Map<int, int> initialRegisterValues) {
    var expectedRegisterValues = mergeRegisterValues(
        initialRegisterValues, expectedState.registerValues);

    expectedRegisterValues[Z80a.R_F] =
        setFlags(expectedRegisterValues[Z80a.R_F], expectedState.flags);

    return expectedRegisterValues;
  }

  int setFlags(int flags, String flagNames) {
    flagNames.split(' ').forEach((f) {
      flags = setFlag(flags, f);
    });
    return flags;
  }

  int setFlag(int flags, String flagName) {
    switch (flagName) {
      case 'C1':
        flags = flags | Z80a.F_CARRY;
        break;
      case 'N1':
        flags = flags | Z80a.F_ADD_SUB;
        break;
      case 'P1':
        flags = flags | Z80a.F_PARITY;
        break;
      case 'Z1':
        flags = flags | Z80a.F_ZERO;
        break;
      case 'S1':
        flags = flags | Z80a.F_SIGN;
        break;
      case 'C0':
        flags = flags & ~Z80a.F_CARRY;
        break;
      case 'N0':
        flags = flags & ~Z80a.F_ADD_SUB;
        break;
      case 'P0':
        flags = flags & ~Z80a.F_PARITY;
        break;
      case 'Z0':
        flags = flags & ~Z80a.F_ZERO;
        break;
      case 'S0':
        flags = flags & ~Z80a.F_SIGN;
        break;
    }
    return flags;
  }
}

List<Scenario> nop = [
  Scenario("nop", [0x00], State(), State())
];

List<Scenario> ldR16NN(int opcode, int r16) => [
      Scenario(
          'ldR16NN (${Z80a.r16Names[r16]})',
          [opcode, 12, 34],
          State(),
          State(
            register16Values: {r16: 34 * 256 + 12},
            pc: 3,
          ))
    ];

Scenario addHLR16Spec(int opcode, int r16, int hlValue, int r16Value,
        int result, String flags) =>
    Scenario(
      "addHLR16",
      [opcode],
      State(register16Values: {Z80a.R_HL: hlValue, r16: r16Value}),
      State(
        register16Values: {Z80a.R_HL: result, r16: r16Value},
        flags: flags,
      ),
    );

List<Scenario> addHLR16(int opcode, int r16) => [
      addHLR16Spec(opcode, r16, 10000, 2345, 12345, "C0"),
      addHLR16Spec(opcode, r16, 65535, 2, 1, "C1"),
    ];

var scenarios = [
  ...nop,
  ...ldR16NN(0x01, Z80a.R_BC),
  ...ldR16NN(0x11, Z80a.R_DE),
  ...ldR16NN(0x21, Z80a.R_HL),
  ...ldR16NN(0x31, Z80a.R_SP),
  ...addHLR16(0x09, Z80a.R_BC),
  ...addHLR16(0x19, Z80a.R_DE),
  ...addHLR16(0x39, Z80a.R_SP),
];

void main() {
  test('All Scenarios', () {
    scenarios.forEach((scenario) {
      scenario.run();
    });
  });
}
