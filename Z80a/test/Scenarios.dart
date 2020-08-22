import 'package:Z80a/Util.dart';
import 'package:Z80a/Z80a.dart';
import 'Scenario.dart';

log(String m, value) {
  print(m);
  print(value);
  return value;
}

bool isIXIY(int rhxy) => rhxy == Z80a.R_IX || rhxy == Z80a.R_IY;

bool isMIXIY(int rhxy) => rhxy == Z80a.R_MIXd || rhxy == Z80a.R_MIYd;

int rMIXY(int rxy) => rxy == Z80a.R_MIXd ? Z80a.R_IX : Z80a.R_IY;

List<int> ixyPrefix(int rhxy) => [
      if (rhxy == Z80a.R_IX) Z80a.IX_PREFIX,
      if (rhxy == Z80a.R_IY) Z80a.IY_PREFIX
    ];

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

List<Scenario> ldMNNHL(int opcode) => [
      Scenario(
        'LD (NN), HL',
        [
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          register16Values: {Z80a.R_HL: 10000},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [lo(10000), hi(10000)],
          pc: 3,
        ),
      )
    ];

List<Scenario> ldMNNA(int opcode) => [
      Scenario(
        'LD (NN), A',
        [
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          register8Values: {Z80a.R_A: 100},
          ram: [0],
        ),
        expectedState: State(
          ram: [100],
          pc: 3,
        ),
      )
    ];

List<Scenario> ldAMNN(int opcode) => [
      Scenario(
        'LD A, (NN)',
        [
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          ram: [12],
        ),
        expectedState: State(
          register8Values: {Z80a.R_A: 12},
          ram: [12],
          pc: 3,
        ),
      )
    ];

