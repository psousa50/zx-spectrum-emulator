import 'dart:typed_data';

abstract class Memory {
  int peek(int address);
  int peek2(int address);

  void poke(int address, int b);
  void poke2(int address, int w);

  void setRange(int address, Uint8List bytes);

  Uint8List range(int start, {int end});
}
