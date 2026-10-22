import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import '../../constants/app_constants.dart';
import '../settings_service.dart';
import '../../utils/formatters.dart';

/// Datos necesarios para construir un ticket.
class TicketData {
  final int ticketNumber;
  final String serviceType;
  final List<Map<String, dynamic>> items;
  final double totalBs;
  final double totalUsd;
  final String customerName;
  final Uint8List? logoBytes;

  const TicketData({
    required this.ticketNumber,
    required this.serviceType,
    required this.items,
    required this.totalBs,
    required this.totalUsd,
    this.customerName = '',
    this.logoBytes,
  });
}

/// Plantillas ESC/POS para impresora térmica de 58 mm.
///
/// Genera los bytes exactos que la impresora entiende (comandos ESC/POS):
/// el mismo contenido que la versión PDF original, optimizado para el ancho
/// de 58 mm (32 columnas por defecto).
class EscPosTemplates {
  EscPosTemplates._();

  static const String _dashed = '--------------------------------';

  static Future<Generator> _generator() async {
    final profile = await CapabilityProfile.load();
    return Generator(PaperSize.mm58, profile);
  }

  /// Línea de ítem "2x Nombre          9.00 Bs." respetando 32 columnas.
  static List<int> _itemLine(
      Generator g, Map<String, dynamic> item) {
    final qty = (item['quantity'] as num?) ?? 1;
    final name = '${item['name']}';
    final price = (item['price'] as num?) ?? 0;
    final isCombo = item['isCombo'] == true;
    final cur = Formatters.currencyFor(isCombo: isCombo);
    final left = '${qty}x $name';
    final right = '${price.toStringAsFixed(2)} $cur';

    final bytes = <int>[];
    bytes.addAll(g.text(_padLine(left, right),
        styles: const PosStyles()));
    final notes = (item['notes'] ?? '').toString().trim();
    if (notes.isNotEmpty) {
      bytes.addAll(g.text('  ($notes)',
          styles: const PosStyles()));
    }
    return bytes;
  }

  /// Alinea texto a la izquierda/derecha en el ancho de la línea.
  static String _padLine(String left, String right) {
    final total = 32;
    final leftFixed = left.length > total - right.length - 1
        ? left.substring(
            0, (total - right.length - 1).clamp(0, left.length).toInt())
        : left;
    final spaces = (total - leftFixed.length - right.length)
        .clamp(0, total)
        .toInt();
    final pad = ''.padLeft(spaces);
    return '$leftFixed$pad$right';
  }

