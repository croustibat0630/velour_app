import 'package:flutter_test/flutter_test.dart';
import 'package:velour_app/game/forge_shop_logic.dart';
import 'package:velour_app/providers/game_state_types.dart';

void main() {
  group('oracleInsuranceRefundLux', () {
    test('60% of high stakes ante', () {
      expect(
        oracleInsuranceRefundLux(
          endedStake: SessionStakeKind.highStakes,
          highStakesAnteLux: 50,
          royalAnteLux: 250,
          refundPercentOfAnte: 60,
        ),
        30,
      );
    });

    test('60% of royal ante', () {
      expect(
        oracleInsuranceRefundLux(
          endedStake: SessionStakeKind.royal,
          highStakesAnteLux: 50,
          royalAnteLux: 250,
          refundPercentOfAnte: 60,
        ),
        150,
      );
    });

    test('casual yields 0', () {
      expect(
        oracleInsuranceRefundLux(
          endedStake: SessionStakeKind.casual,
          highStakesAnteLux: 50,
          royalAnteLux: 250,
          refundPercentOfAnte: 60,
        ),
        0,
      );
    });
  });

  group('isPremiumStakeFailure', () {
    test('detects fail footers', () {
      expect(isPremiumStakeFailure(SessionStakeFooterLine.highStakesFail), true);
      expect(isPremiumStakeFailure(SessionStakeFooterLine.royalFail), true);
      expect(isPremiumStakeFailure(SessionStakeFooterLine.none), false);
      expect(
        isPremiumStakeFailure(SessionStakeFooterLine.highStakesWin150Lux),
        false,
      );
    });
  });
}
