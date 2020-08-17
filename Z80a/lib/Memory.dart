import './Util.dart';

class Memory {
  List<int> bytes;

  Memory.fromBytes(this.bytes);

  Memory({size = 10}) {
    this.bytes = List<int>.filled(size, 0);
  }

  int normalize(int address) => address % 65536;

  peek(int address) => bytes[normalize(address)];

  peek2(int address) =>
      bytes[normalize(address)] + 256 * bytes[normalize(address + 1)];

  poke(int address, int b) {
    this.bytes[normalize(address)] = b;
  }

  poke2(int address, int b) {
    this.bytes[normalize(address)] = lo(b);
    this.bytes[normalize(address + 1)] = hi(b);
  }
}
