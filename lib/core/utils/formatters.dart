import '../constants/app_constants.dart';

/// Formateadores y etiquetas compartidas.
class Formatters {
  Formatters._();

  /// Etiqueta legible del tipo de servicio.
  static String serviceTypeLabel(String type) {
    switch (type) {
      case AppConstants.paraLlevar:
        return 'Para llevar';
      case AppConstants.mixto:
        return 'Mixto';
      default:
        return 'Comer aquí';
    }
  }

  /// Símbolo de moneda según el flag de combo:
  /// los combos se manejan SOLO en divisa ($), el resto en Bs.
  static String currencyFor({required bool isCombo}) => isCombo ? r'$' : 'Bs.';

  /// Símbolo de moneda según el producto (usa combo_quantity > 1).
  static String currencyForProduct(Map<String, dynamic> product) {
    final qty = ((product['combo_quantity'] as num?) ?? 1).toInt();
    return currencyFor(isCombo: qty > 1);
  }

  /// Formatea un monto con su moneda: "12.50 Bs." o "8.00 $".
  static String money(num amount, {required bool isCombo}) =>
      '${amount.toStringAsFixed(2)} ${currencyFor(isCombo: isCombo)}';

  /// Formatea un timestamp de la BD: "2026-10-22 14:30".
  static String timestamp(dynamic ts) {
    if (ts == null) return '';
    final str = ts.toString().replaceFirst('T', ' ');
    if (str.length >= 16) return str.substring(0, 16);
    return str;
  }

  /// Calcula totales separados por moneda a partir de ítems del carrito
  /// (o ítems de BD con las mismas claves price/quantity/isCombo).
  static ({double bs, double usd}) splitTotals(
      List<Map<String, dynamic>> items) {
    double bs = 0;
    double usd = 0;
    for (final item in items) {
      final price = (item['price'] as num?) ?? 0;
      final qty = (item['quantity'] as num?) ?? 0;
      final isCombo = item['isCombo'] == true;
      if (isCombo) {
        usd += price * qty;
      } else {
        bs += price * qty;
      }
    }
    return (bs: bs, usd: usd);
  }
}
