import 'package:ZxSpectrum/BankedMemory.dart';
import 'package:Z80/Util.dart';
import 'package:test/test.dart';

import 'package:ZxSpectrum/MemoryAsBytes.dart';

void main() {
  test("should read memory from each bank", () {
    var b1 = MemoryAsBytes(10, (int _) {});
    var b2 = MemoryAsBytes(50, (int _) {});

    b1.poke(0, 100);
    b2.poke(0, 200);

    var banks = [MemoryBank(0, b1), MemoryBank(20, b2)];

    var memory = BankedMemory(banks);

    expect(memory.peek(0), 100);
    expect(memory.peek(20), 200);
  });

  test("should wrap banks when reading 2 bytes", () {
    var b1 = MemoryAsBytes(0x4000, (int _) {});
    var b2 = MemoryAsBytes(0xC000, (int _) {});

    b2.poke(0xC000 - 1, 200);
    b1.poke(0x0000, 100);

    var banks = [MemoryBank(0x0000, b1), MemoryBank(0x4000, b2)];

    var memory = BankedMemory(banks);

    expect(memory.peek2(0xFFFF), littleEndian(200, 100));
  });
}
