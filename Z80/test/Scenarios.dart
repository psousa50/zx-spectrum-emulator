import 'package:Z80/Cpu/Registers.dart';
import 'package:Z80/Util.dart';
import 'package:Z80/Cpu/Z80.dart';
import 'Scenario.dart';

log(String m, value) {
  print(m);
  print(value);
  return value;
}

bool isIX(int rhxy) =>
    [Registers.R_IX, Registers.R_IX_H, Registers.R_IX_L].contains(rhxy);

bool isIY(int rhxy) =>
    [Registers.R_IY, Registers.R_IY_H, Registers.R_IY_L].contains(rhxy);

bool isIXIY(int rhxy) => isIX(rhxy) || isIY(rhxy);

bool isMIXIY(int rhxy) => rhxy == Registers.R_MIXd || rhxy == Registers.R_MIYd;

int rMIXY(int rxy) => rxy == Registers.R_MIXd ? Registers.R_IX : Registers.R_IY;

List<int> ixyPrefix(int rhxy) => [
      if ([Registers.R_IX, Registers.R_IX_H, Registers.R_IX_L].contains(rhxy))
        Z80.IX_PREFIX,
      if ([Registers.R_IY, Registers.R_IY_H, Registers.R_IY_L].contains(rhxy))
        Z80.IY_PREFIX,
    ];

List<int> ixyPrefix2(int rhxy1, int rhxy2) =>
    Set.of([...ixyPrefix(rhxy1), ...ixyPrefix(rhxy2)]).toList();

List<Scenario> nop(int opcode) => [
      Scenario(
        "NOP",
        [opcode],
        initialState: State(),
        expectedState: State(),
      )
    ];

List<Scenario> ldR8N(int opcode, int r8) => [
      Scenario(
        'LD ${Registers.r8Names[r8]}, NN',
        [...ixyPrefix(r8), opcode, 12],
        initialState: State(),
        expectedState: State(
          register8Values: {r8: 12},
        ),
      )
    ];

List<Scenario> ldMNNR16(int opcode, int r16, {int? prefix}) => [
      Scenario(
        'LD (NN), ${Registers.r16Names[r16]}',
        [
          if (prefix != null) prefix,
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          register16Values: {r16: 10000},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [lo(10000), hi(10000)],
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
          register8Values: {Registers.R_A: 100},
          ram: [0],
        ),
        expectedState: State(
          ram: [100],
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
          register8Values: {Registers.R_A: 12},
          ram: [12],
        ),
      )
    ];

List<Scenario> ldMHLN(int opcode) => [
      Scenario(
        'LD (HL), N',
        [opcode, 12],
        initialState: State(
          register16Values: {Registers.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [12],
        ),
      )
    ];

List<Scenario> ldR16MNN(int opcode, int r16, {int? prefix}) => [
      Scenario(
        'LD HL, (NN)',
        [
          if (prefix != null) prefix,
          opcode,
          lo(Scenario.RAM_START),
          hi(Scenario.RAM_START),
        ],
        initialState: State(
          ram: [12, 34],
        ),
        expectedState: State(
          register16Values: {r16: littleEndian(12, 34)},
          ram: [12, 34],
        ),
      )
    ];

List<Scenario> ldR16NN(int opcode, int r16) => [
      Scenario(
        'LD ${Registers.r16Names[r16]}, NN',
        [opcode, 12, 34],
        initialState: State(),
        expectedState: State(
          register16Values: {r16: 34 * 256 + 12},
        ),
      )
    ];

Scenario changeR16R16Spec(String name, int opcode, int rhxy, int r16,
        int hxyValue, int r16Value, int result, String flags,
        {String inFlags = "", int? prefix}) =>
    Scenario(
      "$name ${Registers.r16Names[rhxy]}, ${Registers.r16Names[r16]} => ($hxyValue $r16Value)",
      [...ixyPrefix(rhxy), if (prefix != null) prefix, opcode],
      initialState: State(
        register16Values: {rhxy: hxyValue, r16: r16Value},
        flags: inFlags,
      ),
      expectedState: State(
        register16Values: {
          rhxy: result,
        },
        flags: flags,
      ),
    );

List<Scenario> addHLR16(int opcode, int rhxy, int r16) => [
      changeR16R16Spec(
          "ADD", opcode, rhxy, r16, 0x0E00, 0x0100, 0x0F00, "~H ~N ~C"),
      changeR16R16Spec("ADD", opcode, rhxy, r16, 0xFFFF, 2, 1, "H ~N C"),
      changeR16R16Spec(
          "ADD", opcode, rhxy, r16, 0x0F00, 0x0100, 0x1000, "H ~N ~C"),
    ];

Scenario addHLHLSpec(
        int opcode, int rhxy, int hxyValue, int result, String flags) =>
    Scenario(
      "ADD ${Registers.r16Names[rhxy]}, ${Registers.r16Names[rhxy]}",
      [...ixyPrefix(rhxy), opcode],
      initialState: State(register16Values: {rhxy: hxyValue}),
      expectedState: State(
        register16Values: {rhxy: result},
        flags: flags,
      ),
    );

List<Scenario> addHLHL(int opcode, int rhxy) => [
      addHLHLSpec(opcode, rhxy, 0x0200, 0x0400, "~H ~N ~C"),
      addHLHLSpec(opcode, rhxy, 0xFFFF, 0xFFFE, "H ~N C"),
    ];

Scenario changeR16(String name, int opcode, int rhxy, int value, int result) =>
    Scenario(
      '$name ${Registers.r16Names[rhxy]}',
      [...ixyPrefix(rhxy), opcode],
      initialState: State(
        register16Values: {rhxy: value},
      ),
      expectedState: State(
        register16Values: {rhxy: result},
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
        {String inFlags = "", int? prefix}) =>
    Scenario(
      '$name ${Registers.r8Names[r8]} ($value $result)',
      [...ixyPrefix(r8), if (prefix != null) prefix, opcode],
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
        {String inFlags = "", int? prefix}) =>
    Scenario(
      '$name (HL)',
      [if (prefix != null) prefix, opcode],
      initialState: State(
        register16Values: {Registers.R_HL: Scenario.RAM_START},
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
        {String inFlags = "", int? prefix}) =>
    Scenario(
      '$name (IX+d)',
      isIXIY(rxy) && prefix != null
          ? [...ixyPrefix(rxy), prefix, 0xFE, opcode]
          : [...ixyPrefix(rxy), if (prefix != null) prefix, opcode, 0xFE],
      initialState: State(
        register16Values: {rxy: Scenario.RAM_START + 3},
        ram: [0, value],
        flags: inFlags,
      ),
      expectedState: State(
        ram: [0, result],
        flags: flags,
      ),
    );

Scenario changeR8(
        String name, int opcode, int r8, int value, int result, String flags,
        {String inFlags = "", int? prefix}) =>
    isMIXIY(r8)
        ? changeR8IXYd(name, opcode, rMIXY(r8), value, result, flags,
            inFlags: inFlags, prefix: prefix)
        : r8 == Registers.R_MHL
            ? changeR8HL(name, opcode, value, result, flags,
                inFlags: inFlags, prefix: prefix)
            : changeR8R8(name, opcode, r8, value, result, flags,
                inFlags: inFlags, prefix: prefix);

List<Scenario> incR8(int opcode, int r8) => [
      changeR8("INC", opcode, r8, 10, 11, "~S ~Z ~H ~P ~N"),
      changeR8("INC", opcode, r8, 255, 0, "~S Z H ~P ~N"),
      changeR8("INC", opcode, r8, 127, 128, "S ~Z H P ~N"),
      changeR8("INC", opcode, r8, 130, 131, "S ~Z ~H ~P ~N"),
    ];

List<Scenario> decR8(int opcode, int r8) => [
      changeR8("DEC", opcode, r8, 10, 9, "~S ~Z ~H ~P N"),
      changeR8("DEC", opcode, r8, 1, 0, "~S Z ~H ~P N"),
      changeR8("DEC", opcode, r8, 0, 255, "S ~Z H ~P N"),
      changeR8("DEC", opcode, r8, 128, 127, "~S ~Z H P N"),
      changeR8("DEC", opcode, r8, 131, 130, "S ~Z ~H ~P N"),
    ];

List<Scenario> exAFAFt(int opcode) => [
      Scenario(
        'EX AF, AF' '',
        [opcode],
        initialState: State(
          register16Values: {Registers.R_AF: 1000, Registers.R_AFt: 1500},
        ),
        expectedState: State(
          register16Values: {Registers.R_AF: 1500, Registers.R_AFt: 1000},
        ),
      )
    ];

List<Scenario> ldR16A(int opcode, int r16) => [
      Scenario(
        'LD (${Registers.r16Names[r16]}), A',
        [opcode],
        initialState: State(
          register8Values: {Registers.R_A: 55},
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 55],
        ),
      )
    ];

List<Scenario> ldAR16(int opcode, int r16) => [
      Scenario(
        'LD A, (${Registers.r16Names[r16]})',
        [opcode],
        initialState: State(
          register16Values: {r16: Scenario.RAM_START + 1},
          ram: [0, 55],
        ),
        expectedState: State(
          register8Values: {Registers.R_A: 55},
          ram: [0, 55],
        ),
      )
    ];

List<Scenario> rlca(int opcode) => [
      changeR8("RLCA", 0x07, Registers.R_A, binary("00010011"),
          binary("00100110"), "~H ~N ~C"),
      changeR8("RLCA", 0x07, Registers.R_A, binary("10010011"),
          binary("00100111"), "~H ~N C"),
    ];

List<Scenario> rrca(int opcode) => [
      changeR8("RRCA", 0x0F, Registers.R_A, binary("10100010"),
          binary("01010001"), "~H ~N ~C"),
      changeR8("RRCA", 0x0F, Registers.R_A, binary("10100011"),
          binary("11010001"), "~H ~N C"),
    ];

List<Scenario> rla(int opcode) => [
      changeR8("RLA", 0x17, Registers.R_A, binary("00100010"),
          binary("01000100"), "~H ~N ~C",
          inFlags: "~C"),
      changeR8("RLA", 0x17, Registers.R_A, binary("10100010"),
          binary("01000100"), "~H ~N C",
          inFlags: "~C"),
      changeR8("RLA", 0x17, Registers.R_A, binary("00100010"),
          binary("01000101"), "~H ~N ~C",
          inFlags: "C"),
      changeR8("RLA", 0x17, Registers.R_A, binary("10100010"),
          binary("01000101"), "~H ~N C",
          inFlags: "C"),
    ];

List<Scenario> rra(int opcode) => [
      changeR8("RRA", 0x1F, Registers.R_A, binary("00100010"),
          binary("00010001"), "~H ~N ~C",
          inFlags: "~C"),
      changeR8("RRA", 0x1F, Registers.R_A, binary("00100011"),
          binary("00010001"), "~H ~N C",
          inFlags: "~C"),
      changeR8("RRA", 0x1F, Registers.R_A, binary("00100010"),
          binary("10010001"), "~H ~N ~C",
          inFlags: "C"),
      changeR8("RRA", 0x1F, Registers.R_A, binary("00100011"),
          binary("10010001"), "~H ~N C",
          inFlags: "C"),
    ];

List<Scenario> rlR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00010011"), binary("00100110"),
          "~S ~Z ~H ~P ~N ~C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("11010011"), binary("10100110"),
          "S ~Z ~H P ~N C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10000000"), binary("00000000"),
          "~S Z ~H P ~N C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10010011"), binary("00100111"),
          "~S ~Z ~H P ~N C",
          inFlags: "C", prefix: prefix),
      changeR8(name, opcode, r8, binary("00010011"), binary("00100111"),
          "~S ~Z ~H P ~N ~C",
          inFlags: "C", prefix: prefix),
    ];

