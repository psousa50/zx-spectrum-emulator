int binary(String b) => int.parse(b, radix: 2);

String toBinary8(int b) {
  var result = "";
  for (var i = 0; i < 8; i++) {
    result = "${b & 0x01 == 0x01 ? '1' : '0'}$result";
    b = b >> 1;
  }
  return result;
}

int lo(int w) => w % 256;
int hi(int w) => w ~/ 256;
int w(int lo, int hi) => lo + 256 * hi;
