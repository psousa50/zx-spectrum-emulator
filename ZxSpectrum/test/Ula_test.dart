import 'package:Z80a/Util.dart';
import 'package:ZxSpectrum/Memory48K.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ZxSpectrum/Ula.dart';

Ula newUla() => Ula(Memory48K());

void main() {
  test("Reading from port 0xFE should return key states", () {
    var ula = newUla();

    ula.keyDown(Keys.K_1);
    ula.keyDown(Keys.K_4);
    ula.keyDown(Keys.K_SYM);

    expect(ula.inPort(0xF7FE), binary("11110110"));
    expect(ula.inPort(0x7FFE), binary("11111101"));

    ula.keyUp(Keys.K_4);
    ula.keyUp(Keys.K_SYM);

    expect(ula.inPort(0xF7FE), binary("11111110"));
    expect(ula.inPort(0x7FFE), binary("11111111"));
  });

  test("Reading from port other that 0xFE should returning 0", () {
    var ula = newUla();

    expect(ula.inPort(0xF7FD), 0x00);
  });
}
