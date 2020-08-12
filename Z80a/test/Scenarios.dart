import 'package:Z80a/Util.dart';
import 'package:Z80a/Z80a.dart';
import 'Scenario.dart';

List<Scenario> nop(int opcode) => [
      Scenario(
        "NOP",
        [opcode],
        initialState: State(),
        expectedState: State(pc: 1),
      )
    ];

List<Scenario> ldR8NN(int opcode, int r8) => [
      Scenario(
        'LD ${Z80a.r8Names[r8]}, NN',
        [opcode, 12],
        initialState: State(),
        expectedState: State(
          register8Values: {r8: 12},
          pc: 2,
        ),
      )
    ];

List<Scenario> ldMHLNN(int opcode) => [
      Scenario(
        'LD (HL), NN',
        [opcode, 12],
        initialState: State(
          register16Values: {Z80a.R_HL: Scenario.RAM_START + 1},
          ram: [0, 0, 0],
        ),
        expectedState: State(
          ram: [0, 12, 0],
          pc: 2,
        ),
      )
    ];

List<Scenario> ldR16NN(int opcode, int r16) => [
      Scenario(
        'LD ${Z80a.r16Names[r16]}, NN',
        [opcode, 12, 34],
        initialState: State(),
        expectedState: State(
          register16Values: {r16: 34 * 256 + 12},
          pc: 3,
        ),
      )
    ];

Scenario addHLR16Spec(int opcode, int r16, int hlValue, int r16Value,
        int result, String flags) =>
    Scenario(
      "ADD HL, ${Z80a.r16Names[r16]}",
      [opcode],
      initialState:
          State(register16Values: {Z80a.R_HL: hlValue, r16: r16Value}),
      expectedState: State(
        register16Values: {Z80a.R_HL: result, r16: r16Value},
        flags: flags,
        pc: 1,
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
      initialState: State(register16Values: {Z80a.R_HL: hlValue}),
      expectedState: State(
        register16Values: {Z80a.R_HL: result},
        flags: flags,
        pc: 1,
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
        initialState: State(register16Values: {r16: 10000}),
        expectedState: State(
          register16Values: {r16: 10001},
          pc: 1,
        ),
      )
    ];

List<Scenario> decR16(int opcode, int r16) => [
      Scenario(
        'DEC ${Z80a.r16Names[r16]}',
        [opcode],
        initialState: State(register16Values: {r16: 10000}),
        expectedState: State(
          register16Values: {r16: 9999},
          pc: 1,
        ),
      )
    ];

Scenario changeR8(
        String name, int opcode, int r8, int value, int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name ${Z80a.r8Names[r8]}',
      [opcode],
      initialState: State(
        register8Values: {r8: value},
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {r8: result},
        flags: flags,
        pc: 1,
      ),
    );

List<Scenario> incR8(int opcode, int r8) => [
      changeR8("INC", opcode, r8, 10, 11, "~Z ~S ~P ~N"),
      changeR8("INC", opcode, r8, 255, 0, "Z ~S ~P ~N"),
      changeR8("INC", opcode, r8, 127, 128, "~Z S P ~N"),
      changeR8("INC", opcode, r8, 130, 131, "~Z S ~P ~N"),
    ];

List<Scenario> decR8(int opcode, int r8) => [
      changeR8("DEC", opcode, r8, 10, 9, "~Z ~S ~P N"),
      changeR8("DEC", opcode, r8, 1, 0, "Z ~S ~P N"),
      changeR8("DEC", opcode, r8, 128, 127, "~Z ~S P N"),
      changeR8("DEC", opcode, r8, 131, 130, "~Z S ~P N"),
    ];

List<Scenario> exAFAFt(int opcode) => [
      Scenario(
        'EX AF, AF' '',
        [opcode],
        initialState: State(
          register16Values: {Z80a.R_AF: 1000, Z80a.R_AFt: 1500},
        ),
        expectedState: State(
          register16Values: {Z80a.R_AF: 1500, Z80a.R_AFt: 1000},
          pc: 1,
        ),
      )
    ];

List<Scenario> ldR16A(int opcode, int r16) => [
      Scenario(
        'LD (${Z80a.r16Names[r16]}), A',
        [opcode],
        initialState: State(
          register8Values: {Z80a.R_A: 55},
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 55],
          pc: 1,
        ),
      )
    ];

List<Scenario> ldAR16(int opcode, int r16) => [
      Scenario(
        'LD A, (${Z80a.r16Names[r16]})',
        [opcode],
        initialState: State(
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 55],
        ),
        expectedState: State(
          register8Values: {Z80a.R_A: 55},
          ram: [0, 55],
          pc: 1,
        ),
      )
    ];