List<Scenario> rrR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("10100010"), binary("01010001"),
          "~S ~Z ~H ~P ~N ~C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10100011"), binary("01010001"),
          "~S ~Z ~H ~P ~N C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("00000001"), binary("00000000"),
          "~S Z ~H P ~N C",
          inFlags: "~C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10100010"), binary("11010001"),
          "S ~Z ~H P ~N ~C",
          inFlags: "C", prefix: prefix),
      changeR8(name, opcode, r8, binary("10100011"), binary("11010001"),
          "S ~Z ~H P ~N C",
          inFlags: "C", prefix: prefix),
    ];

List<Scenario> rlcR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00100010"), binary("01000100"),
          "~S ~Z ~H P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("11100010"), binary("11000101"),
          "S ~Z ~H P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~H P ~N ~C",
          prefix: prefix),
    ];

List<Scenario> rrcR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00100010"), binary("00010001"),
          "~S ~Z ~H P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100011"), binary("10010001"),
          "S ~Z ~H ~P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~H P ~N ~C",
          prefix: prefix),
    ];

List<Scenario> slaR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("01001100"),
          "~S ~Z ~H ~P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("11100011"), binary("11000110"),
          "S ~Z ~H P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10000000"), binary("00000000"),
          "~S Z ~H P ~N C",
          prefix: prefix),
    ];

List<Scenario> sraR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("00010011"),
          "~S ~Z ~H ~P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100111"), binary("00010011"),
          "~S ~Z ~H ~P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100110"), binary("11010011"),
          "S ~Z ~H ~P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100111"), binary("11010011"),
          "S ~Z ~H ~P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~H P ~N ~C",
          prefix: prefix),
    ];

List<Scenario> srlR8Spec(String name, int opcode, int r8, {int? prefix}) => [
      changeR8(name, opcode, r8, binary("00100110"), binary("00010011"),
          "~S ~Z ~H ~P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00100111"), binary("00010011"),
          "~S ~Z ~H ~P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100110"), binary("01010011"),
          "~S ~Z ~H P ~N ~C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("10100111"), binary("01010011"),
          "~S ~Z ~H P ~N C",
          prefix: prefix),
      changeR8(name, opcode, r8, binary("00000000"), binary("00000000"),
          "~S Z ~H P ~N ~C",
          prefix: prefix),
    ];

