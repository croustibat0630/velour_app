import 'package:flutter/material.dart';

class DarkMatteOverlay extends StatelessWidget {
  const DarkMatteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Replaces all standard BackdropFilter blur: dark matte at 85% opacity.
    return const ColoredBox(
      color: Color(0xD9000000), // 85% black
      child: SizedBox.expand(),
    );
  }
}
