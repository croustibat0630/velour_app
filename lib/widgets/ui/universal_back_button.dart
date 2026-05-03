import 'package:flutter/material.dart';

import '../../services/audio_handler.dart';

class UniversalBackButton extends StatefulWidget {
  const UniversalBackButton({super.key});

  @override
  State<UniversalBackButton> createState() => _UniversalBackButtonState();
}

class _UniversalBackButtonState extends State<UniversalBackButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final double opacity = (_hover || _down) ? 1.0 : 0.70;
    final double targetScale = _down ? 1.05 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _down = true);
          // Immediate feedback on press (not release).
          AudioHandler.instance.playMenuClick();
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          Navigator.of(context).maybePop();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: opacity,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: targetScale,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