List<Scenario> rlcR8(int opcode, int r8) =>
    rlcR8Spec("RLC", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> rrcR8(int opcode, int r8) =>
    rrcR8Spec("RRC", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> rlR8(int opcode, int r8) =>
    rlR8Spec("RL", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> rrR8(int opcode, int r8) =>
    rrR8Spec("RR", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> slaR8(int opcode, int r8) =>
    slaR8Spec("SLA", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> sraR8(int opcode, int r8) =>
    sraR8Spec("SRA", opcode, r8, prefix: Z80.BIT_OPCODES);

List<Scenario> srlR8(int opcode, int r8) =>
    srlR8Spec("SRL", opcode, r8, prefix: Z80.BIT_OPCODES);

Scenario rldrrdSpec(String name, int opcode, int a, int mHL, int aResult,
        int mHlResult, String flags) =>
    Scenario(
      name,
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_A: a},
        register16Values: {Registers.R_HL: Scenario.RAM_START},
        ram: [mHL],
      ),
      expectedState: State(
        register8Values: {Registers.R_A: aResult},
        register16Values: {Registers.R_HL: Scenario.RAM_START},
        ram: [mHlResult],
        flags: flags,
      ),
    );

List<Scenario> rld(int opcode) => [
      rldrrdSpec("RLD", opcode, binary("01111010"), binary("10100101"),
          binary("01111010"), binary("01011010"), "~S ~Z ~H ~P ~N"),
      rldrrdSpec("RLD", opcode, binary("00001010"), binary("00000101"),
          binary("00000000"), binary("01011010"), "~S Z ~H P ~N"),
      rldrrdSpec("RLD", opcode, binary("10001010"), binary("00000101"),
          binary("10000000"), binary("01011010"), "S ~Z ~H ~P ~N"),
    ];

List<Scenario> rrd(int opcode) => [
      rldrrdSpec("RRD", opcode, binary("10110101"), binary("11000110"),
          binary("10110110"), binary("01011100"), "S ~Z ~H ~P ~N"),
      rldrrdSpec("RRD", opcode, binary("00000101"), binary("11000000"),
          binary("00000000"), binary("01011100"), "~S Z ~H P ~N"),
    ];

List<Scenario> ldR8R8(int opcode, int r8Dest, int r8Source) => [
      Scenario(
        'LD ${Registers.r8Names[r8Dest]}, ${Registers.r8Names[r8Source]}',
        [...ixyPrefix2(r8Source, r8Dest), opcode],
        initialState: State(
          register8Values: {r8Source: 10, r8Dest: r8Source == r8Dest ? 10 : 5},
        ),
        expectedState: State(
          register8Values: {r8Source: 10, r8Dest: 10},
        ),
      )
    ];

List<Scenario> ldR8MHL(int opcode, int r8) => [
      Scenario(
        'LD ${Registers.r8Names[r8]}, (HL)',
        [opcode],
        initialState: State(
          register16Values: {Registers.R_HL: Scenario.RAM_START},
          ram: [12],
        ),
        expectedState: State(
          ram: [12],
          register8Values: {r8: 12},
        ),
      )
    ];

List<Scenario> ldMHLR8(int opcode, int r8) => [
      Scenario(
        'LD (HL), ${Registers.r8Names[r8]}',
        [opcode],
        initialState: State(
          register8Values: {r8: 12},
          register16Values: {Registers.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [12],
        ),
      )
    ];

List<Scenario> ldMHLH(int opcode) => [
      Scenario(
        'LD (HL), H',
        [opcode],
        initialState: State(
          register16Values: {Registers.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [hi(Scenario.RAM_START)],
        ),
      )
    ];

List<Scenario> ldMHLL(int opcode) => [
      Scenario(
        'LD (HL), H',
        [opcode],
        initialState: State(
          register16Values: {Registers.R_HL: Scenario.RAM_START},
          ram: [0],
        ),
        expectedState: State(
          ram: [lo(Scenario.RAM_START)],
        ),
      )
    ];

List<Scenario> callNN(int opcode) => [
      Scenario(
        "CALL NN",
        [opcode, 12, 34],
        initialState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START + 2},
          ram: [0, 0, 0],
          pc: 5,
        ),
        expectedState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START + 0},
          ram: [lo(8), hi(8), 0],
          pc: littleEndian(12, 34),
        ),
      )
    ];

Scenario retSpec(String name, int opcode, {int? prefix}) => Scenario(
      name,
      [if (prefix != null) prefix, opcode],
      initialState: State(
        register16Values: {Registers.R_SP: Scenario.RAM_START + 0},
        ram: [lo(12345), hi(12345), 0],
      ),
      expectedState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START + 2},
          ram: [lo(12345), hi(12345), 0],
          pc: 12345),
    );

List<Scenario> ret(int opcode) => [retSpec("RET", opcode)];
List<Scenario> retn(int opcode) =>
    [retSpec("RETN", opcode, prefix: Z80.EXTENDED_OPCODES)];
List<Scenario> reti(int opcode) =>
    [retSpec("RETI", opcode, prefix: Z80.EXTENDED_OPCODES)];

Scenario callCCNNJump(int opcode, String flag) => Scenario(
      "CALL $flag, NN",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
        register16Values: {Registers.R_SP: Scenario.RAM_START + 2},
        ram: [0, 0, 0],
        pc: 5,
      ),
      expectedState: State(
        register16Values: {Registers.R_SP: Scenario.RAM_START + 0},
        ram: [lo(8), hi(8), 0],
        pc: littleEndian(12, 34),
      ),
    );

Scenario callCCNNNotJump(int opcode, String flag) => Scenario(
      "CALL ~$flag, NN",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(),
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
        register16Values: {Registers.R_SP: Scenario.RAM_START + 0},
        ram: [lo(12345), hi(12345), 0],
      ),
      expectedState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START + 2},
          ram: [lo(12345), hi(12345), 0],
          pc: 12345),
    );

Scenario retCCNotJump(int opcode, String flag) => Scenario(
      "RET ~$flag",
      [opcode],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(),
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
        pc: littleEndian(12, 34),
      ),
    );

Scenario jpCCNNNotJump(int opcode, String flag) => Scenario(
      "JP $flag",
      [opcode, 12, 34],
      initialState: State(
        flags: flag,
      ),
      expectedState: State(),
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
          pc: littleEndian(12, 34),
        ),
      )
    ];

List<Scenario> popR16(int opcode, int rhxy) => [
      Scenario(
        'POP ${Registers.r16Names[rhxy]}',
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START + 0},
          ram: [lo(12345), hi(12345), 0],
        ),
        expectedState: State(
          register16Values: {
            Registers.R_SP: Scenario.RAM_START + 2,
            rhxy: 12345,
          },
          ram: [lo(12345), hi(12345), 0],
        ),
      )
    ];

List<Scenario> exx(int opcode) => [
      Scenario(
        'EXX',
        [opcode],
        initialState: State(
          register16Values: {
            Registers.R_BC: 10000,
            Registers.R_DE: 20000,
            Registers.R_HL: 30000,
            Registers.R_BCt: 11111,
            Registers.R_DEt: 22222,
            Registers.R_HLt: 33333,
          },
        ),
        expectedState: State(
          register16Values: {
            Registers.R_BC: 11111,
            Registers.R_DE: 22222,
            Registers.R_HL: 33333,
            Registers.R_BCt: 10000,
            Registers.R_DEt: 20000,
            Registers.R_HLt: 30000,
          },
        ),
      ),
    ];

