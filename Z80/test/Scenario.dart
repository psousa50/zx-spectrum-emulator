import 'dart:typed_data';

import 'package:Z80/Cpu/Registers.dart';
import 'package:test/test.dart';

import 'package:Z80/Memory.dart';
import 'package:Z80/Util.dart';
import 'package:Z80/Cpu/Z80.dart';

import 'MemoryTest.dart';
import 'PortsTest.dart';

class State {
  Map<int, int> registerValues = {};
  List<int> ram = [];
  Map<int, int> inPorts = {};
  Map<int, int> outPorts = {};
  int? pc;
  String flags = "";

  State({
    Map<int, int> register8Values = const {},
    Map<int, int> register16Values = const {},
    Map<int, int> inPorts = const {},
    Map<int, int> outPorts = const {},
    this.ram = const [],
    this.pc,
    this.flags = "",
  }) {
    register8Values.forEach((r, value) {
      this.registerValues[r] = value;
    });
    register16Values.forEach((r, value) {
      this.registerValues[r] = hi(value);
      this.registerValues[r + 1] = lo(value);
    });
    this.inPorts = inPorts;
    this.outPorts = outPorts;
  }
}

typedef void BeforeRun(Z80 z80);

class Scenario {
  static const RAM_START = 10;

  final String name;
  final List<int> opcodes;
  State initialState;
  State expectedState;
  BeforeRun? beforeRun;

  Scenario(this.name, this.opcodes,
      {required this.initialState,
      required this.expectedState,
      this.beforeRun});

  String opcodesToString(List<int> opcodes) => '${opcodes.map(toHex)}';

  String scenarioName(List<int> opcodes) =>
      '${this.name} <=> ${opcodesToString(opcodes)}';

  String wrongRegister(List<int> opcodes, int r) =>
      '${scenarioName(opcodes)}\nReason: ${Registers.r8Names[r]} as wrong value';

