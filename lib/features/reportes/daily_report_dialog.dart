import 'package:flutter/material.dart';

import '../../core/services/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../pos/widgets/catalog_dialogs.dart';

/// Resumen de ventas del día, separando monedas:
///  - Bs.  → productos normales (perros, hamburguesas, bebidas...)
///  - $    → combos (solo se venden en divisas)
Future<void> showDailyReportDialog(
  BuildContext context, {
  required Future<void> Function() onClearToday,
}) async {
  final totals = await DatabaseHelper.instance.getTodayTotalsByCurrency();
  final summary =
      await DatabaseHelper.instance.getTodaySalesSummaryByCurrency();

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Resumen de Ventas',
        style: TextStyle(color: AppTheme.accent),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _totalCard(
              'VENTAS EN Bs. (productos)',
              totals.totalBs.toStringAsFixed(2),
              AppTheme.accent,
            ),
            const SizedBox(height: 8),
            _totalCard(
              'VENTAS EN \$ (combos)',
              totals.totalUsd.toStringAsFixed(2),
              Colors.greenAccent,
            ),
            const Divider(color: AppTheme.accent),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Desglose por producto:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: summary.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Aún no hay ventas hoy.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: summary.length,
                      itemBuilder: (context, index) {
                        final s = summary[index];
                        final isCombo = (s['is_combo'] as num? ?? 0) == 1;
                        final qty = (s['qty'] as num? ?? 0);
                        final total = (s['total'] as num? ?? 0);
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isCombo ? Icons.local_offer : Icons.fastfood,
                            size: 18,
                            color: isCombo
                                ? Colors.greenAccent
                                : AppTheme.accent,
                          ),
                          title: Text(
                            s['product_name'],
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            isCombo ? '\$ (combo)' : 'Bs.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCombo
                                  ? Colors.greenAccent
                                  : Colors.white54,
                            ),
                          ),
                          trailing: Text(
                            '${qty} und. — ${Formatters.money(total, isCombo: isCombo)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCombo
                                  ? Colors.greenAccent
                                  : AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
        TextButton.icon(
          onPressed: () => confirmClearTodaySales(
            dialogContext,
            onConfirm: onClearToday,
          ),
          icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
          label: const Text(
            'Limpiar Ventas del Día',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}

Widget _totalCard(String label, String value, Color color) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );
}
