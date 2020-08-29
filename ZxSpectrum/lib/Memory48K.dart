import 'dart:typed_data';

import 'package:Z80a/Memory.dart';

import 'Util.dart';

class Memory48K extends Memory {
  Uint8List bytes;

  Memory48K.fromBytes(this.bytes);

  Memory48K() {
    this.bytes = Uint8List.fromList(List.filled(49152, 0));
  }

  int normalize(int address) => address % 65536;

  @override
  peek(int address) => bytes[normalize(address)];

  @override
  peek2(int address) =>
      bytes[normalize(address)] + 256 * bytes[normalize(address + 1)];

  @override
  poke(int address, int b) {
    this.bytes[normalize(address)] = b;
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
  Uint8List range(int start, {int end}) => bytes.sublist(start, end);
}
