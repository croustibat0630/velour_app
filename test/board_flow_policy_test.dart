import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/board_flow_policy.dart';

void main() {
  test('haute chaleur réduit le biais de complétion', () {
    final double lowHeat = BoardFlowPolicy.slotCompletionBiasChance(
      heatTierClamp0to5: 1,
      timeBarFraction: 0.5,
    );
    final double highHeat = BoardFlowPolicy.slotCompletionBiasChance(
      heatTierClamp0to5: 5,
      timeBarFraction: 0.5,
    );
    expect(highHeat, lessThan(lowHeat));
  });

  test('bas chrono + faible chaleur augmente le secours', () {
    final double ok = BoardFlowPolicy.slotCompletionBiasChance(
      heatTierClamp0to5: 2,
      timeBarFraction: 0.5,
    );
    final double rescue = BoardFlowPolicy.slotCompletionBiasChance(
      heatTierClamp0to5: 2,
      timeBarFraction: 0.1,
    );
    expect(rescue, greaterThanOrEqualTo(ok));
  });
}
