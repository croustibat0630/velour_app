import '../providers/game_state_types.dart';

/// Gemmes figées des trois étapes du tutoriel narratif (première partie).
abstract final class NarrativeTutorialBoardSpecs {
  static const List<({int typeId, int colorId})> step1Gems = <({int typeId, int colorId})>[
    (typeId: 7, colorId: 1),
    (typeId: 7, colorId: 3),
    (typeId: 7, colorId: 4),
  ];

  static const List<({int typeId, int colorId})> step2Gems = <({int typeId, int colorId})>[
    (typeId: 1, colorId: 2),
    (typeId: 7, colorId: 2),
    (typeId: 4, colorId: 2),
  ];

  static const int step3TypeId = 7;
  static const int step3ColorId = 2;
  static const int step3GemCount = 3;
}

/// Gemmes figées du tutoriel « Trinité » par phase plateau.
abstract final class TrinityTutorialBoardSpecs {
  /// `null` si aucun plateau scripté (phase [TrinityTutorialPhase.none]).
  static List<({int typeId, int colorId})>? gemsFor(TrinityTutorialPhase phase) {
    switch (phase) {
      case TrinityTutorialPhase.shape:
        // Même forme, 3 couleurs (type 1 = pas de verrou triangle/cyan).
        return const <({int typeId, int colorId})>[
          (typeId: 1, colorId: 1),
          (typeId: 1, colorId: 2),
          (typeId: 1, colorId: 3),
        ];
      case TrinityTutorialPhase.color:
        // 3 formes différentes, même « or » (couleur 2).
        return const <({int typeId, int colorId})>[
          (typeId: 1, colorId: 2),
          (typeId: 2, colorId: 2),
          (typeId: 4, colorId: 2),
        ];
      case TrinityTutorialPhase.perfect:
        return const <({int typeId, int colorId})>[
          (typeId: 2, colorId: 3),
          (typeId: 2, colorId: 3),
          (typeId: 2, colorId: 3),
        ];
      case TrinityTutorialPhase.none:
        return null;
    }
  }
}
