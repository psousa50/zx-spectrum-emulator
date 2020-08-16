import './Util.dart';

class Memory {
  List<int> bytes;

  Memory.fromBytes(this.bytes);

  Memory({size = 10}) {
    this.bytes = List<int>.filled(size, 0);
  }

  peek(int address) => bytes[address];

  peek2(int address) => bytes[address] + 256 * bytes[address + 1];

  poke(int address, int b) {
    this.bytes[address] = b;
  }

  poke2(int address, int b) {
    this.bytes[address] = lo(b);
    this.bytes[address + 1] = hi(b);
  }
}
