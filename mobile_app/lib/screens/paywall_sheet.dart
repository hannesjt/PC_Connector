import 'package:flutter/material.dart';

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
    setState(() {
      _buying = true;
      _error = null;
    });
    final ok = await PurchaseService.instance.buyPro();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _buying = false;
        _error = PurchaseService.instance.error ?? 'Kauf abgebrochen';
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Icon(Icons.workspace_premium, size: 52, color: cs.primary),
          const SizedBox(height: 8),
          Text('PC Connector Pro',
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
            (Icons.all_inclusive, 'Unbegrenzte Skripte (Gratis: 3)'),
            (Icons.account_tree_outlined, 'Abläufe & Script-Chains'),
            (Icons.folder_outlined, 'Kategorien & Gruppen'),
            (Icons.computer, 'Mehrere PC-Profile'),
            (Icons.public, 'Globale Skripte'),
            (Icons.sort, 'Reihenfolge anpassen'),
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
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _buying
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Pro freischalten – 3 €/Monat'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _buying ? null : _restore,
            child: const Text('Kauf wiederherstellen'),
          ),
        ],
      ),
    );
  }
}
