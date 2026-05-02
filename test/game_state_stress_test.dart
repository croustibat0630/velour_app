import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/providers/game_state.dart';

void _layoutMinimal(GameState gs) {
  const double width = 420;
  const double playH = 700;
  const double slotSize = 45;
  const double gap = 5;
  const double slotTopY = 720;
  gs.setLayout(
    playZoneRect: Rect.fromLTWH(0, 0, width, playH),
    slotTopLefts: List<Offset>.generate(GameState.slotCount, (int i) {
      return Offset(12 + i * (slotSize + gap), slotTopY);
    }),
    luxSafeRect: Rect.fromLTWH(0, 0, width, 140),
    boardSpawnMinY: 200,
    itemSize: slotSize,
    slotSize: slotSize,
    gridGap: gap,
  );
}

/// Stress léger sur [GameState] uniquement (pas d’AudioHandler : pas de plugin en test VM).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final TestDefaultBinaryMessengerBinding b =
        TestDefaultBinaryMessengerBinding.instance;
    for (final String name in <String>[
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      b.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(name),
        (MethodCall call) async => null,
      );
    }
  });

  test('GameState: rafales selectItem + pause (stabilité)', () async {
    final GameState gs = GameState();
    _layoutMinimal(gs);
    gs.startGame();
    await Future<void>.delayed(Duration.zero);

    for (int i = 0; i < 800; i++) {
      gs.setPaused(i.isOdd);
      final List<String> ids = gs.boardItems.map((e) => e.id).toList();
      if (ids.isEmpty) break;
      for (final String id in ids.take(5)) {
        await gs.selectItem(id);
      }
      if (i % 50 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    gs.dispose();
  });
}
