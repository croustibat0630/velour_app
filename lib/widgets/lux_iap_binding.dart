import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../services/lux_iap_service.dart';

/// Abonne le flux d’achats intégrés au [GameState] (recommandation Flutter : avant toute UI).
class LuxIapBinding extends StatefulWidget {
  const LuxIapBinding({super.key, required this.child});

  final Widget child;

  @override
  State<LuxIapBinding> createState() => _LuxIapBindingState();
}

class _LuxIapBindingState extends State<LuxIapBinding> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      LuxIapService.instance.bindGameState(context.read<GameState>());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
