import 'dart:async';

import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
// El paquete NO re-exporta el modelo desde su librería principal:
// Printer y ConnectionType viven en utils/printer.dart.
import 'package:flutter_thermal_printer/utils/printer.dart';

/// Envoltura sobre `flutter_thermal_printer` para impresoras térmicas USB
/// (Android vía OTG; también funciona en Windows/macOS si se requiere).
///
/// Flujo:
///   1. [startScan]  — descubre impresoras USB (convierte el stream en lista).
///   2. [connect]    — solicita permiso USB y abre el canal.
///   3. [printBytes] — envía los comandos ESC/POS.
///   4. [disconnect] — cierra el canal tras imprimir.
class ThermalUsbPrinter {
  ThermalUsbPrinter._();
  static final ThermalUsbPrinter instance = ThermalUsbPrinter._();

  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;
  StreamSubscription? _scanSub;

  final List<Printer> _devices = [];
  Printer? _connected;

  /// Últimos dispositivos USB detectados.
  List<Printer> get devices => List.unmodifiable(_devices);

  /// Escanea impresoras USB disponibles y devuelve la lista al terminar.
  Future<List<Printer>> scanUsbPrinters(
      {Duration wait = const Duration(seconds: 3)}) async {
    _devices.clear();
    final completer = Completer<void>();

    await _scanSub?.cancel();
    _scanSub = _plugin.devicesStream.listen((List<Printer> printers) {
      _devices
        ..clear()
        ..addAll(printers.where((p) =>
            p.connectionType == ConnectionType.USB ||
            p.connectionType == null));
      if (!completer.isCompleted) completer.complete();
    });

    try {
      await _plugin.getPrinters(
        connectionTypes: [ConnectionType.USB],
        refreshDuration: wait,
      );
      // Espera el primer lote o el timeout, lo que ocurra primero.
      await completer.future.timeout(wait, onTimeout: () {});
    } catch (_) {
      // Si el escaneo falla devolvemos lo acumulado (posiblemente vacío).
    }
    await _scanSub?.cancel();
    _scanSub = null;
    return devices;
  }

  /// Identificador estable del dispositivo para guardarlo en ajustes.
  static String idOf(Printer p) {
    // uniqueId es un getter calculado (no nulo): vendorId + '_' + address.
    final uid = p.uniqueId;
    if (uid.isNotEmpty) return uid;
    return '${p.vendorId ?? ''}:${p.productId ?? ''}:${p.name ?? ''}';
  }

  /// Conecta una impresora USB (pide permiso al usuario si hace falta).
  Future<bool> connect(Printer printer) async {
    try {
      final ok = await _plugin.connect(printer);
      _connected = ok ? printer : null;
      return ok;
    } catch (_) {
      _connected = null;
      return false;
    }
  }

  /// Indica si el dispositivo se reporta como conectado.
  Future<bool> isConnected(Printer printer) async {
    try {
      return printer.isConnected == true ||
          _connected != null && idOf(_connected!) == idOf(printer);
    } catch (_) {
      return false;
    }
  }

  /// Envía bytes ESC/POS a la impresora conectada.
  Future<bool> printBytes(Printer printer, List<int> bytes) async {
    try {
      await _plugin.printData(printer, bytes, longData: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Desconecta la impresora.
  Future<void> disconnect(Printer printer) async {
    try {
      await _plugin.disconnect(printer);
    } catch (_) {}
    if (_connected != null && idOf(_connected!) == idOf(printer)) {
      _connected = null;
    }
  }

  /// Detiene cualquier escaneo activo.
  Future<void> stopScan() async {
    try {
      await _plugin.stopScan();
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /// Conveniencia: conecta (aquí Android muestra el diálogo de permiso USB
  /// la primera vez), imprime y desconecta.
  Future<bool> printOnce(Printer printer, List<int> bytes) async {
    // IMPORTANTE: sin connect() el plugin no tiene canal abierto y
    // printData falla en silencio. connect() también dispara el permiso USB.
    final connected = await connect(printer);
    if (!connected) return false;
    try {
      final ok = await printBytes(printer, bytes);
      if (ok) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return ok;
    } finally {
      await disconnect(printer);
    }
  }
}

/// Alias para el tipo de impresora del plugin (evita importar el paquete
/// en toda la app).
typedef UsbPrinterDevice = Printer;
