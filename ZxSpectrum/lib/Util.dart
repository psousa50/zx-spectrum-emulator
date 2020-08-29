int binary(String b) => int.parse(b, radix: 2);

int lo(int w) => w % 256;
int hi(int w) => w ~/ 256;
int w(int lo, int hi) => lo + 256 * hi;
