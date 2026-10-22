import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../constants/app_constants.dart';

/// Plantillas PDF de 58 mm para Windows (impresión vía driver del sistema).
///
/// Mantiene el mismo diseño que la versión original pero con los totales
/// separados por moneda (Bs. productos / $ combos).
class PdfTemplates {
  PdfTemplates._();

  static const PdfPageFormat _format58 = PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 2 * PdfPageFormat.mm,
  );

  // =========================================================================
  // TICKET 1 — TICKET DE VENTA (cliente)
  // =========================================================================
  static Future<Uint8List> saleTicket({
    required String businessName,
    required int ticketNumber,
    required String serviceType,
    required List<Map<String, dynamic>> items,
    required double totalBs,
    required double totalUsd,
    String customerName = '',
  }) {
    final doc = pw.Document();

    final aqui = items
        .where((i) => i['serviceType'] == AppConstants.comerAqui)
        .toList();
    final llevar = items
        .where((i) => i['serviceType'] == AppConstants.paraLlevar)
        .toList();

    doc.addPage(
      pw.Page(
        pageFormat: _format58,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  businessName,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),
              ),
              if (customerName.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'CLIENTE/NOTA: $customerName',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
              pw.Center(
                child: pw.Text('PEDIDO #$ticketNumber',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Center(
                child: pw.Text(
                  (aqui.isNotEmpty && llevar.isNotEmpty)
                      ? 'Comer aquí: ${aqui.length} | Para llevar: ${llevar.length}'
                      : (aqui.isNotEmpty
                          ? 'Comer aquí'
                          : 'Para llevar'),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              if (aqui.isNotEmpty) _section('--- COMER AQUÍ ---', aqui),
              if (llevar.isNotEmpty) _section('--- PARA LLEVAR ---', llevar),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              if (totalBs > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('${totalBs.toStringAsFixed(2)} Bs.',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
              if (totalUsd > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL COMBOS:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('${totalUsd.toStringAsFixed(2)} \$',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('¡Gracias por su compra!',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // =========================================================================
  // TICKET 2 — TICKET DE ÁREA (COCINA / SALCHIPAPAS)
  // =========================================================================
  static Future<Uint8List> areaTicket({
    required String businessName,
    required String areaTitle,
    required int ticketNumber,
    required List<Map<String, dynamic>> items,
    String customerName = '',
  }) {
    final doc = pw.Document();
    final totalUnits = items.fold<int>(
        0, (sum, i) => sum + ((i['quantity'] as num?) ?? 0).toInt());

    doc.addPage(
      pw.Page(
        pageFormat: _format58,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  areaTitle,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: areaTitle == AppConstants.areaSalchipapas
                        ? 18
                        : 14,
                  ),
                ),
              ),
              if (customerName.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'NOTA/SALCHI: $customerName',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              pw.Center(
                child: pw.Text('PEDIDO #$ticketNumber',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 3),
              ...items.map((item) {
                final notes = (item['notes'] ?? '').toString().trim();
                final tag = item['serviceType'] == AppConstants.paraLlevar
                    ? '[LLEVAR]'
                    : '[AQUI]';
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item['quantity']}x ${item['name']}',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(tag,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (notes.isNotEmpty)
                      pw.Padding(
                        padding:
                            const pw.EdgeInsets.only(left: 4, top: 1),
                        child: pw.Text('($notes)',
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),
              pw.Text('Unidades: $totalUnits',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // =========================================================================
  // TICKET 3 — TICKET DE NÚMERO DE PEDIDO
  // =========================================================================
  static Future<Uint8List> numberTicket({
    required int ticketNumber,
    List<Map<String, dynamic>> items = const [],
    Uint8List? logoBytes,
  }) {
    final doc = pw.Document();
    final hasDrink = items
        .any((i) => (i['area'] ?? AppConstants.areaCocina) ==
            AppConstants.areaBebidas);

    doc.addPage(
      pw.Page(
        pageFormat: _format58,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('PEDIDO',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(pw.MemoryImage(logoBytes),
                          fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      width: 60,
                      height: 60,
                      alignment: pw.Alignment.center,
                      child: pw.Text('BOB',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ),
                  pw.SizedBox(width: 8),
                  pw.Text('#$ticketNumber',
                      style: pw.TextStyle(
                          fontSize: 36, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(hasDrink ? 'CON BEBIDA' : 'SIN BEBIDA',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('¡Gracias por su compra!',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // =========================================================================
  // TICKET DE PRUEBA
  // =========================================================================
  static Future<Uint8List> testTicket({required String businessName}) {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: _format58,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('PRUEBA DE IMPRESIÓN',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('Impresora conectada correctamente',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Center(
                child: pw.Text('Formato: 58 mm — vía driver de Windows',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(businessName,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('¡Gracias por su compra!',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // =========================================================================
  // Helpers
  // =========================================================================
  static pw.Widget _section(String title, List<Map<String, dynamic>> list) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        ...list.map((item) {
          final lineTotal =
              ((item['price'] as num) * (item['quantity'] as num))
                  .toStringAsFixed(2);
          final currency = item['isCombo'] ? r'$' : 'Bs.';
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${item['quantity']}x ${item['name']}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Text('$lineTotal $currency',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if ((item['notes'] ?? '').toString().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10),
                  child: pw.Text('(${item['notes']})',
                      style: pw.TextStyle(
                          fontSize: 8, fontStyle: pw.FontStyle.italic)),
                ),
              pw.SizedBox(height: 2),
            ],
          );
        }),
      ],
    );
  }
}
