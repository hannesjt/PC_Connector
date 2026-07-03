import 'package:flutter/material.dart';
import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play product ID for the Pro subscription.
/// Must match exactly what you create in Google Play Console.
const kProProductId = 'pc_connector_pro_monthly';

/// Free-tier limits
const kFreeMaxProfiles = 1;
const kFreeMaxScripts = 3;

/// Machine-readable purchase error causes. The UI maps these to localized text.
enum PurchaseErrorCode { none, storeUnavailable, productNotFound }

class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool _isPro = false;
  bool _loading = true;
  String? _error;
  PurchaseErrorCode _errorCode = PurchaseErrorCode.none;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPro => _isPro;
  bool get loading => _loading;
  String? get error => _error;
  PurchaseErrorCode get errorCode => _errorCode;

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> init() async {
    // Restore cached status immediately (no flicker on start)
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;
    _loading = false;
    notifyListeners();

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    // Listen for purchase updates (renewals, restorations, new purchases)
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    // Restore existing purchases so returning users are unlocked
    await InAppPurchase.instance.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Purchase flow
  // -------------------------------------------------------------------------

  Future<bool> buyPro() async {
    _error = null;
    _errorCode = PurchaseErrorCode.none;
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _errorCode = PurchaseErrorCode.storeUnavailable;
      notifyListeners();
      return false;
    }

    final response =
        await InAppPurchase.instance.queryProductDetails({kProProductId});

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      _errorCode = PurchaseErrorCode.productNotFound;
      notifyListeners();
      return false;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    // Subscriptions use buyNonConsumable
    return await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == kProProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setProStatus(true);
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        } else if (purchase.status == PurchaseStatus.error) {
          _error = purchase.error?.message ?? 'Kauf fehlgeschlagen';
          notifyListeners();
        }
      }
    }
  }

  Future<void> _setProStatus(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }
}
