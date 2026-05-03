import 'package:flutter/material.dart';

import '../models/game_item.dart';
import '../providers/game_state_types.dart';
import 'tutorial_board_specs.dart';

/// Position coin haut-gauche d’une gemme tutoriel pour l’index de slot 0…2.
typedef TutorialGemTopLeft = Offset Function(int slotIndex);

/// Construction des [GameItem] pour plateaux tutoriels figés.
abstract final class TutorialBoardPlacer {
  static void placeNarrativeStep1Gems({
    required List<GameItem> board,
    required void Function(String id) onNarrativeTapId,
    required String Function() nextId,
    required TutorialGemTopLeft topLeftForSlot,
  }) {
    int i = 0;
    for (final ({int typeId, int colorId}) spec
        in NarrativeTutorialBoardSpecs.step1Gems) {
      final String id = nextId();
      onNarrativeTapId(id);
      board.add(
        GameItem(
          id: id,
          typeId: spec.typeId,
          colorId: spec.colorId,
          position: topLeftForSlot(i),
          floatPeriodMs: 2200,
          floatPhase: i * 0.12,
        ),
      );
      i++;
    }
  }

  static void placeNarrativeStep2Gems({
    required List<GameItem> board,
    required void Function(String id) onNarrativeTapId,
    required String Function() nextId,
    required TutorialGemTopLeft topLeftForSlot,
  }) {
    int i = 0;
    for (final ({int typeId, int colorId}) spec
        in NarrativeTutorialBoardSpecs.step2Gems) {
      final String id = nextId();
      onNarrativeTapId(id);
      board.add(
        GameItem(
          id: id,
          typeId: spec.typeId,
          colorId: spec.colorId,
          position: topLeftForSlot(i),
          floatPeriodMs: 2200,
          floatPhase: i * 0.11,
        ),
      );
      i++;
    }
  }

  static void placeNarrativeStep3Gems({
    required List<GameItem> board,
    required void Function(String id) onNarrativeTapId,
    required String Function() nextId,
    required TutorialGemTopLeft topLeftForSlot,
  }) {
    for (int i = 0; i < NarrativeTutorialBoardSpecs.step3GemCount; i++) {
      final String id = nextId();
      onNarrativeTapId(id);
      board.add(
        GameItem(
          id: id,
          typeId: NarrativeTutorialBoardSpecs.step3TypeId,
          colorId: NarrativeTutorialBoardSpecs.step3ColorId,
          position: topLeftForSlot(i),
          floatPeriodMs: 2400,
          floatPhase: i * 0.1,
        ),
      );
    }
  }

  /// Retourne `false` si [phase] est [TrinityTutorialPhase.none] (rien n’est ajouté).
  static bool placeTrinityGemsForPhase({
    required TrinityTutorialPhase phase,
    required List<GameItem> board,
    required String Function() nextId,
    required TutorialGemTopLeft topLeftForSlot,
  }) {
    final List<({int typeId, int colorId})>? specs =
        TrinityTutorialBoardSpecs.gemsFor(phase);
    if (specs == null) {
      return false;
    }
    int i = 0;
    for (final ({int typeId, int colorId}) s in specs) {
      board.add(
        GameItem(
          id: nextId(),
          typeId: s.typeId,
          colorId: s.colorId,
          position: topLeftForSlot(i),
          floatPeriodMs: 2000,
          floatPhase: i * 0.15,
        ),
      );
      i++;
    }
    return true;
  }
}