List<Scenario> pushR16(int opcode, int rhxy) => [
      Scenario(
        'PUSH ${Registers.r16Names[rhxy]}',
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: 10000,
            Registers.R_SP: Scenario.RAM_START + 2,
          },
          ram: [0, 0, 0],
        ),
        expectedState: State(
          register16Values: {
            Registers.R_SP: Scenario.RAM_START + 0,
          },
          ram: [lo(10000), hi(10000), 0],
        ),
      )
    ];

List<Scenario> rstNN(int opcode, int rst) => [
      Scenario(
        'RST $rst',
        [opcode],
        initialState: State(
          register16Values: {
            Registers.R_SP: Scenario.RAM_START + 2,
          },
          ram: [0, 0, 0],
          pc: 5,
        ),
        expectedState: State(
          register16Values: {
            Registers.R_SP: Scenario.RAM_START + 0,
          },
          ram: [lo(6), hi(6), 0],
          pc: rst,
        ),
      )
    ];

Scenario djnzJumpSpec(int opcode, int jump, int initialPC, int? finalPC) =>
    Scenario(
      "DJNZ n",
      [opcode, jump],
      initialState: State(
        register8Values: {Registers.R_B: 5},
        pc: initialPC,
      ),
      expectedState: State(
        register8Values: {Registers.R_B: 4},
        pc: finalPC,
      ),
    );

List<Scenario> djnzJump(int opcode) => [
      djnzJumpSpec(opcode, 3, 6, 11),
      djnzJumpSpec(opcode, 253, 6, 5),
    ];

Scenario djnzNoJump(int opcode) => Scenario(
      "DJNZ n",
      [opcode, 10],
      initialState: State(
        register8Values: {Registers.R_B: 1},
      ),
      expectedState: State(
        register8Values: {Registers.R_B: 0},
      ),
    );

List<Scenario> djnzN(int opcode) => [
      ...djnzJump(opcode),
      djnzNoJump(opcode),
    ];

Scenario jrNSpec(String name, int opcode, String flag, int jump, int initialPC,
        int? finalPC) =>
    Scenario(
      name,
      [opcode, jump],
      initialState: State(
        flags: flag,
        pc: initialPC,
      ),
      expectedState: State(
        pc: finalPC,
      ),
    );

List<Scenario> jrN(int opcode) => [
      jrNSpec("JR n", opcode, "", 3, 6, 11),
      jrNSpec("JR n", opcode, "", 253, 6, 5),
    ];

List<Scenario> jrCCNJump(int opcode, String flag) => [
      jrNSpec("JR $flag, nn", opcode, flag, 3, 6, 11),
      jrNSpec("JR $flag, nn", opcode, flag, 253, 6, 5),
    ];

Scenario jrCCNNoJump(int opcode, String flag) => Scenario(
      "JR $flag, nn",
      [opcode, 10],
      initialState: State(flags: flag),
      expectedState: State(),
    );

List<Scenario> jrCCNN(int opcode, String flag, bool jumpIfSet) => [
      ...jrCCNJump(opcode, jumpIfSet ? flag : '~$flag'),
      jrCCNNoJump(opcode, jumpIfSet ? '~$flag' : flag),
    ];

Scenario cplN(int opcode, int value, int result) => Scenario("CPL", [opcode],
    initialState: State(
      register8Values: {Registers.R_A: value},
    ),
    expectedState: State(
      register8Values: {Registers.R_A: result},
      flags: "N H",
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
        ));

List<Scenario> ccf(int opcode) => [
      flagsTest(opcode, "C N", "~C ~N"),
      flagsTest(opcode, "~C N", "C ~N"),
    ];

List<Scenario> scf(int opcode) => [
      flagsTest(opcode, "", "C ~N ~H"),
    ];

Scenario r8r8Operation(String name, int opcode, int r8, int aValue, int r8Value,
        int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name ${Registers.r8Names[r8]} -> ($aValue)',
      [...ixyPrefix(r8), opcode],
      initialState: State(
        register8Values: {
          Registers.R_A: aValue,
          r8: r8Value,
        },
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Registers.R_A: result,
        },
        flags: flags,
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
          Registers.R_A: aValue,
        },
        register16Values: {Registers.R_HL: Scenario.RAM_START},
        ram: [mhlValue],
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Registers.R_A: result,
        },
        ram: [mhlValue],
        flags: flags,
      ),
    );

Scenario r8IXYOperation(String name, int opcode, int rxy, int aValue,
        int mxyValue, int result, String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name (${Registers.r16Names[rxy]} + d) -> ($aValue)',
      [...ixyPrefix(rxy), opcode, 1],
      initialState: State(
        register8Values: {
          Registers.R_A: aValue,
        },
        register16Values: {rxy: Scenario.RAM_START},
        ram: [0, mxyValue],
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Registers.R_A: result,
        },
        ram: [0, mxyValue],
        flags: flags,
      ),
    );

Scenario r8Operation(String name, int opcode, int r8, int aValue, int r8Value,
        int result, String flags, {String inFlags = ""}) =>
    isMIXIY(r8)
        ? r8IXYOperation(
            name, opcode, rMIXY(r8), aValue, r8Value, result, flags,
            inFlags: inFlags)
        : r8 == Registers.R_MHL
            ? r8HLOperation(name, opcode, aValue, r8Value, result, flags,
                inFlags: inFlags)
            : r8r8Operation(name, opcode, r8, aValue, r8Value, result, flags,
                inFlags: inFlags);

List<Scenario> addAR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("ADD A,", opcode, r8, 10, 10, 20, "~S ~Z H ~P ~N ~C"),
        r8Operation("ADD A,", opcode, r8, 7, 7, 14, "~S ~Z ~H ~P ~N ~C"),
        r8Operation("ADD A,", opcode, r8, 128, 128, 0, "~S Z ~H P ~N C"),
      ]
    : [
        r8Operation("ADD A,", opcode, r8, 10, 2, 12, "~S ~Z ~H ~P ~N ~C"),
        r8Operation("ADD A,", opcode, r8, 127, 2, 129, "S ~Z H P ~N ~C"),
        r8Operation("ADD A,", opcode, r8, 254, 2, 0, "~S Z H ~P ~N C"),
      ];

List<Scenario> adcAR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("ADC A,", opcode, r8, 10, 10, 20, "~S ~Z H ~P ~N ~C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 128, 128, 0, "~S Z ~H P ~N C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 10, 10, 21, "~S ~Z H ~P ~N ~C",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 128, 128, 0, "~S Z ~H P ~N C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 128, 128, 1, "~S ~Z ~H P ~N C",
            inFlags: "C"),
      ]
    : [
        r8Operation("ADC A,", opcode, r8, 10, 2, 12, "~S ~Z ~H ~P ~N ~C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 10, 2, 13, "~S ~Z ~H ~P ~N ~C",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 127, 2, 129, "S ~Z H P ~N ~C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 127, 2, 130, "S ~Z H P ~N ~C",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 128, 127, 0, "~S Z ~H P ~N C",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 255, 255, 255, "S ~Z ~H ~P ~N C",
            inFlags: "C"),
        r8Operation("ADC A,", opcode, r8, 254, 2, 0, "~S Z H ~P ~N C",
            inFlags: "~C"),
        r8Operation("ADC A,", opcode, r8, 254, 1, 0, "~S Z H ~P ~N C",
            inFlags: "C"),
      ];

