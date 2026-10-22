import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../constants/app_constants.dart';
import '../settings_service.dart';
import 'esc_pos_templates.dart';
export 'esc_pos_templates.dart' show TicketData;
import 'pdf_templates.dart';
import 'thermal_usb_printer.dart';

/// Excepción amigable cuando no hay impresora configurada.
class PrinterNotConfiguredException implements Exception {
  final String message;
  PrinterNotConfiguredException(this.message);
  @override
  String toString() => message;
}

/// Modelo simple de impresora para la UI (Ajustes).
class AppPrinterInfo {
  final String id;
  final String name;
  final bool isUsb;

  const AppPrinterInfo({
    required this.id,
    required this.name,
    required this.isUsb,
  });
}

/// Fachada de impresión del POS.
///
/// - **Windows**: PDF de 58 mm enviado al driver del sistema
///   (`printing` / `Printing.directPrintPdf`), igual que la versión original.
/// - **Android**: comandos ESC/POS nativos enviados por USB OTG con
///   `flutter_thermal_printer` (impresora térmica 58 mm).
///
/// El resto de la app solo conoce `PrintService.printSaleTicket(...)`,
/// `printAreaTicket(...)` y `printNumberTicket(...)`.
class PrintService {
  PrintService._();
  static final PrintService instance = PrintService._();

  final ThermalUsbPrinter _usb = ThermalUsbPrinter.instance;
  final SettingsService _settings = SettingsService.instance;

  Uint8List? _logoBytes;
  bool _logoLoaded = false;

  bool get _isWindows => Platform.isWindows;
  bool get _isAndroid => Platform.isAndroid;

  Future<void> _ensureLogo() async {
    if (_logoLoaded) return;
    try {
      final data = await rootBundle.load('img/logo.png');
      _logoBytes = data.buffer.asUint8List();
    } catch (_) {
      _logoBytes = null;
    }
    _logoLoaded = true;
  }

  // =========================================================================
  // LISTADO DE IMPRESORAS (para la pantalla de Ajustes)
  // =========================================================================

  /// Impresoras USB (Android OTG / escritorio).
  Future<List<AppPrinterInfo>> listUsbPrinters() async {
    final devices = await _usb.scanUsbPrinters();
    return devices
        .map((d) => AppPrinterInfo(
              id: ThermalUsbPrinter.idOf(d),
              name: d.name ?? 'Impresora USB (${d.vendorId ?? '?'})',
              isUsb: true,
            ))
        .toList();
  }