  /// Envuelve un texto largo en líneas de máximo [width] caracteres.
  static List<String> _wrap(String text, int width) {
    final words = text.split(' ');
    final lines = <String>[];
    var current = '';
    for (final w in words) {
      if (current.isEmpty) {
        current = w;
      } else if ((current + ' ' + w).length <= width) {
        current = '$current $w';
      } else {
        lines.add(current);
        current = w;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  // =========================================================================
  // TICKET 1 — TICKET DE VENTA (cliente)
  // =========================================================================
  static Future<List<int>> saleTicket(TicketData data) async {
    final g = await _generator();
    final businessName = await SettingsService.instance.getBusinessName();
    final bytes = <int>[];

    bytes.addAll(g.reset());
    bytes.addAll(g.text(businessName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));

    if (data.customerName.isNotEmpty) {
      for (final line in _wrap('CLIENTE/NOTA: ${data.customerName}', 32)) {
        bytes.addAll(g.text(line,
            styles: const PosStyles(align: PosAlign.center, bold: true)));
      }
    }

    bytes.addAll(g.text('PEDIDO #${data.ticketNumber}',
        styles: const PosStyles(align: PosAlign.center)));

    // Tipo de servicio (igual lógica que el PDF original).
    final aqui = data.items
        .where((i) => i['serviceType'] == AppConstants.comerAqui)
        .toList();
    final llevar = data.items
        .where((i) => i['serviceType'] == AppConstants.paraLlevar)
        .toList();
    String serviceLine;
    if (aqui.isNotEmpty && llevar.isNotEmpty) {
      serviceLine =
          'Comer aquí: ${aqui.length} | Para llevar: ${llevar.length}';
    } else if (aqui.isNotEmpty) {
      serviceLine = 'Comer aquí';
    } else {
      serviceLine = 'Para llevar';
    }
    bytes.addAll(g.text(serviceLine,
        styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(g.text(_dashed));
    bytes.addAll(g.feed(1));

    if (aqui.isNotEmpty) {
      bytes.addAll(g.text('--- COMER AQUÍ ---', styles: const PosStyles(bold: true)));
      for (final item in aqui) {
        bytes.addAll(_itemLine(g, item));
      }
    }
    if (llevar.isNotEmpty) {
      bytes.addAll(g.text('--- PARA LLEVAR ---', styles: const PosStyles(bold: true)));
      for (final item in llevar) {
        bytes.addAll(_itemLine(g, item));
      }
    }

    bytes.addAll(g.text(_dashed));

    // Totales separados por moneda: Bs. para productos, $ para combos.
    if (data.totalBs > 0) {
      bytes.addAll(g.text(_padLine('TOTAL:', '${data.totalBs.toStringAsFixed(2)} Bs.'),
          styles: const PosStyles(bold: true, height: PosTextSize.size2)));
    }
    if (data.totalUsd > 0) {
      bytes.addAll(g.text(_padLine('TOTAL COMBOS:', '${data.totalUsd.toStringAsFixed(2)} \$'),
          styles: const PosStyles(bold: true, height: PosTextSize.size2)));
    }

    bytes.addAll(g.feed(1));
    bytes.addAll(g.text('¡Gracias por su compra!',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.feed(3));
    bytes.addAll(g.cut());
    return bytes;
  }

  // =========================================================================
  // TICKET 2 — TICKET DE ÁREA (COCINA / SALCHIPAPAS)
  // =========================================================================
  static Future<List<int>> areaTicket({
    required String areaTitle,
    required int ticketNumber,
    required List<Map<String, dynamic>> items,
    String customerName = '',
  }) async {
    final g = await _generator();
    final bytes = <int>[];

    final totalUnits =
        items.fold<int>(0, (sum, i) => sum + ((i['quantity'] as num?) ?? 0).toInt());

    bytes.addAll(g.reset());
    bytes.addAll(g.text(areaTitle,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));

    if (customerName.isNotEmpty) {
      for (final line in _wrap('NOTA/SALCHI: $customerName', 32)) {
        bytes.addAll(g.text(line,
            styles: const PosStyles(align: PosAlign.center, bold: true)));
      }
    }

    bytes.addAll(g.text('PEDIDO #$ticketNumber',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.text(_dashed));

    for (final item in items) {
      final qty = (item['quantity'] as num?) ?? 1;
      final name = '${item['name']}';
      final tag = item['serviceType'] == AppConstants.paraLlevar
          ? '[LLEVAR]'
          : '[AQUI]';
      bytes.addAll(g.text(_padLine('${qty}x $name', tag),
          styles: const PosStyles(bold: true)));
      final notes = (item['notes'] ?? '').toString().trim();
      if (notes.isNotEmpty) {
        for (final line in _wrap('($notes)', 30)) {
          bytes.addAll(g.text('  $line'));
        }
      }
    }

    bytes.addAll(g.text(_dashed));
    bytes.addAll(g.text('Unidades: $totalUnits',
        styles: const PosStyles(bold: true, height: PosTextSize.size2)));
    bytes.addAll(g.feed(2));
    bytes.addAll(g.cut());
    return bytes;
  }

  // =========================================================================
  // TICKET 3 — TICKET DE NÚMERO DE PEDIDO (para retirar/llamar)
  // =========================================================================
  static Future<List<int>> numberTicket(
    int ticketNumber, {
    List<Map<String, dynamic>> items = const [],
    Uint8List? logoBytes,
  }) async {
    final g = await _generator();
    final bytes = <int>[];

    final hasDrink =
        items.any((i) => (i['area'] ?? '') == AppConstants.areaBebidas);

    bytes.addAll(g.reset());
    bytes.addAll(g.text(_dashed));
    bytes.addAll(g.text('PEDIDO',
        styles: const PosStyles(align: PosAlign.center, bold: true)));

    // Logo rasterizado (si el asset existe).
    final raster = await _rasterizedLogo(logoBytes, g);
    if (raster != null) bytes.addAll(raster);

    bytes.addAll(g.text('#$ticketNumber',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size8,
          width: PosTextSize.size8,
        )));

    bytes.addAll(g.text(hasDrink ? '* CON BEBIDA *' : '* SIN BEBIDA *',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          reverse: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    bytes.addAll(g.text('¡Gracias por su compra!',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.feed(3));
    bytes.addAll(g.cut());
    return bytes;
  }

  // =========================================================================
  // TICKET DE PRUEBA (para el botón de Ajustes)
  // =========================================================================
  static Future<List<int>> testTicket() async {
    final g = await _generator();
    final bytes = <int>[];
    bytes.addAll(g.reset());
    bytes.addAll(g.text('PRUEBA DE IMPRESION',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    bytes.addAll(g.text(_dashed));
    bytes.addAll(g.text('Impresora conectada correctamente',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text('Formato: 58 mm - ESC/POS',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text('áéíóú ñ ÁÉÍÓÚ Ñ 1234567890',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text(_dashed));
    bytes.addAll(g.text('BOB BURGUER',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.feed(3));
    bytes.addAll(g.cut());
    return bytes;
  }

  /// Convierte el logo PNG en una imagen rasterizada ESC/POS de 200px.
  static Future<List<int>?> _rasterizedLogo(
      Uint8List? logoBytes, Generator g) async {
    try {
      Uint8List? bytes = logoBytes;
      bytes ??= await _loadLogoFromAssets();
      if (bytes == null) return null;

      final image = img.decodeImage(bytes);
      if (image == null) return null;
      final resized = img.copyResize(image, width: 200);
      return g.image(resized, align: PosAlign.center);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _loadLogoFromAssets() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows) {
      return null;
    }
    try {
      final data = await rootBundle.load('img/logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

