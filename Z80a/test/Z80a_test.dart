import 'package:Z80a/Memory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Z80a.dart';

class State {
  Map<int, int> registerValues = {};
  List<int> ram = [];
  int pc = 0;
  String flags = "";

  State({
    Map<int, int> register8Values = const {},
    Map<int, int> register16Values = const {},
    this.ram = const [],
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
  static const RAM_START = 10;

  final String name;
  final List<int> opcodes;
  State initialState;
  State expectedState;

  Scenario(this.name, this.opcodes, this.initialState, this.expectedState);

  String scenarioName(List<int> opcodes) =>
      '${this.name} <=> ${opcodes.map((e) => e.toRadixString(16))}';

  String wrongRegister(List<int> opcodes, int r) =>
      '${scenarioName(opcodes)}\nReason: ${Z80a.r8Names[r]} as wrong value';

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

  void checkFlag(bool value, int flag, Map<int, int> expectedRegisterValues) {
    expect(value, expectedRegisterValues[Z80a.R_F] & flag == flag,
        reason:
            '${scenarioName(opcodes)}: Flag ${Z80a.flagNames[flag]} has wrong value');
  }

  void runWithFlagsSetTo(bool flagsValue) {
    List<int> memory = setupMemory();

    Map<int, int> initialRegisterValues =
        setupInitialRegisterValues(flagsValue);

    Map<int, int> expectedRegisterValues =
        setupExpectedRegisterValues(initialRegisterValues);

    var z80a = Z80a(Memory.withBytes(memory));

    setZ80Registers(z80a, initialRegisterValues);

    z80a.step();

    Map<int, int> actualRegisterValues = getZ80Registers(z80a);

    for (var r = 0; r < Z80a.R_COUNT; r++) {
      if (r != Z80a.R_F) {
        // FLAGS are checked later, individually
        expect(actualRegisterValues[r], expectedRegisterValues[r],
            reason: wrongRegister(opcodes, r));
      }
    }

    checkFlag(z80a.carryFlag, Z80a.F_CARRY, expectedRegisterValues);
    checkFlag(z80a.addSubtractFlag, Z80a.F_ADD_SUB, expectedRegisterValues);
    checkFlag(z80a.parityOverflowFlag, Z80a.F_PARITY, expectedRegisterValues);
    checkFlag(z80a.halfCarryFlag, Z80a.F_HALF_CARRY, expectedRegisterValues);
    checkFlag(z80a.zeroFlag, Z80a.F_ZERO, expectedRegisterValues);
    checkFlag(z80a.signFlag, Z80a.F_SIGN, expectedRegisterValues);

    expect(z80a.memory.bytes.sublist(10), expectedState.ram);

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
      ...List<int>(RAM_START - opcodes.length),
      ...initialState.ram,
    ];
    return memory;
  }

  Map<int, int> setupInitialRegisterValues(bool flagsValue) {
    int flags = setFlags(0, flagsValue ? "C N P H Z S" : "~C ~N ~P ~H ~Z ~S");
    var zeroValues = zeroRegisterValues();
    zeroValues[Z80a.R_F] = flags;
    var initialRegisterValues =
        mergeRegisterValues(zeroValues, initialState.registerValues);

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
      case 'C':
        flags = flags | Z80a.F_CARRY;
        break;
      case 'N':
        flags = flags | Z80a.F_ADD_SUB;
        break;
      case 'P':
        flags = flags | Z80a.F_PARITY;
        break;
      case 'H':
        flags = flags | Z80a.F_HALF_CARRY;
        break;
      case 'Z':
        flags = flags | Z80a.F_ZERO;
        break;
      case 'S':
        flags = flags | Z80a.F_SIGN;
        break;
      case '~C':
        flags = flags & ~Z80a.F_CARRY;
        break;
      case '~N':
        flags = flags & ~Z80a.F_ADD_SUB;
        break;
      case '~P':
        flags = flags & ~Z80a.F_PARITY;
        break;
      case '~H':
        flags = flags & ~Z80a.F_HALF_CARRY;
        break;
      case '~Z':
        flags = flags & ~Z80a.F_ZERO;
        break;
      case '~S':
        flags = flags & ~Z80a.F_SIGN;
        break;
    }
    return flags;
  }
}

List<Scenario> nop(int opcode) => [
      Scenario("nop", [0x00], State(), State())
    ];

