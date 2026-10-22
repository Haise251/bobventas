import 'database_helper.dart';
import '../constants/app_constants.dart';

/// Envoltura tipada sobre la tabla app_settings.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  Future<String?> _get(String key) => DatabaseHelper.instance.getSetting(key);
  Future<void> _set(String key, String value) =>
      DatabaseHelper.instance.setSetting(key, value);

  // --- Impresora del sistema (Windows, por nombre) ---
  Future<String?> getSystemPrinterName() =>
      _get(AppConstants.keyPrinterSystemName);
  Future<void> setSystemPrinterName(String name) =>
      _set(AppConstants.keyPrinterSystemName, name);

  // --- Impresora USB térmica (Android OTG, por uniqueId) ---
  Future<String?> getUsbPrinterId() => _get(AppConstants.keyPrinterUsbId);
  Future<void> setUsbPrinterId(String id) =>
      _set(AppConstants.keyPrinterUsbId, id);

  // --- Nombre del negocio (para el ticket) ---
  Future<String> getBusinessName() async =>
      await _get(AppConstants.keyBusinessName) ??
      AppConstants.defaultBusinessName;
  Future<void> setBusinessName(String name) =>
      _set(AppConstants.keyBusinessName, name);
}
