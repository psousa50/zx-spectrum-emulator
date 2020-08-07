import 'package:flutter_test/flutter_test.dart';

import '../lib/Byte.dart';

void main() {
  test('byte sum', () {
    expect(Byte(255) + Byte(2), Byte(1));
  });

  test('byte subtract', () {
    expect(Byte(2) - Byte(3), Byte(255));
  });

  test('word sum', () {
    expect(Word(65535) + Word(2), Word(1));
  });

  test('word subtract', () {
    expect((Word(2) - Word(3)), Word(65535));
  });
}
