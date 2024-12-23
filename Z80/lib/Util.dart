import 'package:collection/collection.dart';

Function eq = const ListEquality().equals;

int binary(String b) => int.parse(b, radix: 2);

String toBinary(int b, {int length = 8}) {
  var result = "";
  for (var i = 0; i < length; i++) {
    result = "${b & 0x01 == 0x01 ? '1' : '0'}$result";
    b = b >> 1;
  }
  return result;
}

String toHex(int value, {width = 2}) =>
    "${value.toRadixString(16).toUpperCase().padLeft(width, "0")}";

String toHex16(int value) => toHex(value, width: 4);

String toTime(DateTime dateTime) =>
    dateTime.toIso8601String().split("T")[1].substring(0, 8);

int lo(int w) => w % 256;
int hi(int w) => w ~/ 256;
int littleEndian(int lo, int hi) => lo + 256 * hi;

int byte(int b) => b % 256;
int word(int w) => w % 65536;

int bit01(int byte) => byte & 0x03;
int bit012(int byte) => byte & 0x07;
int bit123(int byte) => byte & 0x0E;
int bit5(int byte) => byte & 0x20;
int bit345(int byte) => (byte & 0x38);
int bit45(int byte) => (byte & 0x30);
