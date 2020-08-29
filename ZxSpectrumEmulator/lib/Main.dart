import 'package:flutter/material.dart';

import 'ZxSpectrum.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("Main");
    return MaterialApp(
      title: 'Zx Spectrum Emulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ZxSpectrum(),
    );
  }
}