List<Scenario> ldMHLN(int opcode) => [
      Scenario(
        'LD (HL), N',
        [opcode, 12],
        initialState: State(
          register16Values: {Z80a.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [12],
          pc: 2,
        ),
      )
    ];

List<Scenario> ldHLMNN(int opcode) => [
      Scenario(
        'LD HL, (NN)',
        [
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          ram: [12, 34],
        ),
        expectedState: State(
          register16Values: {Z80a.R_HL: w(12, 34)},
          ram: [12, 34],
          pc: 3,
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

Scenario changeR16R16Spec(String name, int opcode, int rhxy, int r16,
        int hxyValue, int r16Value, int result, String flags,
        {String inFlags = "", int prefix}) =>
    Scenario(
      "$name ${Z80a.r16Names[rhxy]}, ${Z80a.r16Names[r16]} => ($hxyValue $r16Value)",
      [if (prefix != null) prefix, ...ixyPrefix(rhxy), opcode],
      initialState: State(
        register16Values: {rhxy: hxyValue, r16: r16Value},
        flags: inFlags,
      ),
      expectedState: State(
        register16Values: {
          rhxy: result,
        },
        flags: flags,
        pc: (prefix == null ? 0 : 1) + (isIXIY(rhxy) ? 2 : 1),
      ),
    );

List<Scenario> addHLR16(int opcode, int rhxy, int r16) => [
      changeR16R16Spec("ADD", opcode, rhxy, r16, 10000, 2345, 12345, "~C"),
      changeR16R16Spec("ADD", opcode, rhxy, r16, 65535, 2, 1, "C"),
    ];

Scenario addHLHLSpec(
        int opcode, int rhxy, int hxyValue, int result, String flags) =>
    Scenario(
      "ADD ${Z80a.r16Names[rhxy]}, ${Z80a.r16Names[rhxy]}",
      [...ixyPrefix(rhxy), opcode],
      initialState: State(register16Values: {rhxy: hxyValue}),
      expectedState: State(
        register16Values: {rhxy: result},
        flags: flags,
        pc: isIXIY(rhxy) ? 2 : 1,
      ),
    );

List<Scenario> addHLHL(int opcode, int rhxy) => [
      addHLHLSpec(opcode, rhxy, 10000, 20000, "~C"),
      addHLHLSpec(opcode, rhxy, 65535, 65534, "C"),
    ];

Scenario changeR16(String name, int opcode, int rhxy, int value, int result) =>
    Scenario(
      '$name ${Z80a.r16Names[rhxy]}',
      [...ixyPrefix(rhxy), opcode],
      initialState: State(
        register16Values: {rhxy: value},
      ),
      expectedState: State(
        register16Values: {rhxy: result},
        pc: isIXIY(rhxy) ? 2 : 1,
      ),
    );

List<Scenario> incR16(int opcode, int rhxy) => [
      changeR16("INC", opcode, rhxy, 10000, 10001),
      changeR16("INC", opcode, rhxy, 65535, 0),
    ];

List<Scenario> decR16(int opcode, int rhxy) => [
      changeR16("DEC", opcode, rhxy, 10000, 9999),
      changeR16("DEC", opcode, rhxy, 0, 65535),
    ];

Scenario changeR8R8(
        String name, int opcode, int r8, int value, int result, String flags,
        {String inFlags = "", int prefix}) =>
    Scenario(
      '$name ${Z80a.r8Names[r8]} ($value $result)',
      [if (prefix != null) prefix, opcode],
      initialState: State(
        register8Values: {r8: value},
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {r8: result},
        flags: flags,
      ),
    );

Scenario changeR8HL(
        String name, int opcode, int value, int result, String flags,
        {String inFlags = "", int prefix}) =>
    Scenario(
      '$name (HL)',
      [if (prefix != null) prefix, opcode],
      initialState: State(
        register16Values: {Z80a.R_HL: Scenario.RAM_START},
        ram: [value],
        flags: inFlags,
      ),
      expectedState: State(
        ram: [result],
        flags: flags,
      ),
    );

Scenario changeR8IXYd(
        String name, int opcode, int rxy, int value, int result, String flags,
        {String inFlags = "", int prefix}) =>
    Scenario(
      '$name (IX+d)',
      [if (prefix != null) prefix, ...ixyPrefix(rxy), opcode, 2],
      initialState: State(
        register16Values: {rxy: Scenario.RAM_START},
        ram: [0, 0, value],
        flags: inFlags,
      ),
      expectedState: State(
        ram: [0, 0, result],
        flags: flags,
      ),
    );

Scenario changeR8(
        String name, int opcode, int r8, int value, int result, String flags,
        {String inFlags = "", int prefix}) =>
    isMIXIY(r8)
        ? changeR8IXYd(name, opcode, rMIXY(r8), value, result, flags,
            inFlags: inFlags, prefix: prefix)
        : r8 == Z80a.R_MHL
            ? changeR8HL(name, opcode, value, result, flags,
                inFlags: inFlags, prefix: prefix)
            : changeR8R8(name, opcode, r8, value, result, flags,
                inFlags: inFlags, prefix: prefix);

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
          "~C ~N ~H"),
      changeR8("RLCA", 0x07, Z80a.R_A, binary("10010011"), binary("00100111"),
          "C ~N ~H"),
    ];

List<Scenario> rrca(int opcode) => [
      changeR8("RRCA", 0x0F, Z80a.R_A, binary("10100010"), binary("01010001"),
          "~C ~N ~H"),
      changeR8("RRCA", 0x0F, Z80a.R_A, binary("10100011"), binary("11010001"),
          "C ~N ~H"),
    ];

List<Scenario> rla(int opcode) => [
      changeR8("RLA", 0x17, Z80a.R_A, binary("00100010"), binary("01000100"),
          "~C ~N ~H",
          inFlags: "~C"),
      changeR8("RLA", 0x17, Z80a.R_A, binary("10100010"), binary("01000100"),
          "C ~N ~H",
          inFlags: "~C"),
      changeR8("RLA", 0x17, Z80a.R_A, binary("00100010"), binary("01000101"),
          "~C ~N ~H",
          inFlags: "C"),
      changeR8("RLA", 0x17, Z80a.R_A, binary("10100010"), binary("01000101"),
          "C ~N ~H",
          inFlags: "C"),
    ];

List<Scenario> rra(int opcode) => [
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100010"), binary("00010001"),
          "~C ~N ~H",
          inFlags: "~C"),
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100011"), binary("00010001"),
          "C ~N ~H",
          inFlags: "~C"),
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100010"), binary("10010001"),
          "~C ~N ~H",
          inFlags: "C"),
      changeR8("RRA", 0x1F, Z80a.R_A, binary("00100011"), binary("10010001"),
          "C ~N ~H",
          inFlags: "C"),
    ];

List<Scenario> rlR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00010011"), binary("00100110"),
          "~S ~Z ~C ~N P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("11010011"), binary("10100110"),
          "S ~Z C ~N ~P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10000000"), binary("00000000"),
          "~S Z C ~N ~P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10010011"), binary("00100111"),
          "~S ~Z C ~N ~P ~H",
          inFlags: "C", prefix: prefix),
      changeR8(name, opcode, r8, binary("00010011"), binary("00100111"),
          "~S ~Z ~C ~N ~P ~H",
          inFlags: "C", prefix: prefix),
    ];

List<Scenario> rrR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8("$name 1", opcode, r8, binary("10100010"), binary("01010001"),
          "~S ~Z ~C ~N P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8("$name 2", opcode, r8, binary("10100011"), binary("01010001"),
          "~S ~Z C ~N P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8("$name 3", opcode, r8, binary("00000001"), binary("00000000"),
          "~S Z C ~N ~P ~H",
          inFlags: "~C", prefix: prefix),
      changeR8("$name 4", opcode, r8, binary("10100010"), binary("11010001"),
          "S ~Z ~C ~N ~P ~H",
          inFlags: "C", prefix: prefix),
      changeR8("$name 5", opcode, r8, binary("10100011"), binary("11010001"),
          "S ~Z C ~N ~P ~H",
          inFlags: "C", prefix: prefix),
    ];

