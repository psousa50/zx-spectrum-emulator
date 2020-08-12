import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Util.dart';
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
    this.pc = 0,
    this.flags = "",
  }) {
    register8Values.forEach((r, value) {
      this.registerValues[r] = value;
    });
    register16Values.forEach((r, value) {
      this.registerValues[r] = hi(value);
      this.registerValues[r + 1] = lo(value);
    });
  }
}

class Scenario {
  static const RAM_START = 10;

  final String name;
  final List<int> opcodes;
  State initialState;
  State expectedState;
  int baseAddress;

  Scenario(this.name, this.opcodes,
      {this.initialState, this.expectedState, this.baseAddress = 0});

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

    var z80a = Z80a(Memory.withBytes(memory, baseAddress: this.baseAddress));

    setZ80Registers(z80a, initialRegisterValues);

    z80a.step();

    Map<int, int> actualRegisterValues = getZ80Registers(z80a);

    for (var r = 0; r < Z80a.R_COUNT; r++) {
      if (![Z80a.R_F, Z80a.R_S, Z80a.R_P].contains(r)) {
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

    expect(z80a.memory.bytes.sublist(10), expectedState.ram,
        reason: '${scenarioName(opcodes)}\nReason: RAM is wrong');

    expect(
        z80a.SP,
        256 * expectedRegisterValues[Z80a.R_SP] +
            expectedRegisterValues[Z80a.R_SP + 1],
        reason: '${scenarioName(opcodes)}\nReason: SP is wrong');

    expect(z80a.PC, expectedState.pc,
        reason: '${scenarioName(opcodes)}\nReason: PC is wrong');
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

    z80a.PC = initialState.pc;
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

    initialRegisterValues[Z80a.R_F] =
        setFlags(initialRegisterValues[Z80a.R_F], initialState.flags);

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