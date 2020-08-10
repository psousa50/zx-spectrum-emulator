import '../lib/Z80a.dart';
import './Scenario.dart';

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
