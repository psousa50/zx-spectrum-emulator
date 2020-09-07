import 'package:Z80a/Cpu/Registers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Util.dart';
import 'package:Z80a/Cpu/Z80a.dart';

import 'MemoryTest.dart';
import 'PortsTest.dart';

class State {
  Map<int, int> registerValues = {};
  List<int> ram = [];
  Map<int, int> inPorts;
  Map<int, int> outPorts;
  int pc = 0;
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

class Scenario {
  static const RAM_START = 10;

  final String name;
  final List<int> opcodes;
  State initialState;
  State expectedState;

  Scenario(this.name, this.opcodes, {this.initialState, this.expectedState});

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
    expect(value, expectedRegisterValues[Registers.R_F] & flag == flag,
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
    var z80a = Z80a(memory, ports);

    setZ80Registers(z80a, initialRegisterValues);

    var tStates = z80a.step();

    expect(tStates != null, true,
        reason: "Opcode not processed => ${opcodesToString(opcodes)}");

    Map<int, int> actualRegisterValues = getZ80Registers(z80a);

    for (var r = 0; r < Registers.R_COUNT; r++) {
      if (![Registers.R_F, Registers.R_S, Registers.R_P].contains(r)) {
        // FLAGS are checked later, individually
        expect(actualRegisterValues[r], expectedRegisterValues[r],
            reason: wrongRegister(opcodes, r));
      }
    }

    checkFlag(
        z80a.registers.carryFlag, Registers.F_CARRY, expectedRegisterValues);
    checkFlag(z80a.registers.addSubtractFlag, Registers.F_ADD_SUB,
        expectedRegisterValues);
    checkFlag(z80a.registers.parityOverflowFlag, Registers.F_PARITY,
        expectedRegisterValues);
    checkFlag(z80a.registers.halfCarryFlag, Registers.F_HALF_CARRY,
        expectedRegisterValues);
    checkFlag(
        z80a.registers.zeroFlag, Registers.F_ZERO, expectedRegisterValues);
    checkFlag(
        z80a.registers.signFlag, Registers.F_SIGN, expectedRegisterValues);

    expect(z80a.memory.range(10), expectedState.ram,
        reason: '${scenarioName(opcodes)}\nReason: RAM is wrong');

    expectedState.outPorts.forEach((port, value) {
      expect(ports.readOutPort(port), value,
          reason: '${scenarioName(opcodes)}\nReason: OutPort $port is wrong');
    });

    expect(
        z80a.registers.SP,
        256 * expectedRegisterValues[Registers.R_SP] +
            expectedRegisterValues[Registers.R_SP + 1],
        reason: '${scenarioName(opcodes)}\nReason: SP is wrong');

    var expectedPC = expectedState.pc == null
        ? initialState.pc + opcodes.length
        : expectedState.pc;
    expect(z80a.PC, expectedPC,
        reason: '${scenarioName(opcodes)}\nReason: PC is wrong');
  }

  Map<int, int> getZ80Registers(Z80a z80a) {
    Map<int, int> actualRegisterValues = {};
    for (var r = 0; r < Registers.R_COUNT; r++) {
      actualRegisterValues[r] = z80a.r8Value(r);
    }
    return actualRegisterValues;
  }

  void setZ80Registers(Z80a z80a, Map<int, int> initialRegisterValues) {
    initialRegisterValues.keys.forEach((r) {
      z80a.setR8Value(r, initialRegisterValues[r]);
    });

    z80a.PC = initialState.pc;
  }

  void run() {
    if (initialState.pc == null) initialState.pc = 0;
    runWithFlagsSetTo(false);
    runWithFlagsSetTo(true);
  }

  Memory setupMemory() {
    var memory = [
      ...List<int>(RAM_START),
      ...initialState.ram,
    ];
    memory.setRange(initialState.pc, initialState.pc + opcodes.length, opcodes);

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
        setFlags(initialRegisterValues[Registers.R_F], initialState.flags);

    return initialRegisterValues;
  }

  Map<int, int> setupExpectedRegisterValues(
      Map<int, int> initialRegisterValues) {
    var expectedRegisterValues = mergeRegisterValues(
        initialRegisterValues, expectedState.registerValues);

    expectedRegisterValues[Registers.R_F] =
        setFlags(expectedRegisterValues[Registers.R_F], expectedState.flags);

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
