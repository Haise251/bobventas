import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/database_helper.dart';
import '../../core/services/print/print_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'editable_sale_dialog.dart';

/// Detalle de un pedido con desglose Bs. / $ y acciones de
/// edición y reimpresión.
Future<void> showSaleDetailDialog(
  BuildContext context, {
  required Map<String, dynamic> sale,
  required Future<void> Function() onEdited,
}) async {
  final saleId = sale['id'] as int;
  final itemsRaw = await DatabaseHelper.instance.getSaleItems(saleId);
  final items = itemsRaw.map(_dbItemToCartItem).toList();
  final ticketNumber = (sale['ticket_number'] as num).toInt();
  final serviceType =
      sale['service_type'] as String? ?? AppConstants.comerAqui;
  final total = (sale['total'] as num).toDouble();
  final customerName = sale['customer_name'] as String? ?? '';
  final totals = Formatters.splitTotals(items);

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        customerName.isNotEmpty
            ? 'Pedido #$ticketNumber - $customerName'
            : 'Pedido #$ticketNumber',
        style: const TextStyle(color: AppTheme.accent),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${Formatters.serviceTypeLabel(serviceType)}  •  ${Formatters.timestamp(sale['timestamp'])}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: AppTheme.accent),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final currency =
                      Formatters.currencyFor(isCombo: item['isCombo'] == true);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item['quantity']}x ${item['name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: (item['notes'] as String).isNotEmpty
                        ? Text(
                            item['notes'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppTheme.accent),
            if (totals.bs > 0)
              _totalLine('TOTAL Bs.:', totals.bs),
            if (totals.usd > 0)
              _totalLine('TOTAL COMBOS (\$):', totals.usd, isUsd: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} Bs.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
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
          onPressed: () async {
            final edited = await showDialog<List<Map<String, dynamic>>?>(
              context: dialogContext,
              builder: (_) => EditableSaleDialog(
                ticketNumber: ticketNumber,
                items: List<Map<String, dynamic>>.from(items),
                serviceType: serviceType,
              ),
            );
            if (edited == null || !dialogContext.mounted) return;
            final editTotal =
                edited.fold<double>(0.0, (sum, i) => sum + (i['price'] * i['quantity']));
            await DatabaseHelper.instance.updateSaleWithItems(
              saleId,
              editTotal,
              serviceType,
              'FINALIZADO',
              edited,
            );
            await onEdited();
            if (!dialogContext.mounted) return;

            final messenger =
                ScaffoldMessenger.of(dialogContext);
            final navigator = Navigator.of(dialogContext);

            // Reimprimir (ticket cliente + número).
            try {
              final t = Formatters.splitTotals(edited);
              await PrintService.instance.printSaleTicket(TicketData(
                ticketNumber: ticketNumber,
                serviceType: serviceType,
                items: edited,
                totalBs: t.bs,
                totalUsd: t.usd,
                customerName: customerName,
              ));
              await PrintService.instance.printNumberTicket(ticketNumber,
                  items: edited);
            } catch (e) {
              messenger.showSnackBar(SnackBar(
                content: Text('Guardado. No se pudo reimprimir: $e'),
                backgroundColor: Colors.redAccent,
              ));
            }
            navigator.pop();
          },
          icon: const Icon(Icons.print, color: AppTheme.accent),
          label: const Text(
            'Editar y Reimprimir',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final edited = await showDialog<List<Map<String, dynamic>>?>(
              context: dialogContext,
              builder: (_) => EditableSaleDialog(
                ticketNumber: ticketNumber,
                items: List<Map<String, dynamic>>.from(items),
                serviceType: serviceType,
              ),
            );
            if (edited == null || !dialogContext.mounted) return;
            final editTotal =
                edited.fold<double>(0.0, (sum, i) => sum + (i['price'] * i['quantity']));
            await DatabaseHelper.instance.updateSaleWithItems(
              saleId,
              editTotal,
              serviceType,
              'FINALIZADO',
              edited,
            );
            await onEdited();
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('Pedido actualizado correctamente.'),
              ),
            );
            Navigator.pop(dialogContext);
          },
          icon: const Icon(Icons.edit, color: AppTheme.accent),
          label: const Text(
            'Editar',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
      ],
    ),
  );
}

Widget _totalLine(String label, num amount, {bool isUsd = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isUsd ? Colors.greenAccent : Colors.white,
        ),
      ),
      Text(
        amount.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isUsd ? Colors.greenAccent : AppTheme.accent,
        ),
      ),
    ],
  );
}

/// Convierte una fila de sale_items al formato de ítem del carrito.
Map<String, dynamic> _dbItemToCartItem(Map<String, dynamic> dbItem) {
  return {
    'name': dbItem['product_name'],
    'price': (dbItem['price'] as num).toDouble(),
    'quantity': (dbItem['quantity'] as num).toInt(),
    'notes': dbItem['notes'] ?? '',
    'isCombo': (dbItem['is_combo'] as num? ?? 0) == 1,
    'serviceType': dbItem['service_type'] ?? AppConstants.comerAqui,
    'area': dbItem['area'] ?? AppConstants.areaCocina,
  };
}
