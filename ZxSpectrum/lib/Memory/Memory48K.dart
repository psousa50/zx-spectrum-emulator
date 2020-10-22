import 'package:Z80/Memory.dart';

import 'BankedMemory.dart';
import 'MemoryAsBytes.dart';

class Memory48K extends BankedMemory {
  static List<MemoryBank> buildMemoryBanks(OnMemoryError onMemoryError) {
    var rom = MemoryAsBytes(0x4000, onMemoryError, readonly: true);
    var ram = MemoryAsBytes(0xC000, onMemoryError);

    return [MemoryBank(0, rom), MemoryBank(0x4000, ram)];
  }

  Memory48K({OnMemoryError onMemoryError = onMemoryErrorDefault})
      : super(buildMemoryBanks(onMemoryError), onMemoryError: onMemoryError);
}
