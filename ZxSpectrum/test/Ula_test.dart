import 'package:ZxSpectrum/Colors.dart';
import 'package:ZxSpectrum/Keyboard/ZxKeys.dart';
import 'package:ZxSpectrum/Memory/Memory48K.dart';
import 'package:ZxSpectrum/Ula.dart';
import 'package:test/test.dart';

import 'package:Z80/Util.dart';

Ula newUla() => Ula(Memory48K());

void main() {
  test("Reading from port 0xFE should return key states", () {
    var ula = newUla();

    ula.keyDown(ZxKey.K_1);
    ula.keyDown(ZxKey.K_4);
    ula.keyDown(ZxKey.K_SYM);

    expect(ula.read(0xF7FE), binary("11110110"));
    expect(ula.read(0x7FFE), binary("11111101"));

    ula.keyUp(ZxKey.K_4);
    ula.keyUp(ZxKey.K_SYM);

    expect(ula.read(0xF7FE), binary("11111110"));
    expect(ula.read(0x7FFE), binary("11111111"));
  });

  test("Reading from port other that 0xFE should returning 0xFF", () {
    var ula = newUla();

    expect(ula.read(0xF7FD), 0xFF);
  });

  test("Writing to port 0xFE should change the border color", () {
    var ula = newUla();

    ula.write(0xFE, 2);

    expect(ula.borderColor, SpectrumColors[2]);
  });
}
