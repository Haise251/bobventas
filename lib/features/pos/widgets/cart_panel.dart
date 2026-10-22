import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Panel derecho: carrito de ventas con total separado Bs. / $.
class CartPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double total;
  final ({double bs, double usd}) totals;
  final void Function(int index, int delta) onQtyChanged;
  final ValueChanged<int> onToggleService;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;

  const CartPanel({
    super.key,
    required this.items,
    required this.total,
    required this.totals,
    required this.onQtyChanged,
    required this.onToggleService,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'img/logo.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.store,
                  color: AppTheme.accentSoft,
                  size: 200,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final currency = Formatters.currencyFor(
                          isCombo: item['isCombo'] == true);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['quantity']} x ${(item['price'] as num).toStringAsFixed(2)} $currency',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (item['notes'] != null &&
                                (item['notes'] as String).isNotEmpty)
                              Text(
                                item['notes'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
                                ),
                              ),
                            InkWell(
                              onTap: () => onToggleService(index),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item['serviceType'] ==
                                            AppConstants.comerAqui
                                        ? Icons.restaurant
                                        : Icons.takeout_dining,
                                    size: 18,
                                    color: AppTheme.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['serviceType'] ==
                                            AppConstants.comerAqui
                                        ? 'Comer aquí'
                                        : 'Para llevar',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item['isCombo'] != true)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.orangeAccent, size: 24),
                                onPressed: () => onQtyChanged(index, -1),
                              ),
                            if (item['isCombo'] != true)
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.greenAccent, size: 24),
                                onPressed: () => onQtyChanged(index, 1),
                              ),
                            Text(
                              '${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)} $currency',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 24),
                              onPressed: () => onRemove(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1, color: Colors.white10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      if (totals.bs > 0)
                        _totalRow('TOTAL Bs.:', totals.bs, AppTheme.accent, 20),
                      if (totals.usd > 0)
                        _totalRow('TOTAL COMBOS (\$):', totals.usd,
                            Colors.greenAccent, 20),
                      _totalRow('TOTAL:', total, AppTheme.accent, 28,
                          boldLabel: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Carrito de Ventas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.accent,
          ),
        ),
        if (items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
            onPressed: onClear,
          ),
      ],
    );
  }

  Widget _totalRow(String label, num amount, Color color, double fontSize,
      {bool boldLabel = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: boldLabel ? 24 : 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
