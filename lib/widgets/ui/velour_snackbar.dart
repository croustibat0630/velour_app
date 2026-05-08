import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// SnackBar “Velour” : floating, glass + néon, cohérent avec le thème de l’app.
void showVelourSnackBar(
  BuildContext context,
  String message, {
  Color accent = const Color(0xFF00E5FF),
  Duration duration = const Duration(seconds: 3),
  IconData icon = Icons.info_outline_rounded,
}) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        content: _VelourSnackContent(
          message: message,
          accent: accent,
          icon: icon,
        ),
      ),
    );
}

class _VelourSnackContent extends StatelessWidget {
  const _VelourSnackContent({
    required this.message,
    required this.accent,
    required this.icon,
  });

  final String message;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B0D12).withValues(alpha: 0.82),
                const Color(0xFF05070C).withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.24), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 26,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 14,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: accent.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 14,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.25,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.80),
                        ) ??
                        TextStyle(
                          height: 1.25,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
