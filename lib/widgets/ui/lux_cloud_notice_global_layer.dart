import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../../providers/game_state.dart';

/// Affiche un SnackBar global quand une sync LUX est abandonnée (erreur Functions
/// irrécupérable) afin d’éviter un “silent fail” pour le joueur.
class LuxCloudNoticeGlobalLayer extends StatefulWidget {
  const LuxCloudNoticeGlobalLayer({super.key});

  @override
  State<LuxCloudNoticeGlobalLayer> createState() =>
      _LuxCloudNoticeGlobalLayerState();
}

class _LuxCloudNoticeGlobalLayerState extends State<LuxCloudNoticeGlobalLayer> {
  GameState? _gameState;
  int _consumedId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GameState g = context.read<GameState>();
    if (_gameState == g) return;
    _gameState?.removeListener(_onGameState);
    _gameState = g;
    _gameState!.addListener(_onGameState);
  }

  @override
  void dispose() {
    _gameState?.removeListener(_onGameState);
    super.dispose();
  }

  void _onGameState() {
    if (!mounted) return;
    final ({int id, String code, String motif})? n =
        _gameState?.consumeLuxCloudUnrecoverableNotice();
    if (n == null) return;
    if (n.id <= _consumedId) return;
    _consumedId = n.id;
    unawaited(_showNotice(n.code, n.motif));
  }

  Future<void> _showNotice(String code, String motif) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final String text = switch (code) {
      'invalid-argument' => l10n.luxCloudRejectedUpdateRequired,
      'failed-precondition' => l10n.luxCloudRejectedTryLater,
      _ => l10n.luxCloudRejectedGeneric,
    };

    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