  Map<int, int> zeroRegisterValues() {
    Map<int, int> registerValues = {};
    for (var r = 0; r < Registers.R_COUNT; r++) {
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
    expect(value, expectedRegisterValues[Registers.R_F]! & flag == flag,
        reason:
            '${scenarioName(opcodes)}: Flag ${Registers.flagNames[flag]} has wrong value');
  }

  void runWithFlagsSetTo(bool flagsValue) {
    Map<int, int> initialRegisterValues =
        setupInitialRegisterValues(flagsValue);

    Map<int, int> expectedRegisterValues =
        setupExpectedRegisterValues(initialRegisterValues);

    var memory = setupMemory();
    var ports = setupPorts();
    var z80 = Z80(memory, ports);

    z80.PC = initialState.pc ?? 0;

    setZ80Registers(z80, initialRegisterValues);

    beforeRun?.call(z80);

    var initialPC = z80.PC;

    memory.setRange(initialPC, Uint8List.fromList(opcodes));

    Map<int, int> actualRegisterValues = getZ80Registers(z80);

    for (var r = 0; r < Registers.R_COUNT; r++) {
      if (![
        Registers.R_R,
        Registers.R_F,
        Registers.R_S,
        Registers.R_P,
        Registers.R_PC_H,
        Registers.R_PC_L,
      ].contains(r)) {
        // FLAGS are checked later, individually
        expect(actualRegisterValues[r], expectedRegisterValues[r],
            reason: wrongRegister(opcodes, r));
      }
    }

    checkFlag(
        z80.registers.carryFlag, Registers.F_CARRY, expectedRegisterValues);
    checkFlag(z80.registers.addSubtractFlag, Registers.F_ADD_SUB,
        expectedRegisterValues);
    checkFlag(z80.registers.parityOverflowFlag, Registers.F_PARITY,
        expectedRegisterValues);
    checkFlag(z80.registers.halfCarryFlag, Registers.F_HALF_CARRY,
        expectedRegisterValues);
    checkFlag(z80.registers.zeroFlag, Registers.F_ZERO, expectedRegisterValues);
    checkFlag(z80.registers.signFlag, Registers.F_SIGN, expectedRegisterValues);

    expect(z80.memory.range(10), expectedState.ram,
        reason: '${scenarioName(opcodes)}\nReason: RAM is wrong');

    expectedState.outPorts.forEach((port, value) {
      expect(ports.readOutPort(port), value,
          reason: '${scenarioName(opcodes)}\nReason: OutPort $port is wrong');
    });

    expect(
        z80.registers.SP,
        256 * expectedRegisterValues[Registers.R_SP]! +
            expectedRegisterValues[Registers.R_SP + 1]!,
        reason: '${scenarioName(opcodes)}\nReason: SP is wrong');

    var expectedPC = expectedState.pc == null
        ? initialPC + opcodes.length
        : expectedState.pc;
    expect(z80.PC, expectedPC,
        reason: '${scenarioName(opcodes)}\nReason: PC is wrong');
  }

  Map<int, int> getZ80Registers(Z80 z80) {
    Map<int, int> actualRegisterValues = {};
    for (var r = 0; r < Registers.R_COUNT; r++) {
      actualRegisterValues[r] = z80.r8Value(r);
    }
    return actualRegisterValues;
  }

  void setZ80Registers(Z80 z80, Map<int, int> initialRegisterValues) {
    int pc = z80.PC;
    initialRegisterValues.keys.forEach((r) {
      z80.setR8Value(r, initialRegisterValues[r]!);
    });

    z80.PC = pc;
  }

  void run() {
    if (initialState.pc == null) initialState.pc = 0;
    runWithFlagsSetTo(false);
    runWithFlagsSetTo(true);
  }

  Memory setupMemory() {
    var memory = List<int>.filled(RAM_START, 0)..addAll(initialState.ram);

    return MemoryTest.fromBytes(memory);
  }

  PortsTest setupPorts() {
    var ports = PortsTest();
    initialState.inPorts.forEach((port, value) {
      ports.writeInPort(port, value);
    });
    return ports;
  }

  Map<int, int> setupInitialRegisterValues(bool flagsValue) {
    int flags = setFlags(0, flagsValue ? "C N P H Z S" : "~C ~N ~P ~H ~Z ~S");
    var zeroValues = zeroRegisterValues();
    zeroValues[Registers.R_F] = flags;
    var initialRegisterValues =
        mergeRegisterValues(zeroValues, initialState.registerValues);

    initialRegisterValues[Registers.R_F] =
        setFlags(initialRegisterValues[Registers.R_F]!, initialState.flags);

    return initialRegisterValues;
  }

  Map<int, int> setupExpectedRegisterValues(
      Map<int, int> initialRegisterValues) {
    var expectedRegisterValues = mergeRegisterValues(
        initialRegisterValues, expectedState.registerValues);

    expectedRegisterValues[Registers.R_F] =
        setFlags(expectedRegisterValues[Registers.R_F]!, expectedState.flags);

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
        flags = flags | Registers.F_CARRY;
        break;
      case 'N':
        flags = flags | Registers.F_ADD_SUB;
        break;
      case 'P':
        flags = flags | Registers.F_PARITY;
        break;
      case 'H':
        flags = flags | Registers.F_HALF_CARRY;
        break;
      case 'Z':
        flags = flags | Registers.F_ZERO;
        break;
      case 'S':
        flags = flags | Registers.F_SIGN;
        break;
      case '~C':
        flags = flags & ~Registers.F_CARRY;
        break;
      case '~N':
        flags = flags & ~Registers.F_ADD_SUB;
        break;
      case '~P':
        flags = flags & ~Registers.F_PARITY;
        break;
      case '~H':
        flags = flags & ~Registers.F_HALF_CARRY;
        break;
      case '~Z':
        flags = flags & ~Registers.F_ZERO;
        break;
      case '~S':
        flags = flags & ~Registers.F_SIGN;
        break;
    }
    return flags;
  }
}