List<Scenario> subAR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("SUB", opcode, r8, 20, 20, 0, "~S Z ~H N ~P ~C"),
        r8Operation("SUB", opcode, r8, 128, 128, 0, "~S Z ~H N ~P ~C"),
      ]
    : [
        r8Operation("SUB", opcode, r8, 23, 8, 15, "~S ~Z H N ~P ~C"),
        r8Operation("SUB", opcode, r8, 10, 2, 8, "~S ~Z ~H N ~P ~C"),
        r8Operation("SUB", opcode, r8, 129, 2, 127, "~S ~Z H N P ~C"),
        r8Operation("SUB", opcode, r8, 255, 254, 1, "~S ~Z ~H N ~P ~C"),
        r8Operation("SUB", opcode, r8, 3, 5, 254, "S ~Z H N ~P C"),
      ];

List<Scenario> sbcAR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("SBC A,", opcode, r8, 10, 10, 0, "~S Z ~H ~P N ~C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 10, 10, 255, "S ~Z H ~P N C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 128, 128, 0, "~S Z ~H ~P N ~C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 128, 128, 255, "S ~Z H ~P N C",
            inFlags: "C"),
      ]
    : [
        r8Operation("SBC A,", opcode, r8, 10, 2, 8, "~S ~Z ~H ~P N ~C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 10, 2, 7, "~S ~Z ~H ~P N ~C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 23, 8, 14, "~S ~Z H ~P N ~C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 23, 7, 15, "~S ~Z H ~P N ~C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 255, 1, 254, "S ~Z ~H ~P N ~C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 255, 1, 253, "S ~Z ~H ~P N ~C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 255, 254, 1, "~S ~Z ~H ~P N ~C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 255, 254, 0, "~S Z ~H ~P N ~C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 3, 5, 254, "S ~Z H ~P N C",
            inFlags: "~C"),
        r8Operation("SBC A,", opcode, r8, 3, 5, 253, "S ~Z H ~P N C",
            inFlags: "C"),
        r8Operation("SBC A,", opcode, r8, 129, 2, 126, "~S ~Z H P N ~C",
            inFlags: "C"),
      ];

List<Scenario> andR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("AND", opcode, r8, 0x07, 0x07, 0x07, "~S ~Z H ~P ~N ~C"),
        r8Operation("AND", opcode, r8, 0x00, 0x00, 0x00, "~S Z H P ~N ~C"),
        r8Operation("AND", opcode, r8, 0x90, 0x90, 0x90, "S ~Z H P ~N ~C"),
      ]
    : [
        r8Operation("AND", opcode, r8, 0x03, 0x01, 0x01, "~S ~Z H ~P ~N ~C"),
        r8Operation("AND", opcode, r8, 0x03, 0x04, 0x00, "~S Z H P ~N ~C"),
      ];

List<Scenario> xorR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("XOR", opcode, r8, 0x07, 0x07, 0x00, "~S Z ~H P ~N ~C"),
        r8Operation("XOR", opcode, r8, 0x90, 0x90, 0x00, "~S Z ~H P ~N ~C"),
      ]
    : [
        r8Operation("XOR", opcode, r8, 0x03, 0x01, 0x02, "~S ~Z ~H ~P ~N ~C"),
        r8Operation("XOR", opcode, r8, 0x03, 0x81, 0x82, "S ~Z ~H P ~N ~C"),
      ];

List<Scenario> orR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("OR", opcode, r8, 0x00, 0x00, 0x00, "~S Z ~H P ~N ~C"),
        r8Operation("OR", opcode, r8, 0x07, 0x07, 0x07, "~S ~Z ~H ~P ~N ~C"),
        r8Operation("OR", opcode, r8, 0x90, 0x90, 0x90, "S ~Z ~H P ~N ~C"),
      ]
    : [
        r8Operation("OR", opcode, r8, 0x02, 0x01, 0x03, "~S ~Z ~H P ~N ~C"),
        r8Operation("OR", opcode, r8, 0x02, 0x81, 0x83, "S ~Z ~H ~P ~N ~C"),
      ];

List<Scenario> cpR8(int opcode, int r8) => r8 == Registers.R_A
    ? [
        r8Operation("CP", opcode, r8, 20, 20, 20, "~S Z ~H ~P N ~C"),
        r8Operation("CP", opcode, r8, 128, 128, 128, "~S Z ~H ~P N ~C"),
      ]
    : [
        r8Operation("CP", opcode, r8, 10, 2, 10, "~S ~Z ~H ~P N ~C"),
        r8Operation("CP", opcode, r8, 129, 2, 129, "~S ~Z H P N ~C"),
        r8Operation("CP", opcode, r8, 255, 254, 255, "~S ~Z ~H ~P N ~C"),
        r8Operation("CP", opcode, r8, 3, 5, 3, "S ~Z H ~P N C"),
      ];

Scenario nOperation(String name, int opcode, int aValue, int nValue, int result,
        String flags,
        {String inFlags = ""}) =>
    Scenario(
      '$name -> ($aValue)',
      [opcode, nValue],
      initialState: State(
        register8Values: {
          Registers.R_A: aValue,
        },
        flags: inFlags,
      ),
      expectedState: State(
        register8Values: {
          Registers.R_A: result,
        },
        flags: flags,
      ),
    );

List<Scenario> addAN(int opcode) => [
      nOperation("ADD A, N", opcode, 10, 2, 12, "~S ~Z ~H ~P ~N ~C"),
      nOperation("ADD A, N", opcode, 127, 2, 129, "S ~Z H P ~N ~C"),
      nOperation("ADD A, N", opcode, 254, 2, 0, "~S Z H ~P ~N C"),
    ];

List<Scenario> adcAN(int opcode) => [
      nOperation("ADC A, N", opcode, 10, 10, 20, "~S ~Z H ~P ~N ~C",
          inFlags: "~C"),
      nOperation("ADC A, N", opcode, 10, 10, 21, "~S ~Z H ~P ~N ~C",
          inFlags: "C"),
      nOperation("ADC A, N", opcode, 128, 128, 0, "~S Z ~H P ~N C",
          inFlags: "~C"),
      nOperation("ADC A, N", opcode, 128, 128, 1, "~S ~Z ~H P ~N C",
          inFlags: "C"),
    ];

List<Scenario> subAN(int opcode) => [
      nOperation("SUB N", opcode, 10, 2, 8, "~S ~Z ~H ~P N ~C"),
      nOperation("SUB N", opcode, 129, 2, 127, "~S H ~Z P N ~C"),
      nOperation("SUB N", opcode, 255, 254, 1, "~S ~H ~Z ~P N ~C"),
      nOperation("SUB N", opcode, 3, 5, 254, "S ~Z H ~P N C"),
    ];

List<Scenario> sbcAN(int opcode) => [
      nOperation("SBC N", opcode, 10, 10, 0, "~S Z ~H ~P N ~C", inFlags: "~C"),
      nOperation("SBC N", opcode, 10, 10, 255, "S ~Z H ~P N C", inFlags: "C"),
      nOperation("SBC N", opcode, 128, 128, 0, "~S Z ~H ~P N ~C",
          inFlags: "~C"),
      nOperation("SBC N", opcode, 128, 128, 255, "S ~Z H ~P N C", inFlags: "C"),
    ];