List<Scenario> rlcR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00100010"), binary("01000100"),
          "~S ~Z ~C ~N ~P ~H",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("11100010"), binary("11000101"),
          "S ~Z C ~N ~P ~H",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~C ~N ~P ~H",
          prefix: prefix),
    ];

List<Scenario> rrcR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00100010"), binary("00010001"),
          "~S ~Z ~C ~N ~P ~H",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100011"), binary("10010001"),
          "S ~Z C ~N P ~H",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~C ~N ~P ~H",
          prefix: prefix),
    ];

List<Scenario> slaR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("01001100"),
          "~S ~Z ~C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("11100011"), binary("11000110"),
          "S ~Z C ~N ~H ~P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10000000"), binary("00000000"),
          "~S Z C ~N ~H ~P",
          prefix: prefix),
    ];

List<Scenario> sraR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("00010011"),
          "~S ~Z ~C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100111"), binary("00010011"),
          "~S ~Z C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100110"), binary("11010011"),
          "S ~Z ~C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100111"), binary("11010011"),
          "S ~Z C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~C ~N ~H ~P",
          prefix: prefix),
    ];

List<Scenario> srlR8Spec(String name, int opcode, int r8, {int prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("00010011"),
          "~S ~Z ~C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100111"), binary("00010011"),
          "~S ~Z C ~N ~H P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100110"), binary("01010011"),
          "~S ~Z ~C ~N ~H ~P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100111"), binary("01010011"),
          "~S ~Z C ~N ~H ~P",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~C ~N ~H ~P",
          prefix: prefix),
    ];

List<Scenario> rlcR8(int opcode, int r8) =>
    rlcR8Spec("RLC", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> rrcR8(int opcode, int r8) =>
    rrcR8Spec("RRC", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> rlR8(int opcode, int r8) =>
    rlR8Spec("RL", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> rrR8(int opcode, int r8) =>
    rrR8Spec("RR", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> slaR8(int opcode, int r8) =>
    slaR8Spec("SLA", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> sraR8(int opcode, int r8) =>
    sraR8Spec("SRA", opcode, r8, prefix: Z80a.BIT_OPCODES);

List<Scenario> srlR8(int opcode, int r8) =>
    srlR8Spec("SRL", opcode, r8, prefix: Z80a.BIT_OPCODES);

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

List<Scenario> ldR8MHL(int opcode, int r8) => [
      Scenario(
        'LD ${Z80a.r8Names[r8]}, (HL)',
        [opcode],
        initialState: State(
          register16Values: {Z80a.R_HL: Scenario.RAM_START},
          ram: [12],
        ),
        expectedState: State(
          ram: [12],
          register8Values: {r8: 12},
          pc: 1,
        ),
      )
    ];

List<Scenario> ldMHLR8(int opcode, int r8) => [
      Scenario(
        'LD (HL), ${Z80a.r8Names[r8]}',
        [opcode],
        initialState: State(
          register8Values: {r8: 12},
          register16Values: {Z80a.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [12],
          pc: 1,
        ),
      )
    ];

List<Scenario> ldMHLH(int opcode) => [
      Scenario(
        'LD (HL), H',
        [opcode],
        initialState: State(
          register16Values: {Z80a.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [hi(Scenario.RAM_START)],
          pc: 1,
        ),
      )
    ];

List<Scenario> ldMHLL(int opcode) => [
      Scenario(
        'LD (HL), H',
        [opcode],
        initialState: State(
          register16Values: {Z80a.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [lo(Scenario.RAM_START)],
          pc: 1,
        ),
      )
    ];

List<Scenario> callNN(int opcode) => [
      Scenario(
        "CALL NN",
        [opcode, 12, 34],
        initialState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 2},
          ram: [0, 0, 0],
          pc: 5,
        ),
        expectedState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 0},
          ram: [lo(8), hi(8), 0],
          pc: w(12, 34),
        ),
      )
    ];

List<Scenario> ret(int opcode) => [
      Scenario(
        "RET",
        [opcode],
        initialState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 0},
          ram: [lo(12345), hi(12345), 0],
        ),
        expectedState: State(
            register16Values: {Z80a.R_SP: Scenario.RAM_START + 2},
            ram: [lo(12345), hi(12345), 0],
            pc: 12345),
      )
    ];

Scenario callCCNNJump(int opcode, String flag) => Scenario(
      "CALL $flag, NN",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
        register16Values: {Z80a.R_SP: Scenario.RAM_START + 2},
        ram: [0, 0, 0],
        pc: 5,
      ),
      expectedState: State(
        register16Values: {Z80a.R_SP: Scenario.RAM_START + 0},
        ram: [lo(8), hi(8), 0],
        pc: w(12, 34),
      ),
    );

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

Scenario retCCJump(int opcode, String flag) => Scenario(
      "RET $flag",
      [opcode],
      initialState: State(
        flags: flag,
        register16Values: {Z80a.R_SP: Scenario.RAM_START + 0},
        ram: [lo(12345), hi(12345), 0],
      ),
      expectedState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 2},
          ram: [lo(12345), hi(12345), 0],
          pc: 12345),
    );

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

