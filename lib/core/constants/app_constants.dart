import 'package:flutter/material.dart';

/// Constantes globales del negocio y del POS.
class AppConstants {
  AppConstants._();

  /// Nombre del negocio que aparece en los tickets (editable en Ajustes).
  static const String defaultBusinessName = 'BOB BURGUER';

  /// Nombre del archivo de base de datos (NO cambiar: conserva datos).
  static const String databaseName = 'pos_karen.db';

  /// Áreas de preparación.
  static const String areaCocina = 'COCINA';
  static const String areaSalchipapas = 'SALCHIPAPAS';
  static const String areaBebidas = 'BEBIDAS';

  /// Tipos de servicio.
  static const String comerAqui = 'COMER_AQUI';
  static const String paraLlevar = 'PARA_LLEVAR';
  static const String mixto = 'MIXTO';

  /// Salsas disponibles para personalización.
  static const List<String> availableSauces = [
    'Ketchup',
    'Mayonesa',
    'Salsa de tocineta',
    'Salsa de maíz',
    'Salsa de queso',
    'Mostaza',
  ];

  /// Claves de app_settings.
  static const String keyPrinterSystemName = 'printer_system_name';
  static const String keyPrinterUsbId = 'printer_usb_id';
  static const String keyBusinessName = 'business_name';

  /// Claves de los ítems del carrito (mapas).
  static const String kName = 'name';
  static const String kPrice = 'price';
  static const String kBasePrice = 'basePrice';
  static const String kQuantity = 'quantity';
  static const String kNotes = 'notes';
  static const String kIsCombo = 'isCombo';
  static const String kServiceType = 'serviceType';
  static const String kExtras = 'extras';
  static const String kArea = 'area';
}

/// Utilidad para construir ítems del carrito con el mismo formato interno
/// que usaba la versión original (mapas), centralizado en un solo lugar.
class CartItemFactory {
  CartItemFactory._();

  static Map<String, dynamic> fromProduct(
    Map<String, dynamic> product,
    String notes, {
    List<Map<String, dynamic>> extras = const [],
    double extraTotal = 0,
  }) {
    final isCombo = ((product['combo_quantity'] as num?) ?? 1) > 1;
    final basePrice = (product['price'] as num).toDouble();
    return {
      AppConstants.kName: product['name'],
      AppConstants.kPrice: basePrice + extraTotal,
      AppConstants.kBasePrice: basePrice,
      AppConstants.kQuantity: 1,
      AppConstants.kNotes: notes,
      AppConstants.kIsCombo: isCombo,
      AppConstants.kServiceType: AppConstants.comerAqui,
      AppConstants.kExtras: extras,
      AppConstants.kArea: product['area'] ?? AppConstants.areaCocina,
    };
  }

  static Map<String, dynamic> simple({
    required String name,
    required double price,
    required bool isCombo,
    required String serviceType,
    String notes = '',
    String area = AppConstants.areaCocina,
  }) {
    return {
      AppConstants.kName: name,
      AppConstants.kPrice: price,
      AppConstants.kBasePrice: price,
      AppConstants.kQuantity: 1,
      AppConstants.kNotes: notes,
      AppConstants.kIsCombo: isCombo,
      AppConstants.kServiceType: serviceType,
      AppConstants.kExtras: <Map<String, dynamic>>[],
      AppConstants.kArea: area,
    };
  }
}

/// Construye la nota "SIN: ... | CON: ..." a partir de las selecciones.
String buildNotesFromSelection({
  required Map<String, bool> removedIngredients,
  required Map<String, bool> addedSauces,
}) {
  final removed = <String>[];
  removedIngredients.forEach((k, v) {
    if (v == false) removed.add(k);
  });
  final added = <String>[];
  addedSauces.forEach((k, v) {
    if (v == true) added.add(k);
  });
  final parts = <String>[];
  if (removed.isNotEmpty) parts.add('SIN: ${removed.join(',')}');
  if (added.isNotEmpty) parts.add('CON: ${added.join(',')}');
  return parts.join(' | ');
}