List<Scenario> andAN(int opcode) => [
      nOperation("AND A, N", opcode, 0x03, 0x01, 0x01, "~S ~Z H ~P ~N ~C"),
      nOperation("AND A, N", opcode, 0x03, 0x04, 0x00, "~S Z H P ~N ~C"),
      nOperation("AND A, N", opcode, 0x80, 0x81, 0x80, "S ~Z H ~P ~N ~C"),
    ];

List<Scenario> xorN(int opcode) => [
      nOperation("XOR N", opcode, 0x03, 0x01, 0x02, "~S ~Z ~H ~P ~N ~C"),
      nOperation("XOR N", opcode, 0x03, 0x81, 0x82, "S ~Z ~H P ~N ~C"),
      nOperation("XOR N", opcode, 0x00, 0x00, 0x00, "~S Z ~H P ~N ~C"),
    ];

List<Scenario> orN(int opcode) => [
      nOperation("OR N", opcode, 0x02, 0x01, 0x03, "~S ~Z ~H P ~N ~C"),
      nOperation("OR N", opcode, 0x02, 0x81, 0x83, "S ~Z ~H ~P ~N ~C"),
      nOperation("OR N", opcode, 0x00, 0x00, 0x00, "~S Z ~H P ~N ~C"),
    ];

List<Scenario> cpN(int opcode) => [
      nOperation("CP N", opcode, 10, 2, 10, "~S ~Z ~H ~P N ~C"),
      nOperation("CP N", opcode, 129, 2, 129, "~S ~Z H P N ~C"),
      nOperation("CP N", opcode, 255, 254, 255, "~S ~Z ~H ~P N ~C"),
      nOperation("CP N", opcode, 3, 5, 3, "S ~Z H ~P N C"),
    ];

List<Scenario> exMSPHL(int opcode, int rhxy) => [
      Scenario(
        "EX (SP), ${Registers.r16Names[rhxy]}",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {Registers.R_SP: Scenario.RAM_START, rhxy: 10000},
          ram: [12, 34],
        ),
        expectedState: State(
          register16Values: {
            rhxy: littleEndian(12, 34),
          },
          ram: [lo(10000), hi(10000)],
        ),
      )
    ];

List<Scenario> jpMHL(int opcode, int rhxy) => [
      Scenario(
        "JP (${Registers.r16Names[rhxy]})",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: 12345,
          },
        ),
        expectedState: State(
          pc: 12345,
        ),
      )
    ];

List<Scenario> exDEHL(int opcode) => [
      Scenario(
        "EX DE, HL",
        [opcode],
        initialState: State(
          register16Values: {
            Registers.R_DE: 10000,
            Registers.R_HL: 20000,
          },
        ),
        expectedState: State(
          register16Values: {
            Registers.R_DE: 20000,
            Registers.R_HL: 10000,
          },
        ),
      )
    ];

List<Scenario> ldSPHL(int opcode, int rhxy) => [
      Scenario(
        "LD SP, ${Registers.r16Names[rhxy]}",
        [...ixyPrefix(rhxy), opcode],
        initialState: State(
          register16Values: {
            rhxy: 10000,
          },
        ),
        expectedState: State(
          register16Values: {
            Registers.R_SP: 10000,
          },
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
        ),
      )
    ];

List<Scenario> ldMNNIXY(int opcode, int rxy) => [
      Scenario(
        "LD (NN), ${Registers.r16Names[rxy]}",
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
        ),
      )
    ];

List<Scenario> ldIXYMN(int opcode, rxy) => [
      Scenario(
        'LD ${Registers.r16Names[rxy]}, (NN)',
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
          register16Values: {rxy: littleEndian(12, 34)},
          ram: [12, 34],
        ),
      )
    ];

List<Scenario> ldMIXYdN(int opcode, rxy) => [
      Scenario(
        'LD ${Registers.r16Names[rxy]}, (NN)',
        [...ixyPrefix(rxy), opcode, 1, 12],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 12],
        ),
      )
    ];

List<Scenario> ldR8MIXYd(int opcode, int r8, int rxy) => [
      Scenario(
        'LD ${Registers.r8Names[r8]}, (${Registers.r16Names[rxy]} + d)',
        [...ixyPrefix(rxy), opcode, 1],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          ram: [0, 12],
        ),
        expectedState: State(
          ram: [0, 12],
          register8Values: {r8: 12},
        ),
      )
    ];

List<Scenario> ldMIXYdR8(int opcode, int r8, int rxy) => [
      Scenario(
        'LD (${Registers.r16Names[rxy]} + d), ${Registers.r8Names[r8]}',
        [...ixyPrefix(rxy), opcode, 1],
        initialState: State(
          register16Values: {rxy: Scenario.RAM_START},
          register8Values: {r8: 12},
          ram: [0, 0],
        ),
        expectedState: State(
          ram: [0, 12],
        ),
      )
    ];

Scenario inR8CSpec(int opcode, int r8, int value, String flags) => Scenario(
      'IN ${Registers.r8Names[r8]}, (C) => ($value)',
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register16Values: {Registers.R_BC: 12345},
        inPorts: {12345: value},
      ),
      expectedState: State(
        register8Values: {r8: value},
        flags: flags,
      ),
    );

List<Scenario> inR8C(int opcode, int r8) => [
      inR8CSpec(opcode, r8, 0x07, "~S ~Z ~H ~P ~N"),
      inR8CSpec(opcode, r8, 0x00, "~S Z ~H P ~N"),
      inR8CSpec(opcode, r8, 0x80, "S ~Z ~H ~P ~N"),
    ];

List<Scenario> outCR8(int opcode, int r8) => [
      Scenario(
        'OUT (C) ${Registers.r8Names[r8]}',
        [Z80.EXTENDED_OPCODES, opcode],
        initialState: State(
          register8Values: {
            Registers.R_B: 10,
            Registers.R_C: 254,
            r8: r8 == Registers.R_B
                ? 10
                : r8 == Registers.R_C
                    ? 254
                    : 12
          },
        ),
        expectedState: State(
          outPorts: {
            littleEndian(254, 10): r8 == Registers.R_B
                ? 10
                : r8 == Registers.R_C
                    ? 254
                    : 12
          },
        ),
      )
    ];

List<Scenario> outNA(int opcode) => [
      Scenario(
        'OUT (N), A',
        [opcode, 253],
        initialState: State(
          register8Values: {Registers.R_A: 12},
        ),
        expectedState: State(
          outPorts: {littleEndian(253, 12): 12},
        ),
      )
    ];

List<Scenario> inAN(int opcode) => [
      Scenario(
        'IN A, (N)',
        [opcode, 253],
        initialState: State(
          register8Values: {Registers.R_A: 10},
          inPorts: {10 * 256 + 253: 12},
        ),
        expectedState: State(
          register8Values: {Registers.R_A: 12},
        ),
      )
    ];

