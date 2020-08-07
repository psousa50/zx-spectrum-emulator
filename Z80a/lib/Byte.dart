class Byte {
  int value;

  Byte(this.value);

  int normalize(int v) => v % 256;

  operator +(Byte other) =>
      Byte(this.value = normalize(this.value + other.value));

  operator -(Byte other) =>
      Byte(this.value = normalize(this.value - other.value));

  bool operator ==(other) => other is Byte && this.value == other.value;

  @override
  int get hashCode => this.value;
}

class Word {
  int value;

  Word(this.value);

  int normalize(int v) => v % 65536;

  operator +(Word other) =>
      Word(this.value = normalize(this.value + other.value));
  operator -(Word other) =>
      Word(this.value = normalize(this.value - other.value));

  bool operator ==(other) => other is Word && this.value == other.value;

  @override
  int get hashCode => this.value;
}
