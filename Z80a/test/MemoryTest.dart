import 'dart:typed_data';

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Util.dart';

class MemoryTest extends Memory {
  List<int> bytes;

  MemoryTest.fromBytes(this.bytes);

  MemoryTest({size = 10}) {
    this.bytes = List<int>.filled(size, 0);
  }

  int normalize(int address) => address % 65536;

  @override
  peek(int address) => bytes[normalize(address)];

  @override
  peek2(int address) =>
      bytes[normalize(address)] + 256 * bytes[normalize(address + 1)];

  @override
  poke(int address, int b) {
    this.bytes[normalize(address)] = b % 256;
  }

  @override
  poke2(int address, int b) {
    this.bytes[normalize(address)] = lo(b);
    this.bytes[normalize(address + 1)] = hi(b);
  }

  @override
  void setRange(int address, Uint8List bytes) {
    this.bytes.setRange(address, address + bytes.length, bytes);
  }

  @override
  Uint8List range(int start, {int end}) =>
      Uint8List.fromList(bytes.sublist(start, end));
}