List<Scenario> popR16(int opcode, int rhxy) => [
      Scenario(
        'POP ${Z80a.r16Names[rhxy]}',
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START + 0},
          ram: [lo(12345), hi(12345), 0],
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 2,
            rhxy: 12345,
          },
          ram: [lo(12345), hi(12345), 0],
          pc: isIXIY(rhxy) ? 2 : 1,
        ),
      )
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

List<Scenario> pushR16(int opcode, int rhxy) => [
      Scenario(
        'PUSH ${Z80a.r16Names[rhxy]}',
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: 10000,
            Z80a.R_SP: Scenario.RAM_START + 2,
          },
          ram: [0, 0, 0],
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 0,
          },
          ram: [lo(10000), hi(10000), 0],
          pc: isIXIY(rhxy) ? 2 : 1,
        ),
      )
    ];

List<Scenario> rstNN(int opcode, int rst) => [
      Scenario(
        'RST $rst',
        [opcode],
        initialState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 2,
          },
          ram: [0, 0, 0],
          pc: 5,
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: Scenario.RAM_START + 0,
          },
          ram: [lo(6), hi(6), 0],
          pc: rst,
        ),
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

Scenario cplN(int opcode, int value, int result) => Scenario("CPL", [opcode],
    initialState: State(
      register8Values: {Z80a.R_A: value},
    ),
    expectedState: State(
      register8Values: {Z80a.R_A: result},
      pc: 1,
    ));

List<Scenario> cpl(int opcode) => [
      cplN(opcode, binary("00000000"), binary("11111111")),
      cplN(opcode, binary("11111111"), binary("00000000")),
      cplN(opcode, binary("10110100"), binary("01001011")),
    ];

Scenario flagsTest(int opcode, String flags, String expectedFlags) =>
    Scenario("CCF", [opcode],
        initialState: State(
          flags: flags,
        ),
        expectedState: State(
          flags: expectedFlags,
          pc: 1,
        ));

List<Scenario> ccf(int opcode) => [
      flagsTest(opcode, "C N", "~C ~N"),
      flagsTest(opcode, "~C N", "C ~N"),
    ];

List<Scenario> scf(int opcode) => [
      flagsTest(opcode, "", "C ~N"),
    ];

Scenario r8r8Operation(String name, int opcode, int r8, int aValue, int r8Value,
        int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name ${Z80a.r8Names[r8]} -> ($aValue)',
      [opcode],
      initialState: State(
        register8Values: {
          Z80a.R_A: aValue,
          r8: r8Value,
        },
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Z80a.R_A: result,
        },
        flags: flags,
        pc: 1,
      ),
    );

Scenario r8HLOperation(String name, int opcode, int aValue, int mhlValue,
        int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name (HL) -> ($aValue)',
      [opcode],
      initialState: State(
        register8Values: {
          Z80a.R_A: aValue,
        },
        register16Values: {Z80a.R_HL: Scenario.RAM_START},
        ram: [mhlValue],
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Z80a.R_A: result,
        },
        ram: [mhlValue],
        flags: flags,
        pc: 1,
      ),
    );

Scenario r8IXYOperation(String name, int opcode, int rxy, int aValue,
        int mxyValue, int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name (${Z80a.r16Names[rxy]} + d) -> ($aValue)',
      [...ixyPrefix(rxy), opcode, 1],
      initialState: State(
        register8Values: {
          Z80a.R_A: aValue,
        },
        register16Values: {rxy: Scenario.RAM_START},
        ram: [0, mxyValue],
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Z80a.R_A: result,
        },
        ram: [0, mxyValue],
        flags: flags,
        pc: 3,
      ),
    );

Scenario r8Operation(String name, int opcode, int r8, int aValue, int r8Value,
        int result, String flags, {String inFlags = ""}) =>
    isMIXIY(r8)
        ? r8IXYOperation(
            name, opcode, rMIXY(r8), aValue, r8Value, result, flags,
            inFlags: inFlags)
        : r8 == Z80a.R_MHL
            ? r8HLOperation(name, opcode, aValue, r8Value, result, flags,
                inFlags: inFlags)
            : r8r8Operation(name, opcode, r8, aValue, r8Value, result, flags,
                inFlags: inFlags);

List<Scenario> addAR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("ADD A,", opcode, r8, 10, 10, 20, "~S ~Z ~N ~C ~P"),
        r8Operation("ADD A,", opcode, r8, 128, 128, 0, "~S Z ~N C P"),
      ]
    : [
        r8Operation("ADD A,", opcode, r8, 10, 2, 12, "~S ~Z ~N ~C ~P"),
        r8Operation("ADD A,", opcode, r8, 127, 2, 129, "S ~Z ~N ~C P"),
        r8Operation("ADD A,", opcode, r8, 254, 2, 0, "~S Z ~N C ~P"),
      ];