List<Scenario> rlca(int opcode) => [
      changeR8("RLCA", 0x07, Z80a.R_A, binary("00010011"), binary("00100110"),
          "~C ~N"),
      changeR8("RLCA", 0x07, Z80a.R_A, binary("10010011"), binary("00100111"),
          "C ~N"),
    ];

List<Scenario> rrca(int opcode) => [
      changeR8("RRCA", 0x0F, Z80a.R_A, binary("10100010"), binary("01010001"),
          "~C ~N"),
      changeR8("RRCA", 0x0F, Z80a.R_A, binary("10100011"), binary("11010001"),
          "C ~N"),
    ];

List<Scenario> rla(int opcode) => [
      changeR8("RLA", 0x17, Z80a.R_A, binary("00100010"), binary("01000100"),
          "~C ~N",
          inFlags: "~C"),
      changeR8(
          "RLA", 0x17, Z80a.R_A, binary("10100010"), binary("01000100"), "C ~N",
          inFlags: "~C"),
      changeR8("RLA", 0x17, Z80a.R_A, binary("00100010"), binary("01000101"),
          "~C ~N",
          inFlags: "C"),
      changeR8(
          "RLA", 0x17, Z80a.R_A, binary("10100010"), binary("01000101"), "C ~N",
          inFlags: "C"),
    ];

List<Scenario> rra(int opcode) => [
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100010"), binary("00010001"),
          "~C ~N",
          inFlags: "~C"),
      changeR8(
          "RRA", 0x1F, Z80a.R_A, binary("00100011"), binary("00010001"), "C ~N",
          inFlags: "~C"),
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100010"), binary("10010001"),
          "~C ~N",
          inFlags: "C"),
      changeR8(
          "RRA", 0x1F, Z80a.R_A, binary("00100011"), binary("10010001"), "C ~N",
          inFlags: "C"),
    ];

List<Scenario> ldR8R8(int opcode, int r8Source, int r8Dest) => [
      Scenario(
        'LD ${Z80a.r8Names[r8Source]}, ${Z80a.r8Names[r8Dest]}',
        [opcode],
        initialState: State(
          register8Values: {r8Source: 10, r8Dest: r8Source == r8Dest ? 10 : 5},
        ),
        expectedState: State(
          register8Values: {r8Source: 10, r8Dest: 10},
          pc: 1,
        ),
      )
    ];

List<Scenario> callNN(int opcode) => [
      Scenario("CALL NN", [opcode, 12, 34],
          initialState: State(
              register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 2},
              ram: [0, 0, 0],
              pc: 50000),
          expectedState: State(
            register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 0},
            ram: [lo(50003), hi(50003), 0],
            pc: w(12, 34),
          ),
          baseAddress: 50000)
    ];

List<Scenario> ret(int opcode) => [
      Scenario("RET", [opcode],
          initialState: State(
              register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 0},
              ram: [lo(12345), hi(12345), 0],
              pc: 50000),
          expectedState: State(
              register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 2},
              ram: [lo(12345), hi(12345), 0],
              pc: 12345),
          baseAddress: 50000)
    ];

Scenario callCCNNJump(int opcode, String flag) =>
    Scenario("CALL $flag, NN", [opcode, 12, 34],
        initialState: State(
            flags: flag,
            register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 2},
            ram: [0, 0, 0],
            pc: 50000),
        expectedState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 0},
          ram: [lo(50003), hi(50003), 0],
          pc: w(12, 34),
        ),
        baseAddress: 50000);

Scenario callCCNNNotJump(int opcode, String flag) => Scenario(
      "CALL ~$flag, NN",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(pc: 3),
    );

List<Scenario> callCCNN(int opcode, String flag, bool jumpIfSet) => [
      callCCNNJump(opcode, jumpIfSet ? flag : '~$flag'),
      callCCNNNotJump(opcode, jumpIfSet ? '~$flag' : flag),
    ];

Scenario retCCJump(int opcode, String flag) => Scenario("RET $flag", [opcode],
    initialState: State(
        flags: flag,
        register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 0},
        ram: [lo(12345), hi(12345), 0],
        pc: 50000),
    expectedState: State(
        register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 2},
        ram: [lo(12345), hi(12345), 0],
        pc: 12345),
    baseAddress: 50000);

Scenario retCCNotJump(int opcode, String flag) => Scenario(
      "RET ~$flag",
      [opcode],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(pc: 1),
    );

List<Scenario> retCC(int opcode, String flag, bool jumpIfSet) => [
      retCCJump(opcode, jumpIfSet ? flag : '~$flag'),
      retCCNotJump(opcode, jumpIfSet ? '~$flag' : flag),
    ];

