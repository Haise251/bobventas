import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'sale_detail_dialog.dart';

/// Historial de ventas del día con desglose Bs. / $ por pedido.
Future<void> showSalesHistoryDialog(
  BuildContext context, {
  required Future<void> Function() onDataChanged,
}) async {
  final sales = await DatabaseHelper.instance.getTodaySalesWithCurrency();
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Ventas de Hoy',
        style: TextStyle(color: AppTheme.accent),
      ),
      content: SizedBox(
        width: 500,
        height: 450,
        child: sales.isEmpty
            ? const Center(
                child: Text(
                  'No hay ventas registradas hoy.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final s = sales[index];
                  final ticketNumber = (s['ticket_number'] as num).toInt();
                  final total = (s['total'] as num).toDouble();
                  final totalBs = (s['total_bs'] as num? ?? 0).toDouble();
                  final totalUsd = (s['total_usd'] as num? ?? 0).toDouble();
                  final type =
                      s['service_type'] as String? ?? AppConstants.comerAqui;
                  final time = Formatters.timestamp(s['timestamp']);
                  final customerName = s['customer_name'] as String? ?? '';

                  final parts = <String>[];
                  if (totalBs > 0) parts.add(totalBs.toStringAsFixed(2));
                  if (totalUsd > 0) parts.add('\$${totalUsd.toStringAsFixed(2)}');
                  final breakdown = parts.isEmpty
                      ? total.toStringAsFixed(2)
                      : parts.join(' + ');

                  return Card(
                    color: AppTheme.cardDark,
                    child: ListTile(
                      onTap: () => _openDetail(
                          dialogContext, s, onDataChanged),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accent,
                        child: Text(
                          '#$ticketNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      title: Text(
                        customerName.isNotEmpty
                            ? 'Pedido #$ticketNumber ($customerName)'
                            : 'Pedido #$ticketNumber',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '$time  •  ${Formatters.serviceTypeLabel(type)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        breakdown,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
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
      ],
    ),
  );
}

Future<void> _openDetail(
  BuildContext parentContext,
  Map<String, dynamic> sale,
  Future<void> Function() onDataChanged,
) async {
  await showSaleDetailDialog(parentContext, sale: sale, onEdited: onDataChanged);
}