List<Scenario> adcAR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("ADC A,", opcode, r8, 10, 10, 20, "~S ~Z ~N ~C ~P",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 10, 10, 21, "~S ~Z ~N ~C ~P",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 128, 128, 0, "~S Z ~N C P",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 128, 128, 1, "~S ~Z ~N C P",
            inFlags: "C"),
      ]
    : [
        r8Operation("ADC A,", opcode, r8, 10, 2, 12, "~S ~Z ~N ~C ~P",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 10, 2, 13, "~S ~Z ~N ~C ~P",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 127, 2, 129, "S ~Z ~N ~C P",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 127, 2, 130, "S ~Z ~N ~C P",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 128, 127, 0, "~S Z ~N C P",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 255, 255, 255, "S ~Z ~N C ~P",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 254, 2, 0, "~S Z ~N C ~P",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 254, 1, 0, "~S Z ~N C ~P",
            inFlags: "C"),
      ];

List<Scenario> subAR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("SUB", opcode, r8, 20, 20, 0, "~S Z N ~C ~P"),
        r8Operation("SUB", opcode, r8, 128, 128, 0, "~S Z N ~C ~P"),
      ]
    : [
        r8Operation("SUB", opcode, r8, 10, 2, 8, "~S ~Z N ~C ~P"),
        r8Operation("SUB", opcode, r8, 129, 2, 127, "~S ~Z N ~C P"),
        r8Operation("SUB", opcode, r8, 255, 254, 1, "~S ~Z N ~C ~P"),
        r8Operation("SUB", opcode, r8, 3, 5, 254, "S ~Z N C ~P"),
      ];

List<Scenario> sbcAR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("SBC A,", opcode, r8, 10, 10, 0, "~S Z N ~C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 10, 10, 255, "S ~Z N C ~P",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 128, 128, 0, "~S Z N ~C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 128, 128, 255, "S ~Z N C ~P",
            inFlags: "C"),
      ]
    : [
        r8Operation("SBC A,", opcode, r8, 10, 2, 8, "~S ~Z N ~C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 10, 2, 7, "~S ~Z N ~C ~P",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 255, 1, 254, "S ~Z N ~C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 255, 1, 253, "S ~Z N ~C ~P",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 255, 254, 1, "~S ~Z N ~C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 255, 254, 0, "~S Z N ~C ~P",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 3, 5, 254, "S ~Z N C ~P",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 3, 5, 253, "S ~Z N C ~P",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 129, 2, 126, "~S ~Z N ~C P",
            inFlags: "C"),
      ];

List<Scenario> andR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("AND", opcode, r8, 0x07, 0x07, 0x07, "~S ~Z ~N ~C P"),
        r8Operation("AND", opcode, r8, 0x00, 0x00, 0x00, "~S Z ~N ~C ~P"),
        r8Operation("AND", opcode, r8, 0x90, 0x90, 0x90, "S ~Z ~N ~C ~P"),
      ]
    : [
        r8Operation("AND", opcode, r8, 0x03, 0x01, 0x01, "~S ~Z ~N ~C P"),
        r8Operation("AND", opcode, r8, 0x03, 0x04, 0x00, "~S Z ~N ~C ~P"),
      ];

List<Scenario> xorR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("XOR", opcode, r8, 0x07, 0x07, 0x00, "~S Z ~N ~C ~P"),
        r8Operation("XOR", opcode, r8, 0x90, 0x90, 0x00, "~S Z ~N ~C ~P"),
      ]
    : [
        r8Operation("XOR", opcode, r8, 0x03, 0x01, 0x02, "~S ~Z ~N ~C P"),
        r8Operation("XOR", opcode, r8, 0x03, 0x81, 0x82, "S ~Z ~N ~C ~P"),
      ];

List<Scenario> orR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("OR", opcode, r8, 0x00, 0x00, 0x00, "~S Z ~N ~C ~P"),
        r8Operation("OR", opcode, r8, 0x07, 0x07, 0x07, "~S ~Z ~N ~C P"),
        r8Operation("OR", opcode, r8, 0x90, 0x90, 0x90, "S ~Z ~N ~C ~P"),
      ]
    : [
        r8Operation("OR", opcode, r8, 0x02, 0x01, 0x03, "~S ~Z ~N ~C ~P"),
        r8Operation("OR", opcode, r8, 0x02, 0x81, 0x83, "S ~Z ~N ~C P"),
      ];

