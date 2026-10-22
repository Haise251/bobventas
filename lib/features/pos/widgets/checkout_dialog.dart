import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/print/print_service.dart';
import '../../../core/utils/formatters.dart';

/// Diálogo de checkout: vista previa del ticket (igual que la versión
/// original) y botón "Imprimir y Finalizar".
///
/// Al confirmar: toma número de ticket, guarda la venta e imprime el
/// ticket completo (cliente + áreas + número) con manejo de errores de
/// impresión (la venta ya queda guardada aunque falle la impresora).
void showCheckoutDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> items,
  required TextEditingController customNameController,
  required double total,
  required VoidCallback onFinished,
}) {
  customNameController.clear();

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final comerQty = items
            .where((i) => i['serviceType'] == AppConstants.comerAqui)
            .fold<int>(0, (s, i) => s + (i['quantity'] as int));
        final llevarQty = items
            .where((i) => i['serviceType'] == AppConstants.paraLlevar)
            .fold<int>(0, (s, i) => s + (i['quantity'] as int));

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            content: SingleChildScrollView(
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BOB BURGUER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: customNameController,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Nombre / Salchipapa (Opcional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comerQty > 0 && llevarQty > 0
                          ? 'Comer aquí: $comerQty | Para llevar: $llevarQty'
                          : (comerQty > 0 ? 'Comer aquí' : 'Para llevar'),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const Text(
                      '--------------------------------',
                      style: TextStyle(color: Colors.black),
                    ),
                    ...items.map((item) {
                      final currency = Formatters.currencyFor(
                          isCombo: item['isCombo'] == true);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['quantity']}x ${item['name']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)} $currency',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          if ((item['notes'] as String? ?? '').isNotEmpty)
                            Text(
                              '  ${item['notes']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          Text(
                            '  [${Formatters.serviceTypeLabel(item['serviceType'])}]',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      );
                    }),
                    const Text(
                      '--------------------------------',
                      style: TextStyle(color: Colors.black),
                    ),
                    ..._buildTotalRows(items),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _finishSale(
                    dialogContext,
                    items: items,
                    total: total,
                    customNameController: customNameController,
                    onFinished: onFinished,
                  );
                },
                child: const Text('Imprimir y Finalizar'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _finishSale(
  BuildContext dialogContext, {
  required List<Map<String, dynamic>> items,
  required double total,
  required TextEditingController customNameController,
  required VoidCallback onFinished,
}) async {
  final messenger = ScaffoldMessenger.of(dialogContext);
  final navigator = Navigator.of(dialogContext);

  final comer = items.any((i) => i['serviceType'] == AppConstants.comerAqui);
  final llevar =
      items.any((i) => i['serviceType'] == AppConstants.paraLlevar);
  final orderServiceType = comer && llevar
      ? AppConstants.mixto
      : (comer ? AppConstants.comerAqui : AppConstants.paraLlevar);

  final customerNameInput = customNameController.text.trim();
  final ticketNumber =
      await DatabaseHelper.instance.getTodayNextTicketNumber();
  await DatabaseHelper.instance.saveSale(
    total,
    items,
    orderServiceType,
    ticketNumber: ticketNumber,
    customerName: customerNameInput,
  );

  // La venta ya está guardada: la impresión puede fallar sin perder datos.
  try {
    await PrintService.instance.printFullSale(
      ticketNumber: ticketNumber,
      serviceType: orderServiceType,
      items: List<Map<String, dynamic>>.from(items),
      total: total,
      customerName: customerNameInput,
    );
    messenger.showSnackBar(SnackBar(
      content: Text('Pedido #$ticketNumber guardado e impreso.'),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Pedido #$ticketNumber guardado. No se pudo imprimir: $e'),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 5),
    ));
  }

  onFinished();
  navigator.pop();
}

/// Filas de totales separadas por moneda (igual que el ticket impreso).
List<Widget> _buildTotalRows(List<Map<String, dynamic>> items) {
  final totals = Formatters.splitTotals(items);
  final rows = <Widget>[];
  if (totals.bs > 0) {
    rows.add(_boldRow('TOTAL Bs.:', totals.bs.toStringAsFixed(2)));
  }
  if (totals.usd > 0) {
    rows.add(_boldRow('TOTAL COMBOS (\$):', totals.usd.toStringAsFixed(2)));
  }
  final grand = totals.bs + totals.usd;
  rows.add(_boldRow('TOTAL:', grand.toStringAsFixed(2)));
  return rows;
}

Widget _boldRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  );
}