List<Scenario> sbcHLR16(int opcode, int r16) => r16 == Registers.R_HL
    ? [
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 30000, 0,
            "~S Z ~H ~P N ~C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 30000,
            65535, "S ~Z H P N C",
            inFlags: "C", prefix: Z80.EXTENDED_OPCODES),
      ]
    : [
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 12000,
            18000, "~S ~Z H ~P N ~C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 30000, 0,
            "~S Z ~H ~P N ~C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 40000,
            55536, "S ~Z H ~P N C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 12000,
            17999, "~S ~Z H ~P N ~C",
            inFlags: "C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("SBC", opcode, Registers.R_HL, r16, 30000, 30000,
            65535, "S ~Z H P N C",
            inFlags: "C", prefix: Z80.EXTENDED_OPCODES),
      ];

List<Scenario> adcHLR16(int opcode, int r16) => r16 == Registers.R_HL
    ? [
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 40000, 40000,
            14464, "~S ~Z H P ~N C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 32768, 32768, 0,
            "~S Z ~H P ~N C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 10000, 10000,
            20001, "~S ~Z ~H ~P ~N ~C",
            inFlags: "C", prefix: Z80.EXTENDED_OPCODES),
      ]
    : [
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 20000, 12000,
            32000, "~S ~Z H ~P ~N ~C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 30000, 20000,
            50000, "S ~Z H P ~N ~C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 30000, 42000, 6464,
            "~S ~Z ~H ~P ~N C",
            inFlags: "~C", prefix: Z80.EXTENDED_OPCODES),
        changeR16R16Spec("ADC", opcode, Registers.R_HL, r16, 30000, 42000, 6465,
            "~S ~Z ~H ~P ~N C",
            inFlags: "C", prefix: Z80.EXTENDED_OPCODES),
      ];

List<Scenario> neg(int opcode) => [
      changeR8("NEG", opcode, Registers.R_A, 3, 253, "S ~Z H ~P N C",
          prefix: Z80.EXTENDED_OPCODES),
      changeR8("NEG", opcode, Registers.R_A, 0, 0, "~S Z ~H ~P N ~C",
          prefix: Z80.EXTENDED_OPCODES),
      changeR8("NEG", opcode, Registers.R_A, 0x80, 0x80, "S ~Z H P N C",
          prefix: Z80.EXTENDED_OPCODES),
    ];

Scenario bitNR8R8Spec(int opcode, int bit, int r8, int value, String flags) =>
    Scenario(
      "BIT $bit, ${Registers.r8Names[r8]} (${toBinary(value)})",
      [Z80.BIT_OPCODES, opcode],
      initialState: State(
        register8Values: {r8: value},
      ),
      expectedState: State(flags: flags),
    );

Scenario bitNR8HLSpec(int opcode, int bit, int value, String flags) => Scenario(
      "BIT $bit, (HL) (${toBinary(value)})",
      [Z80.BIT_OPCODES, opcode],
      initialState: State(
        register16Values: {Registers.R_HL: Scenario.RAM_START + 1},
        ram: [0, value],
      ),
      expectedState: State(
        ram: [0, value],
        flags: flags,
      ),
    );

Scenario bitNR8Spec(int opcode, int bit, int r8, int value, String flags) =>
    changeR8("BIT $bit", opcode, r8, value, value, flags,
        prefix: Z80.BIT_OPCODES);

List<Scenario> bitNR8(int opcode, int bit, int r8) => [
      bitNR8Spec(opcode, bit, r8, 0xFF ^ Z80.bitMask[bit], "Z H ~N"),
      bitNR8Spec(opcode, bit, r8, Z80.bitMask[bit], "~Z H ~N")
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
        prefix: Z80.BIT_OPCODES);

List<Scenario> resNR8(int opcode, int bit, int r8) => [
      resNR8Spec(opcode, bit, r8, Z80.bitMask[bit], 0x00),
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
        prefix: Z80.BIT_OPCODES);

List<Scenario> setNR8(int opcode, int bit, int r8) => [
      setNR8Spec(opcode, bit, r8, 0x00, Z80.bitMask[bit]),
      setNR8Spec(opcode, bit, r8, Z80.bitMask[bit], Z80.bitMask[bit]),
    ];

List<Scenario> set0R8(int opcode, int r8) => setNR8(opcode, 0, r8);
List<Scenario> set1R8(int opcode, int r8) => setNR8(opcode, 1, r8);
List<Scenario> set2R8(int opcode, int r8) => setNR8(opcode, 2, r8);
List<Scenario> set3R8(int opcode, int r8) => setNR8(opcode, 3, r8);
List<Scenario> set4R8(int opcode, int r8) => setNR8(opcode, 4, r8);
List<Scenario> set5R8(int opcode, int r8) => setNR8(opcode, 5, r8);
List<Scenario> set6R8(int opcode, int r8) => setNR8(opcode, 6, r8);
List<Scenario> set7R8(int opcode, int r8) => setNR8(opcode, 7, r8);

List<Scenario> ldIA(int opcode) => [
      Scenario(
        'LD I, A',
        [Z80.EXTENDED_OPCODES, opcode],
        initialState: State(
          register8Values: {Registers.R_A: 12},
        ),
        expectedState: State(
          register8Values: {Registers.R_I: 12},
        ),
      )
    ];

Scenario ldAISpec(int opcode, int value, String flags) => Scenario(
      'LD A, I ($value)',
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_I: value},
      ),
      expectedState: State(
        register8Values: {Registers.R_A: value},
        flags: flags,
      ),
    );

List<Scenario> ldAI(int opcode) => [
      ldAISpec(opcode, 12, "~S ~Z ~H ~N"),
      ldAISpec(opcode, 0, "~S Z ~H ~N"),
      ldAISpec(opcode, 255, "S ~Z ~H ~N"),
    ];

List<Scenario> ldRA(int opcode) => [
      Scenario(
        'LD R, A',
        [Z80.EXTENDED_OPCODES, opcode],
        initialState: State(
          register8Values: {Registers.R_A: 12},
        ),
        expectedState: State(
          register8Values: {Registers.R_R: 12},
        ),
      )
    ];

Scenario ldARSpec(int opcode, int value, String flags) => Scenario(
      'LD A, R ($value)',
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_R: value},
      ),
      expectedState: State(
        register8Values: {Registers.R_A: value},
        flags: flags,
      ),
    );

List<Scenario> ldAR(int opcode) => [
      ldARSpec(opcode, 12, "~S ~Z ~H ~N"),
      ldARSpec(opcode, 0, "~S Z ~H ~N"),
      ldARSpec(opcode, 255, "S ~Z ~H ~N"),
    ];

Scenario ldIncDecSpec(String name, int opcode, int inc, int bc, String flags,
        {int? finalPC}) =>
    Scenario(
      name,
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register16Values: {
          Registers.R_HL: Scenario.RAM_START + 2,
          Registers.R_DE: Scenario.RAM_START + 6,
          Registers.R_BC: bc,
        },
        ram: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      ),
      expectedState: State(
        register16Values: {
          Registers.R_HL: Scenario.RAM_START + 2 + inc,
          Registers.R_DE: Scenario.RAM_START + 6 + inc,
          Registers.R_BC: bc - 1,
        },
        ram: [0, 1, 2, 3, 4, 5, 2, 7, 8, 9],
        flags: flags,
        pc: finalPC,
      ),
    );

