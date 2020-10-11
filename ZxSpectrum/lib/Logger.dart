import "dart:async";

import 'package:Z80/Util.dart';
import "package:ZxSpectrum/ZxSpectrum.dart";

class Logger {
  bool disabled;
  int bufferlength;

  int counter = 0;

  Logger({bool this.disabled = false, int this.bufferlength = 1000});

  void setActive(bool active) => disabled = !active;
  bool isActive() => !disabled;

  var printBuffer = List<String>();

  void pc(ZxSpectrum zx) {
    if (disabled) return;

    var z80 = zx.z80;
    var state = "#${toHex16(z80.PC)}" +
        " SP:${toHex16(z80.registers.SP)}" +
        " MSP:${toHex16(zx.memory.peek2(z80.registers.SP))}";

    var i = zx.z80.getInstruction();
    var opcode = i != null ? i.name : "Invalid Instruction";

    log("$state       $opcode");
  }

  void z80State(ZxSpectrum zx, String s) {
    if (disabled) return;

    var z80 = zx.z80;
    var state = "#${toHex16(z80.PC)} " +
        " A:${toHex(z80.registers.A)}" +
        " BC:${toHex16(z80.registers.BC)}" +
        " DE:${toHex16(z80.registers.DE)}" +
        " HL:${toHex16(z80.registers.HL)}" +
        " IX:${toHex16(z80.registers.IX)}" +
        " IY:${toHex16(z80.registers.IY)}" +
        " SP:${toHex16(z80.registers.SP)}" +
        " MSP:${toHex16(zx.memory.peek2(z80.registers.SP))}" +
        " ${z80.registers.signFlag ? "S" : " "}" +
        " ${z80.registers.zeroFlag ? "Z" : " "}" +
        " ${z80.registers.halfCarryFlag ? "H" : " "}" +
        " ${z80.registers.parityOverflowFlag ? "P" : " "}" +
        " ${z80.registers.addSubtractFlag ? "N" : " "}" +
        " ${z80.registers.carryFlag ? "C" : " "}" +
        " ${z80.memory.range(z80.PC, end: z80.PC + 4).map(toHex)}";

    var i = zx.z80.getInstruction();
    var opcode = i != null ? i.name : "Invalid Instruction";

    log("$state       $opcode                 $s");
  }

  void flush() {
    printBuffer.forEach((s) {
      print(s);
    });
    printBuffer.clear();
  }

  void log(String s) {
    if (disabled) return;

    counter++;

    printBuffer.add(
        "${counter.toString().padLeft(7, "0")} ${toTime(DateTime.now())}: $s");

    if (printBuffer.length >= bufferlength) {
      new Future(() {
        scheduleMicrotask(flush);
      });
    }
  }
}
