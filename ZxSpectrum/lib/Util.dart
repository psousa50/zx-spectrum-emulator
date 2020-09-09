int binary(String b) => int.parse(b, radix: 2);

String toBinary8(int b) {
  var result = "";
  for (var i = 0; i < 8; i++) {
    result = "${b & 0x01 == 0x01 ? '1' : '0'}$result";
    b = b >> 1;
  }
  return result;
}

String toHex(int value) =>
    "${value < 0x10 ? "0" : ''}${value.toRadixString(16).toUpperCase()}";

String toHex2(int value) =>
    "${value < 0x1000 ? "0" : ''}${value < 0x100 ? "0" : ''}${value < 0x10 ? "0" : ''}${value.toRadixString(16).toUpperCase()}";

int lo(int w) => w % 256;
int hi(int w) => w ~/ 256;
int w(int lo, int hi) => lo + 256 * hi;

int bit01(int byte) => byte & 0x03;
int bit012(int byte) => byte & 0x07;
int bit123(int byte) => byte & 0x0E;
int bit5(int byte) => byte & 0x20;
int bit345(int byte) => (byte & 0x38) >> 3;
int bit45(int byte) => (byte & 0x30) >> 4;