  /// Impresoras del sistema (Windows).
  Future<List<AppPrinterInfo>> listSystemPrinters() async {
    try {
      final printers = await Printing.listPrinters();
      return printers
          .map((p) => AppPrinterInfo(id: p.name, name: p.name, isUsb: false))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Guarda la impresora USB seleccionada (Android).
  Future<void> selectUsbPrinter(String id) => _settings.setUsbPrinterId(id);

  /// Guarda la impresora de sistema seleccionada (Windows).
  Future<void> selectSystemPrinter(String name) =>
      _settings.setSystemPrinterName(name);

  // =========================================================================
  // IMPRESIÓN DE TICKETS
  // =========================================================================

  /// TICKET DE VENTA (el del cliente con items y totales).
  Future<void> printSaleTicket(TicketData data) async {
    await _ensureLogo();

    if (_isWindows) {
      final name = await _settings.getSystemPrinterName();
      final bytes = await PdfTemplates.saleTicket(
        businessName: await _settings.getBusinessName(),
        ticketNumber: data.ticketNumber,
        serviceType: data.serviceType,
        items: data.items,
        totalBs: data.totalBs,
        totalUsd: data.totalUsd,
        customerName: data.customerName,
      );
      await _printPdfWindows(bytes, name,
          fallbackName: 'Ticket_Bob_Burguer');
    } else if (_isAndroid) {
      final bytes = await EscPosTemplates.saleTicket(data);
      await _printEscPosAndroid(bytes);
    }
  }

  /// TICKET DE ÁREA (COCINA o SALCHIPAPAS).
  Future<void> printAreaTicket({
    required String areaTitle,
    required int ticketNumber,
    required List<Map<String, dynamic>> items,
    String customerName = '',
  }) async {
    await _ensureLogo();

    if (_isWindows) {
      final name = await _settings.getSystemPrinterName();
      final bytes = await PdfTemplates.areaTicket(
        businessName: await _settings.getBusinessName(),
        areaTitle: areaTitle,
        ticketNumber: ticketNumber,
        items: items,
        customerName: customerName,
      );
      await _printPdfWindows(bytes, name,
          fallbackName: 'Ticket_${areaTitle}_Bob_Burguer');
    } else if (_isAndroid) {
      final bytes = await EscPosTemplates.areaTicket(
        areaTitle: areaTitle,
        ticketNumber: ticketNumber,
        items: items,
        customerName: customerName,
      );
      await _printEscPosAndroid(bytes);
    }
  }

  /// TICKET DE NÚMERO DE PEDIDO (con logo y CON/SIN BEBIDA).
  Future<void> printNumberTicket(
    int ticketNumber, {
    List<Map<String, dynamic>> items = const [],
  }) async {
    await _ensureLogo();

    if (_isWindows) {
      final name = await _settings.getSystemPrinterName();
      final bytes = await PdfTemplates.numberTicket(
        ticketNumber: ticketNumber,
        items: items,
        logoBytes: _logoBytes,
      );
      await _printPdfWindows(bytes, name,
          fallbackName: 'Numero_Pedido_Bob_Burguer');
    } else if (_isAndroid) {
      final bytes = await EscPosTemplates.numberTicket(
        ticketNumber,
        items: items,
        logoBytes: _logoBytes,
      );
      await _printEscPosAndroid(bytes);
    }
  }

  /// Ticket de prueba (Ajustes → "Probar impresora").
  Future<void> printTest() async {
    if (_isWindows) {
      final name = await _settings.getSystemPrinterName();
      final bytes = await PdfTemplates.testTicket(
          businessName: await _settings.getBusinessName());
      await _printPdfWindows(bytes, name, fallbackName: 'Prueba_Impresion');
    } else if (_isAndroid) {
      final bytes = await EscPosTemplates.testTicket();
      await _printEscPosAndroid(bytes);
    }
  }

  /// Flujo completo de una venta (ticket cliente + áreas + número),
  /// con las mismas pausas de 2 s que la versión original.
  Future<void> printFullSale({
    required int ticketNumber,
    required String serviceType,
    required List<Map<String, dynamic>> items,
    required double total,
    String customerName = '',
  }) async {
    final totals = _splitTotals(items);

    await printSaleTicket(TicketData(
      ticketNumber: ticketNumber,
      serviceType: serviceType,
      items: items,
      totalBs: totals.bs,
      totalUsd: totals.usd,
      customerName: customerName,
    ));

    final cocinaItems = items
        .where((i) => (i['area'] ?? AppConstants.areaCocina) ==
            AppConstants.areaCocina)
        .toList();
    final salchipapaItems = items
        .where((i) => (i['area'] ?? AppConstants.areaCocina) ==
            AppConstants.areaSalchipapas)
        .toList();

    if (cocinaItems.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      await printAreaTicket(
        areaTitle: AppConstants.areaCocina,
        ticketNumber: ticketNumber,
        items: cocinaItems,
        customerName: customerName,
      );
    }

    if (salchipapaItems.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      await printAreaTicket(
        areaTitle: AppConstants.areaSalchipapas,
        ticketNumber: ticketNumber,
        items: salchipapaItems,
        customerName: customerName,
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    await printNumberTicket(ticketNumber, items: items);
  }

  // =========================================================================
  // Internos por plataforma
  // =========================================================================

  ({double bs, double usd}) _splitTotals(List<Map<String, dynamic>> items) {
    double bs = 0, usd = 0;
    for (final i in items) {
      final price = (i['price'] as num?) ?? 0;
      final qty = (i['quantity'] as num?) ?? 0;
      if (i['isCombo'] == true) {
        usd += price * qty;
      } else {
        bs += price * qty;
      }
    }
    return (bs: bs, usd: usd);
  }

  /// Windows: envía el PDF al driver guardado; si no hay driver configurado
  /// abre el diálogo de impresión del sistema.
  Future<void> _printPdfWindows(Uint8List bytes, String? printerName,
      {required String fallbackName}) async {
    try {
      final printers = await Printing.listPrinters();
      if (printerName != null) {
        for (final p in printers) {
          if (p.name == printerName) {
            await Printing.directPrintPdf(
              printer: p,
              onLayout: (PdfPageFormat format) async => bytes,
            );
            return;
          }
        }
      }
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: fallbackName);
    } catch (_) {
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: fallbackName);
    }
  }

  /// Android: busca la impresora USB guardada, se conecta y envía ESC/POS.
  Future<void> _printEscPosAndroid(List<int> bytes) async {
    final savedId = await _settings.getUsbPrinterId();
    if (savedId == null || savedId.isEmpty) {
      throw PrinterNotConfiguredException(
          'No hay impresora USB configurada. Ve a Ajustes → Impresora térmica USB.');
    }

    final devices = await _usb.scanUsbPrinters();
    for (final d in devices) {
      if (ThermalUsbPrinter.idOf(d) == savedId) {
        final ok = await _usb.printOnce(d, bytes);
        if (!ok) {
          throw Exception('No se pudo enviar la impresión a la impresora USB.');
        }
        return;
      }
    }
    throw PrinterNotConfiguredException(
        'La impresora USB configurada no está conectada. Revisa el cable OTG.');
  }
}