List<Scenario> cpR8(int opcode, int r8) => r8 == Z80a.R_A
    ? [
        r8Operation("CP", opcode, r8, 20, 20, 20, "~S Z N ~C ~P"),
        r8Operation("CP", opcode, r8, 128, 128, 128, "~S Z N ~C ~P"),
      ]
    : [
        r8Operation("CP", opcode, r8, 10, 2, 10, "~S ~Z N ~C ~P"),
        r8Operation("CP", opcode, r8, 129, 2, 129, "~S ~Z N ~C P"),
        r8Operation("CP", opcode, r8, 255, 254, 255, "~S ~Z N ~C ~P"),
        r8Operation("CP", opcode, r8, 3, 5, 3, "S ~Z N C ~P"),
      ];

Scenario nOperation(String name, int opcode, int aValue, int nValue, int result,
        String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name -> ($aValue)',
      [opcode, nValue],
      initialState: State(
        register8Values: {
          Z80a.R_A: aValue,
        },
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Z80a.R_A: result,
        },
        flags: flags,
        pc: 2,
      ),
    );

List<Scenario> addAN(int opcode) => [
      nOperation("ADD A, N", opcode, 10, 2, 12, "~S ~Z ~N ~C ~P"),
      nOperation("ADD A, N", opcode, 127, 2, 129, "S ~Z ~N ~C P"),
      nOperation("ADD A, N", opcode, 254, 2, 0, "~S Z ~N C ~P"),
    ];

List<Scenario> adcAN(int opcode) => [
      nOperation("ADC A, N", opcode, 10, 10, 20, "~S ~Z ~N ~C ~P",
          inFlags: "~C"),
      nOperation("ADC A, N", opcode, 10, 10, 21, "~S ~Z ~N ~C ~P",
          inFlags: "C"),
      nOperation("ADC A, N", opcode, 128, 128, 0, "~S Z ~N C P", inFlags: "~C"),
      nOperation("ADC A, N", opcode, 128, 128, 1, "~S ~Z ~N C P", inFlags: "C"),
    ];

List<Scenario> subAN(int opcode) => [
      nOperation("SUB N", opcode, 10, 2, 8, "~S ~Z N ~C ~P"),
      nOperation("SUB N", opcode, 129, 2, 127, "~S ~Z N ~C P"),
      nOperation("SUB N", opcode, 255, 254, 1, "~S ~Z N ~C ~P"),
      nOperation("SUB N", opcode, 3, 5, 254, "S ~Z N C ~P"),
    ];

List<Scenario> sbcAN(int opcode) => [
      nOperation("SBC N", opcode, 10, 10, 0, "~S Z N ~C ~P", inFlags: "~C"),
      nOperation("SBC N", opcode, 10, 10, 255, "S ~Z N C ~P", inFlags: "C"),
      nOperation("SBC N", opcode, 128, 128, 0, "~S Z N ~C ~P", inFlags: "~C"),
      nOperation("SBC N", opcode, 128, 128, 255, "S ~Z N C ~P", inFlags: "C"),
    ];

List<Scenario> andAN(int opcode) => [
      nOperation("AND A, N", opcode, 0x03, 0x01, 0x01, "~S ~Z ~N ~C P"),
      nOperation("AND A, N", opcode, 0x03, 0x04, 0x00, "~S Z ~N ~C ~P"),
    ];

List<Scenario> xorN(int opcode) => [
      nOperation("XOR N", opcode, 0x03, 0x01, 0x02, "~S ~Z ~N ~C P"),
      nOperation("XOR N", opcode, 0x03, 0x81, 0x82, "S ~Z ~N ~C ~P"),
    ];

List<Scenario> orN(int opcode) => [
      nOperation("OR N", opcode, 0x02, 0x01, 0x03, "~S ~Z ~N ~C ~P"),
      nOperation("OR N", opcode, 0x02, 0x81, 0x83, "S ~Z ~N ~C P"),
    ];

List<Scenario> cpN(int opcode) => [
      nOperation("CP N", opcode, 10, 2, 10, "~S ~Z N ~C ~P"),
      nOperation("CP N", opcode, 129, 2, 129, "~S ~Z N ~C P"),
      nOperation("CP N", opcode, 255, 254, 255, "~S ~Z N ~C ~P"),
      nOperation("CP N", opcode, 3, 5, 3, "S ~Z N C ~P"),
    ];

List<Scenario> exMSPHL(int opcode, int rhxy) => [
      Scenario(
        "EX (SP), ${Z80a.r16Names[rhxy]}",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {Z80a.R_SP: Scenario.RAM_START, rhxy: 10000},
          ram: [12, 34],
        ),
        expectedState: State(
          register16Values: {
            rhxy: w(12, 34),
          },
          ram: [lo(10000), hi(10000)],
          pc: isIXIY(rhxy) ? 2 : 1,
        ),
      )
    ];

List<Scenario> jpMHL(int opcode, int rhxy) => [
      Scenario(
        "JP (${Z80a.r16Names[rhxy]})",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: Scenario.RAM_START,
          },
          ram: [12, 34],
        ),
        expectedState: State(
          ram: [12, 34],
          pc: w(12, 34),
        ),
      )
    ];

