import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/services/lux_iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LuxIapService.debugSkipCloudPurchaseSync = true;

  group('LuxIapProducts', () {
    test('vaultIds and luxForProductId', () {
      expect(LuxIapProducts.vaultIds, hasLength(3));
      expect(LuxIapProducts.vaultIds, contains(LuxIapProducts.sparkReserve));
      expect(LuxIapProducts.luxForProductId(LuxIapProducts.sparkReserve), 100);
      expect(LuxIapProducts.luxForProductId(LuxIapProducts.oracleTreasure), 750);
      expect(LuxIapProducts.luxForProductId(LuxIapProducts.royalLegacy), 5000);
      expect(LuxIapProducts.luxForProductId('unknown'), 0);
    });
  });

  group('LuxIapService (mock InAppPurchasePlatform)', () {
    late FakeLuxIapPurchasePlatform fake;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      fake = FakeLuxIapPurchasePlatform();
      InAppPurchasePlatform.instance = fake;
      LuxIapService.instance.resetForTesting();
    });

    tearDown(() {
      LuxIapService.debugSkipCloudPurchaseSync = true;
      LuxIapService.instance.resetForTesting();
      LuxIapService.instance.dispose();
      debugDefaultTargetPlatformOverride = null;
      // Ne pas appeler registerPlatform() (Android/StoreKit) : ça ouvre des canaux natifs
      // asynchrones après la fin du test. Un fake neutre suffit pour les suites suivantes.
      InAppPurchasePlatform.instance = FakeLuxIapPurchasePlatform();
    });

    test('invalid product id', () async {
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable('com.unknown');
      expect(r.kind, LuxIapBuyKind.error);
      expect(r.errorDetail, 'invalid_product');
    });

    test('store unavailable', () async {
      fake.storeAvailable = false;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(r.kind, LuxIapBuyKind.unavailable);
    });

    test('products unavailable when query returns empty', () async {
      fake.returnEmptyProducts = true;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(r.kind, LuxIapBuyKind.productsUnavailable);
    });

    test('buyConsumable uses autoConsume false', () async {
      fake.emitKind = LuxIapTestEmitKind.purchased;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(r.kind, LuxIapBuyKind.success);
      expect(fake.lastAutoConsume, isFalse);
    });

    test('success then finalizeAfterLuxDelivered calls completePurchase', () async {
      fake.emitKind = LuxIapTestEmitKind.purchased;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.oracleTreasure);
      expect(r.kind, LuxIapBuyKind.success);
      expect(r.luxAmount, 750);

      await LuxIapService.instance.finalizeAfterLuxDelivered();

      expect(fake.completedPurchaseIds, isNotEmpty);
      expect(fake.completedPurchaseIds.length, 1);
    });

    test('duplicate purchaseId while awaiting yields duplicate_transaction', () async {
      fake.emitKind = LuxIapTestEmitKind.purchased;
      fake.purchaseIdFor = (_) => 'shared-tx';

      final LuxIapBuyOutcome first =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(first.kind, LuxIapBuyKind.success);
      await LuxIapService.instance.finalizeAfterLuxDelivered();

      final LuxIapBuyOutcome second =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(second.kind, LuxIapBuyKind.error);
      expect(second.errorDetail, 'duplicate_transaction');
    });

    test('cancelled purchase', () async {
      fake.emitKind = LuxIapTestEmitKind.canceled;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(r.kind, LuxIapBuyKind.cancelled);
    });

    test('launch_failed when buyConsumable returns false', () async {
      fake.launchReturnsTrue = false;
      final LuxIapBuyOutcome r =
          await LuxIapService.instance.buyVaultConsumable(LuxIapProducts.sparkReserve);
      expect(r.kind, LuxIapBuyKind.error);
      expect(r.errorDetail, 'launch_failed');
    });
  });
}

enum LuxIapTestEmitKind { purchased, canceled, error }

class FakeLuxIapPurchasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _purchaseEvents =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool storeAvailable = true;
  bool returnEmptyProducts = false;
  bool launchReturnsTrue = true;
  LuxIapTestEmitKind emitKind = LuxIapTestEmitKind.purchased;
  bool? lastAutoConsume;
  String Function(String productId)? purchaseIdFor;

  final List<String> completedPurchaseIds = <String>[];

  int _seq = 0;

  String _purchaseIdFor(String productId) =>
      purchaseIdFor?.call(productId) ?? 'test-purchase-${_seq++}';

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseEvents.stream;

  @override
  Future<bool> isAvailable() => Future<bool>.value(storeAvailable);

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    if (returnEmptyProducts) {
      return Future<ProductDetailsResponse>.value(
        ProductDetailsResponse(
          productDetails: <ProductDetails>[],
          notFoundIDs: identifiers.toList(),
        ),
      );
    }
    final List<ProductDetails> list = identifiers
        .map(
          (String id) => ProductDetails(
            id: id,
            title: id,
            description: 'd',
            price: '1',
            rawPrice: 1,
            currencyCode: 'EUR',
          ),
        )
        .toList();
    return Future<ProductDetailsResponse>.value(
      ProductDetailsResponse(productDetails: list, notFoundIDs: <String>[]),
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) {
    lastAutoConsume = autoConsume;
    if (!launchReturnsTrue) {
      return Future<bool>.value(false);
    }
    final String productId = purchaseParam.productDetails.id;
    final PurchaseDetails details = _purchaseDetails(productId);
    _purchaseEvents.add(<PurchaseDetails>[details]);
    return Future<bool>.value(true);
  }

  PurchaseDetails _purchaseDetails(String productId) {
    final String pid = _purchaseIdFor(productId);
    switch (emitKind) {
      case LuxIapTestEmitKind.purchased:
        return PurchaseDetails(
          purchaseID: pid,
          productID: productId,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'l',
            serverVerificationData: 's',
            source: 'test',
          ),
          transactionDate: '1',
          status: PurchaseStatus.purchased,
        )..pendingCompletePurchase = true;
      case LuxIapTestEmitKind.canceled:
        return PurchaseDetails(
          purchaseID: pid,
          productID: productId,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'l',
            serverVerificationData: 's',
            source: 'test',
          ),
          transactionDate: null,
          status: PurchaseStatus.canceled,
        )..pendingCompletePurchase = true;
      case LuxIapTestEmitKind.error:
        return PurchaseDetails(
          purchaseID: pid,
          productID: productId,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'l',
            serverVerificationData: 's',
            source: 'test',
          ),
          transactionDate: null,
          status: PurchaseStatus.error,
        )..error = IAPError(source: 'test', code: 'e1', message: 'oops')
          ..pendingCompletePurchase = true;
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    final String? id = purchase.purchaseID;
    if (id != null) {
      completedPurchaseIds.add(id);
    }
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      Future<bool>.value(true);

  @override
  Future<void> restorePurchases({String? applicationUserName}) => Future<void>.value();

  @override
  Future<String> countryCode() => Future<String>.value('FRA');
}