List<Scenario> ldi(int opcode) => [
      ldIncDecSpec("LDI", opcode, 1, 10, "~H P ~N"),
      ldIncDecSpec("LDI", opcode, 1, 1, "~H ~P ~N"),
    ];

List<Scenario> ldd(int opcode) => [
      ldIncDecSpec("LDD", opcode, -1, 10, "~H P ~N"),
      ldIncDecSpec("LDD", opcode, -1, 1, "~H ~P ~N"),
    ];

Scenario cpIncDecSpec(String name, int opcode, int inc, int a, int value,
        int bc, String flags,
        {int? finalPC}) =>
    Scenario(
      name,
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_A: a},
        register16Values: {
          Registers.R_HL: Scenario.RAM_START + 1,
          Registers.R_BC: bc,
        },
        ram: [0, value],
      ),
      expectedState: State(
        register16Values: {
          Registers.R_HL: Scenario.RAM_START + 1 + inc,
          Registers.R_BC: bc - 1,
        },
        ram: [0, value],
        flags: flags,
        pc: finalPC,
      ),
    );

List<Scenario> cpi(int opcode) => [
      cpIncDecSpec("CPI", opcode, 1, 10, 2, 4, "~S ~Z ~H P ~N ~C"),
      cpIncDecSpec("CPI", opcode, 1, 129, 2, 3, "~S ~Z H P ~N ~C"),
      cpIncDecSpec("CPI", opcode, 1, 255, 254, 2, "~S ~Z ~H P ~N ~C"),
      cpIncDecSpec("CPI", opcode, 1, 3, 5, 1, "S ~Z H ~P ~N C"),
    ];

List<Scenario> cpd(int opcode) => [
      cpIncDecSpec("CPD", opcode, -1, 10, 2, 4, "~S ~Z ~H P ~N ~C"),
      cpIncDecSpec("CPD", opcode, -1, 129, 2, 3, "~S ~Z H P ~N ~C"),
      cpIncDecSpec("CPD", opcode, -1, 255, 254, 2, "~S ~Z ~H P ~N ~C"),
      cpIncDecSpec("CPD", opcode, -1, 3, 5, 1, "S ~Z H ~P ~N C"),
    ];

Scenario inIncDecSpec(String name, int opcode, int inc, int b, String flags,
        {int? finalPC}) =>
    Scenario(
      name,
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_B: b, Registers.R_C: 254},
        register16Values: {Registers.R_HL: Scenario.RAM_START + 1},
        inPorts: {254: 12},
        ram: [0, 0],
      ),
      expectedState: State(
        register8Values: {Registers.R_B: b - 1},
        register16Values: {Registers.R_HL: Scenario.RAM_START + 1 + inc},
        ram: [0, 12],
        flags: flags,
        pc: finalPC,
      ),
    );

List<Scenario> ini(int opcode) => [
      inIncDecSpec("INI", opcode, 1, 5, "~Z N"),
      inIncDecSpec("INI", opcode, 1, 1, "Z N"),
    ];

List<Scenario> ind(int opcode) => [
      inIncDecSpec("IND", opcode, -1, 5, "~Z N"),
      inIncDecSpec("IND", opcode, -1, 1, "Z N"),
    ];

Scenario outIncDecSpec(String name, int opcode, int inc, int b, String flags,
        {int? finalPC}) =>
    Scenario(
      name,
      [Z80.EXTENDED_OPCODES, opcode],
      initialState: State(
        register8Values: {Registers.R_B: b, Registers.R_C: 254},
        register16Values: {Registers.R_HL: Scenario.RAM_START + 1},
        ram: [0, 12],
      ),
      expectedState: State(
        register8Values: {Registers.R_B: b - 1},
        register16Values: {Registers.R_HL: Scenario.RAM_START + 1 + inc},
        ram: [0, 12],
        outPorts: {254: 12},
        flags: flags,
        pc: finalPC,
      ),
    );

List<Scenario> outi(int opcode) => [
      outIncDecSpec("OUTI", opcode, 1, 5, "~Z N"),
      outIncDecSpec("OUTI", opcode, 1, 1, "Z N"),
    ];

List<Scenario> outd(int opcode) => [
      outIncDecSpec("OUTD", opcode, -1, 5, "~Z N"),
      outIncDecSpec("OUTD", opcode, -1, 1, "Z N"),
    ];

List<Scenario> ldir(int opcode) => [
      ldIncDecSpec("LDIR", opcode, 1, 5, "~H P ~N",
          finalPC: 0), //PC does not move
      ldIncDecSpec("LDIR", opcode, 1, 1, "~H ~P ~N"),
    ];

List<Scenario> lddr(int opcode) => [
      ldIncDecSpec("LDDR", opcode, -1, 5, "~H P ~N",
          finalPC: 0), //PC does not move
      ldIncDecSpec("LDDR", opcode, -1, 1, "~H ~P ~N"),
    ];

List<Scenario> cpir(int opcode) => [
      cpIncDecSpec("CPIR", opcode, 1, 10, 2, 4, "~S ~Z ~H P ~N ~C", finalPC: 0),
      cpIncDecSpec("CPIR", opcode, 1, 129, 2, 3, "~S ~Z H P ~N ~C", finalPC: 0),
      cpIncDecSpec("CPIR", opcode, 1, 255, 254, 2, "~S ~Z ~H P ~N ~C",
          finalPC: 0),
      cpIncDecSpec("CPIR", opcode, 1, 10, 10, 4, "~S Z ~H P ~N ~C"),
      cpIncDecSpec("CPIR", opcode, 1, 3, 5, 1, "S ~Z H ~P ~N C"),
    ];

List<Scenario> cpdr(int opcode) => [
      cpIncDecSpec("CPDR", opcode, -1, 10, 2, 4, "~S ~Z ~H P ~N ~C",
          finalPC: 0),
      cpIncDecSpec("CPDR", opcode, -1, 129, 2, 3, "~S ~Z H P ~N ~C",
          finalPC: 0),
      cpIncDecSpec("CPDR", opcode, -1, 255, 254, 2, "~S ~Z ~H P ~N ~C",
          finalPC: 0),
      cpIncDecSpec("CPDR", opcode, -1, 3, 5, 1, "S ~Z H ~P ~N C"),
      cpIncDecSpec("CPDR", opcode, -1, 10, 10, 4, "~S Z ~H P ~N ~C"),
    ];

List<Scenario> inir(int opcode) => [
      inIncDecSpec("INIR", opcode, 1, 5, "Z N", finalPC: 0),
      inIncDecSpec("INIR", opcode, 1, 1, "Z N"),
    ];

List<Scenario> indr(int opcode) => [
      inIncDecSpec("INIR", opcode, -1, 5, "Z N", finalPC: 0),
      inIncDecSpec("INIR", opcode, -1, 1, "Z N"),
    ];

List<Scenario> otir(int opcode) => [
      outIncDecSpec("OUTI", opcode, 1, 5, "Z N", finalPC: 0),
      outIncDecSpec("OUTI", opcode, 1, 1, "Z N"),
    ];

List<Scenario> otdr(int opcode) => [
      outIncDecSpec("OUTI", opcode, -1, 5, "Z N", finalPC: 0),
      outIncDecSpec("OUTI", opcode, -1, 1, "Z N"),
    ];