List<Scenario> exDEHL(int opcode) => [
      Scenario(
        "EX DE, HL",
        [opcode],
        initialState: State(
          register16Values: {
            Z80a.R_DE: 10000,
            Z80a.R_HL: 20000,
          },
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_DE: 20000,
            Z80a.R_HL: 10000,
          },
          pc: 1,
        ),
      )
    ];

List<Scenario> ldSPHL(int opcode, int rhxy) => [
      Scenario(
        "LD SP, ${Z80a.r16Names[rhxy]}",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: 10000,
          },
        ),
        expectedState: State(
          register16Values: {
            Z80a.R_SP: 10000,
          },
          pc: isIXIY(rhxy) ? 2 : 1,
        ),
      )
    ];

List<Scenario> ldIXYNN(int opcode, int rxy) => [
      Scenario(
        "LD IXY, NN",
        [...ixyPrefix(rxy), opcode, lo(10000), hi(10000)],
        initialState: State(),
        expectedState: State(
          register16Values: {
            rxy: 10000,
          },
          pc: 4,
        ),
      )
    ];

List<Scenario> ldMNNIXY(int opcode, int rxy) => [
      Scenario(
        "LD (NN), ${Z80a.r16Names[rxy]}",
        [
          ...ixyPrefix(rxy),
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          register16Values: {
            rxy: 10000,
          },
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [lo(10000), hi(10000)],
          pc: 4,
        ),
      )
    ];

List<Scenario> ldIXYMN(int opcode, rxy) => [
      Scenario(
        'LD ${Z80a.r16Names[rxy]}, (NN)',
        [
          ...ixyPrefix(rxy),
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          ram: [12, 34],
        ),
        expectedState: State(
          register16Values: {rxy: w(12, 34)},
          ram: [12, 34],
          pc: 4,
        ),
      )
    ];

List<Scenario> ldMIXYdN(int opcode, rxy) => [
      Scenario(
        'LD ${Z80a.r16Names[rxy]}, (NN)',
        [...ixyPrefix(rxy), opcode, 1, 12],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 12],
          pc: 4,
        ),
      )
    ];

List<Scenario> ldR8MIXYd(int opcode, int r8, int rxy) => [
      Scenario(
        'LD ${Z80a.r8Names[r8]}, (${Z80a.r16Names[rxy]} + d)',
        [...ixyPrefix(rxy), opcode, 1],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          ram: [0, 12],
        ),
        expectedState: State(
          ram: [0, 12],
          register8Values: {r8: 12},
          pc: 3,
        ),
      )
    ];

List<Scenario> ldMIXYdR8(int opcode, int r8, int rxy) => [
      Scenario(
        'LD (${Z80a.r16Names[rxy]} + d), ${Z80a.r8Names[r8]}',
        [...ixyPrefix(rxy), opcode, 1],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          register8Values: {r8: 12},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 12],
          pc: 3,
        ),
      )
    ];

Scenario inR8CSpec(int opcode, int r8, int value, String flags) => Scenario(
      'IN ${Z80a.r8Names[r8]}, (C) => ($value)',
      [0xED, opcode],
      initialState: State(
        register8Values: {Z80a.R_C: 254},
        ports: {254: value},
      ),
      expectedState: State(
        register8Values: {r8: value},
        pc: 2,
        flags: flags,
      ),
    );

List<Scenario> inR8C(int opcode, int r8) => [
      inR8CSpec(opcode, r8, 0x07, "~S ~Z ~H P ~N"),
      inR8CSpec(opcode, r8, 0x00, "~S Z ~H ~P ~N"),
      inR8CSpec(opcode, r8, 0x80, "S ~Z ~H P ~N"),
    ];

List<Scenario> outCR8(int opcode, int r8) => [
      Scenario(
        'OUT (C) ${Z80a.r8Names[r8]}',
        [0xED, opcode],
        initialState: State(
          register8Values: {Z80a.R_C: 254, r8: r8 == Z80a.R_C ? 254 : 12},
        ),
        expectedState: State(
          ports: {254: r8 == Z80a.R_C ? 254 : 12},
          pc: 2,
        ),
      )
    ];

List<Scenario> sbcHLR16(int opcode, int r16) => r16 == Z80a.R_HL
    ? [
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 30000, 0, "~S Z ~P ~C",
            inFlags: "~C", prefix: 0xED),
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 30000, 65535, "S ~Z P C",
            inFlags: "C", prefix: 0xED),
      ]
    : [
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 12000, 18000, "~S ~Z ~P ~C",
            inFlags: "~C", prefix: 0xED),
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 30000, 0, "~S Z ~P ~C",
            inFlags: "~C", prefix: 0xED),
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 40000, 55536, "S ~Z ~P C",
            inFlags: "~C", prefix: 0xED),
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 12000, 17999, "~S ~Z ~P ~C",
            inFlags: "C", prefix: 0xED),
        changeR16R16Spec(
            "SBC", opcode, Z80a.R_HL, r16, 30000, 30000, 65535, "S ~Z P C",
            inFlags: "C", prefix: 0xED),
      ];

