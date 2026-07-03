import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

/// Shows a bottom sheet explaining what Pro includes and triggers the purchase.
Future<void> showPaywallSheet(BuildContext context, {String? reason}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PaywallSheet(reason: reason),
  );
}

class PaywallSheet extends StatefulWidget {
  final String? reason;
  const PaywallSheet({super.key, this.reason});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  bool _buying = false;
  String? _error;

  Future<void> _buy() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _buying = true;
      _error = null;
    });
    final ok = await PurchaseService.instance.buyPro();
    if (!mounted) return;
    if (!ok) {
      final code = PurchaseService.instance.errorCode;
      setState(() {
        _buying = false;
        _error = switch (code) {
          PurchaseErrorCode.storeUnavailable => l.storeUnavailable,
          PurchaseErrorCode.productNotFound => l.productNotFound,
          _ => PurchaseService.instance.error ?? l.purchaseCancelled,
        };
      });
    } else {
      // Purchase stream will update isPro; close sheet
      Navigator.of(context).pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _buying = true);
    await PurchaseService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _buying = false);
    if (PurchaseService.instance.isPro) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Icon(Icons.workspace_premium, size: 52, color: cs.primary),
          const SizedBox(height: 8),
          Text(l.pcConnectorPro,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          if (widget.reason != null) ...[
            Text(
              widget.reason!,
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // Feature list
          const SizedBox(height: 4),
          ...[
            (Icons.all_inclusive, l.featureUnlimitedScripts),
            (Icons.account_tree_outlined, l.featureChains),
            (Icons.folder_outlined, l.featureCategories),
            (Icons.computer, l.featureMultiPc),
            (Icons.public, l.featureGlobalScripts),
            (Icons.sort, l.featureReorder),
          ].map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(e.$1, size: 20, color: cs.primary),
                  const SizedBox(width: 12),
                  Text(e.$2),
                ]),
              )),

          const SizedBox(height: 20),

          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 8),
          ],

          FilledButton(
            onPressed: _buying ? null : _buy,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _buying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(l.unlockPro),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _buying ? null : _restore,
            child: Text(l.restorePurchase),
          ),
        ],
      ),
    );
  }
}