List<Scenario> ldR16NN(int opcode, int r16) => [
      Scenario(
          'LD ${Z80a.r16Names[r16]}, NN',
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
      "ADD HL, ${Z80a.r16Names[r16]}",
      [opcode],
      State(register16Values: {Z80a.R_HL: hlValue, r16: r16Value}),
      State(
        register16Values: {Z80a.R_HL: result, r16: r16Value},
        flags: flags,
      ),
    );

List<Scenario> addHLR16(int opcode, int r16) => [
      addHLR16Spec(opcode, r16, 10000, 2345, 12345, "~C"),
      addHLR16Spec(opcode, r16, 65535, 2, 1, "C"),
    ];

Scenario addHLHLSpec(int opcode, int hlValue, int result, String flags) =>
    Scenario(
      "ADD HL, HL",
      [opcode],
      State(register16Values: {Z80a.R_HL: hlValue}),
      State(
        register16Values: {Z80a.R_HL: result},
        flags: flags,
      ),
    );

List<Scenario> addHLHL(int opcode) => [
      addHLHLSpec(opcode, 10000, 20000, "~C"),
      addHLHLSpec(opcode, 65535, 65534, "C"),
    ];

List<Scenario> incR16(int opcode, int r16) => [
      Scenario(
          'INC ${Z80a.r16Names[r16]}',
          [opcode],
          State(register16Values: {r16: 10000}),
          State(
            register16Values: {r16: 10001},
          ))
    ];

List<Scenario> decR16(int opcode, int r16) => [
      Scenario(
          'DEC ${Z80a.r16Names[r16]}',
          [opcode],
          State(register16Values: {r16: 10000}),
          State(
            register16Values: {r16: 9999},
          ))
    ];

Scenario changeR8N(
        String name, int opcode, int r8, int value, int result, String flags) =>
    Scenario(
        '$name ${Z80a.r8Names[r8]}',
        [opcode],
        State(register8Values: {r8: value}),
        State(register8Values: {r8: result}, flags: flags));

List<Scenario> incR8(int opcode, int r8) => [
      changeR8N("INC", opcode, r8, 10, 11, "~Z ~S ~P ~N"),
      changeR8N("INC", opcode, r8, 255, 0, "Z ~S ~P ~N"),
      changeR8N("INC", opcode, r8, 127, 128, "~Z S P ~N"),
      changeR8N("INC", opcode, r8, 130, 131, "~Z S ~P ~N"),
    ];

List<Scenario> decR8(int opcode, int r8) => [
      changeR8N("DEC", opcode, r8, 10, 9, "~Z ~S ~P N"),
      changeR8N("DEC", opcode, r8, 1, 0, "Z ~S ~P N"),
      changeR8N("DEC", opcode, r8, 128, 127, "~Z ~S P N"),
      changeR8N("DEC", opcode, r8, 131, 130, "~Z S ~P N"),
    ];

List<Scenario> exAFAFt(int opcode) => [
      Scenario(
          'EX AF, AF' '',
          [opcode],
          State(register16Values: {Z80a.R_AF: 1000, Z80a.R_AFt: 1500}),
          State(register16Values: {Z80a.R_AF: 1500, Z80a.R_AFt: 1000}))
    ];

List<Scenario> ldR16A(int opcode, int r16) => [
      Scenario(
        'LD (${Z80a.r16Names[r16]}), A',
        [opcode],
        State(
          register8Values: {Z80a.R_A: 55},
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 0],
        ),
        State(ram: [0, 55]),
      )
    ];

List<Scenario> ldAR16(int opcode, int r16) => [
      Scenario(
        'LD A, (${Z80a.r16Names[r16]})',
        [opcode],
        State(
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 55],
        ),
        State(register8Values: {Z80a.R_A: 55}, ram: [0, 55]),
      )
    ];

var scenarios = [
  ...nop(0x00),
  // ...ldR16A(0x02, Z80a.R_BC),
  // ...ldR16A(0x12, Z80a.R_DE),
  // ...ldAR16(0x0A, Z80a.R_BC),
  // ...ldAR16(0x1A, Z80a.R_DE),
  // ...exAFAFt(0x08),
  // ...ldR16NN(0x01, Z80a.R_BC),
  // ...ldR16NN(0x11, Z80a.R_DE),
  // ...ldR16NN(0x21, Z80a.R_HL),
  // ...ldR16NN(0x31, Z80a.R_SP),
  // ...addHLR16(0x09, Z80a.R_BC),
  // ...addHLR16(0x19, Z80a.R_DE),
  // ...addHLHL(0x29),
  // ...addHLR16(0x39, Z80a.R_SP),
  // ...incR16(0x03, Z80a.R_BC),
  // ...incR16(0x13, Z80a.R_DE),
  // ...incR16(0x23, Z80a.R_HL),
  // ...incR16(0x33, Z80a.R_SP),
  // ...decR16(0x0B, Z80a.R_BC),
  // ...decR16(0x1B, Z80a.R_DE),
  // ...decR16(0x2B, Z80a.R_HL),
  // ...decR16(0x3B, Z80a.R_SP),
  // ...incR8(0x04, Z80a.R_B),
  // ...incR8(0x0C, Z80a.R_C),
  // ...incR8(0x14, Z80a.R_D),
  // ...incR8(0x1C, Z80a.R_E),
  // ...incR8(0x24, Z80a.R_H),
  // ...incR8(0x2C, Z80a.R_L),
  // ...incR8(0x3C, Z80a.R_A),
  // ...decR8(0x05, Z80a.R_B),
  // ...decR8(0x0D, Z80a.R_C),
  // ...decR8(0x15, Z80a.R_D),
  // ...decR8(0x1D, Z80a.R_E),
  // ...decR8(0x25, Z80a.R_H),
  // ...decR8(0x2D, Z80a.R_L),
  // ...decR8(0x3D, Z80a.R_A),
];

void main() {
  test('All Scenarios', () {
    scenarios.forEach((scenario) {
      scenario.run();
    });
  });
}