Scenario bitNR8R8Spec(int opcode, int bit, int r8, int value, String flags) =>
    Scenario(
      "BIT $bit, ${Z80a.r8Names[r8]} (${toBinary8(value)})",
      [Z80a.BIT_OPCODES, opcode],
      initialState: State(
        register8Values: {r8: value},
      ),
      expectedState: State(flags: flags),
    );

Scenario bitNR8HLSpec(int opcode, int bit, int value, String flags) => Scenario(
      "BIT $bit, (HL) (${toBinary8(value)})",
      [Z80a.BIT_OPCODES, opcode],
      initialState: State(
        register16Values: {Z80a.R_HL: Scenario.RAM_START + 1},
        ram: [0, value],
      ),
      expectedState: State(
        ram: [0, value],
        flags: flags,
      ),
    );

Scenario bitNR8Spec(int opcode, int bit, int r8, int value, String flags) =>
    changeR8("BIT $bit", opcode, r8, value, value, flags,
        prefix: Z80a.BIT_OPCODES);

List<Scenario> bitNR8(int opcode, int bit, int r8) => [
      bitNR8Spec(opcode, bit, r8, 0xFF ^ Z80a.bitMask[bit], "Z H ~N"),
      bitNR8Spec(opcode, bit, r8, Z80a.bitMask[bit], "~Z H ~N")
    ];

List<Scenario> bit0R8(int opcode, int r8) => bitNR8(opcode, 0, r8);
List<Scenario> bit1R8(int opcode, int r8) => bitNR8(opcode, 1, r8);
List<Scenario> bit2R8(int opcode, int r8) => bitNR8(opcode, 2, r8);
List<Scenario> bit3R8(int opcode, int r8) => bitNR8(opcode, 3, r8);
List<Scenario> bit4R8(int opcode, int r8) => bitNR8(opcode, 4, r8);
List<Scenario> bit5R8(int opcode, int r8) => bitNR8(opcode, 5, r8);
List<Scenario> bit6R8(int opcode, int r8) => bitNR8(opcode, 6, r8);
List<Scenario> bit7R8(int opcode, int r8) => bitNR8(opcode, 7, r8);

Scenario resNR8Spec(int opcode, int bit, int r8, int value, int result) =>
    changeR8("RES $bit", opcode, r8, value, result, "",
        prefix: Z80a.BIT_OPCODES);

List<Scenario> resNR8(int opcode, int bit, int r8) => [
      resNR8Spec(opcode, bit, r8, Z80a.bitMask[bit], 0x00),
      resNR8Spec(opcode, bit, r8, 0x00, 0x00),
    ];

List<Scenario> res0R8(int opcode, int r8) => resNR8(opcode, 0, r8);
List<Scenario> res1R8(int opcode, int r8) => resNR8(opcode, 1, r8);
List<Scenario> res2R8(int opcode, int r8) => resNR8(opcode, 2, r8);
List<Scenario> res3R8(int opcode, int r8) => resNR8(opcode, 3, r8);
List<Scenario> res4R8(int opcode, int r8) => resNR8(opcode, 4, r8);
List<Scenario> res5R8(int opcode, int r8) => resNR8(opcode, 5, r8);
List<Scenario> res6R8(int opcode, int r8) => resNR8(opcode, 6, r8);
List<Scenario> res7R8(int opcode, int r8) => resNR8(opcode, 7, r8);

Scenario setNR8Spec(int opcode, int bit, int r8, int value, int result) =>
    changeR8("SET $bit", opcode, r8, value, result, "",
        prefix: Z80a.BIT_OPCODES);

List<Scenario> setNR8(int opcode, int bit, int r8) => [
      resNR8Spec(opcode, bit, r8, 0x00, Z80a.bitMask[bit]),
      resNR8Spec(opcode, bit, r8, Z80a.bitMask[bit], Z80a.bitMask[bit]),
    ];

List<Scenario> set0R8(int opcode, int r8) => setNR8(opcode, 0, r8);
List<Scenario> set1R8(int opcode, int r8) => setNR8(opcode, 1, r8);
List<Scenario> set2R8(int opcode, int r8) => setNR8(opcode, 2, r8);
List<Scenario> set3R8(int opcode, int r8) => setNR8(opcode, 3, r8);
List<Scenario> set4R8(int opcode, int r8) => setNR8(opcode, 4, r8);
List<Scenario> set5R8(int opcode, int r8) => setNR8(opcode, 5, r8);
List<Scenario> set6R8(int opcode, int r8) => setNR8(opcode, 6, r8);
List<Scenario> set7R8(int opcode, int r8) => setNR8(opcode, 7, r8);