Scenario jpCCNNJump(int opcode, String flag) => Scenario(
      "JP $flag, NN",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(
        pc: w(12, 34),
      ),
    );

Scenario jpCCNNNotJump(int opcode, String flag) => Scenario(
      "JP $flag",
      [opcode],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(pc: 1),
    );

List<Scenario> jpCCNN(int opcode, String flag, bool jumpIfSet) => [
      jpCCNNJump(opcode, jumpIfSet ? flag : '~$flag'),
      jpCCNNNotJump(opcode, jumpIfSet ? '~$flag' : flag),
    ];

List<Scenario> jpNN(int opcode) => [
      Scenario(
        "JP NN",
        [opcode, 12, 34],
        initialState: State(),
        expectedState: State(
          pc: w(12, 34),
        ),
      )
    ];

List<Scenario> popR16(int opcode, int r16) => [
      Scenario('POP ${Z80a.r16Names[r16]}', [opcode],
          initialState: State(
              register16Values: {Z80a.R_SP: Scenario.RAM_START + 50000 + 0},
              ram: [lo(12345), hi(12345), 0],
              pc: 50000),
          expectedState: State(
            register16Values: {
              Z80a.R_SP: Scenario.RAM_START + 50000 + 2,
              r16: 12345,
            },
            ram: [
              lo(12345),
              hi(12345),
              0,
            ],
            pc: 50001,
          ),
          baseAddress: 50000)
    ];

List<Scenario> exx(int opcode) => [
      Scenario(
        'EXX',
        [opcode],
        initialState: State(
          register16Values: {
            Z80a.R_BC: 10000,
            Z80a.R_DE: 20000,
            Z80a.R_HL: 30000,
            Z80a.R_BCt: 11111,
            Z80a.R_DEt: 22222,
            Z80a.R_HLt: 33333,
          },
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_BC: 11111,
            Z80a.R_DE: 22222,
            Z80a.R_HL: 33333,
            Z80a.R_BCt: 10000,
            Z80a.R_DEt: 20000,
            Z80a.R_HLt: 30000,
          },
          pc: 1,
        ),
      ),
    ];

List<Scenario> pushR16(int opcode, int r16) => [
      Scenario(
        'PUSH ${Z80a.r16Names[r16]}',
        [opcode],
        initialState: State(
          register16Values: {
            r16: 10000,
            Z80a.R_SP: Scenario.RAM_START + 50000 + 2,
          },
          ram: [0, 0, 0],
          pc: 50000,
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 50000 + 0,
          },
          ram: [lo(10000), hi(10000), 0],
          pc: 50001,
        ),
        baseAddress: 50000,
      )
    ];

List<Scenario> rstNN(int opcode, int rst) => [
      Scenario(
        'RST $rst',
        [opcode],
        initialState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 50000 + 2,
          },
          ram: [0, 0, 0],
          pc: 50000,
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 50000 + 0,
          },
          ram: [lo(50001), hi(50001), 0],
          pc: rst,
        ),
        baseAddress: 50000,
      )
    ];

Scenario djnzNJump(int opcode) => Scenario(
      "DJNZ n",
      [opcode, 10],
      initialState: State(
        register8Values: {Z80a.R_B: 1},
      ),
      expectedState: State(
        register8Values: {Z80a.R_B: 0},
        pc: 12,
      ),
    );

Scenario djnzNNotJump(int opcode) => Scenario(
      "DJNZ n",
      [opcode, 10],
      initialState: State(
        register8Values: {Z80a.R_B: 5},
      ),
      expectedState: State(
        register8Values: {Z80a.R_B: 4},
        pc: 2,
      ),
    );

List<Scenario> djnzN(int opcode) => [
      djnzNJump(opcode),
      djnzNNotJump(opcode),
    ];

List<Scenario> jrN(int opcode) => [
      Scenario(
        "JR n",
        [opcode, 10],
        initialState: State(),
        expectedState: State(
          pc: 12,
        ),
      )
    ];

Scenario jrCCNJump(int opcode, String flag) => Scenario(
      "JR $flag, NN",
      [opcode, 10],
      initialState: State(flags: flag),
      expectedState: State(pc: 12),
    );

Scenario jrCCNNotJump(int opcode, String flag) => Scenario(
      "JR $flag, NN",
      [opcode, 10],
      initialState: State(flags: flag),
      expectedState: State(pc: 2),
    );

List<Scenario> jrCCNN(int opcode, String flag, bool jumpIfSet) => [
      jrCCNJump(opcode, jumpIfSet ? flag : '~$flag'),
      jrCCNNotJump(opcode, jumpIfSet ? '~$flag' : flag),
    ];
