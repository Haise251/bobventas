import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/print/print_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de ajustes:
///  - Windows: seleccionar impresora del sistema (driver PDF 58mm) + prueba.
///  - Android: escanear y seleccionar impresora térmica USB (OTG) + prueba.
///  - Nombre del negocio usado en el ticket.
///  - Información de la plataforma.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get _isWindows => Platform.isWindows;
  bool get _isAndroid => Platform.isAndroid;

  List<AppPrinterInfo> _printers = [];
  String? _selectedId;
  bool _loadingPrinters = false;

  final TextEditingController _businessNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPrinters();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService.instance;
    final businessName = await settings.getBusinessName();
    _selectedId = _isWindows
        ? await settings.getSystemPrinterName()
        : await settings.getUsbPrinterId();
    if (mounted) {
      setState(() {
        _businessNameController.text = businessName;
      });
    }
  }

  Future<void> _loadPrinters() async {
    setState(() => _loadingPrinters = true);
    try {
      final printers = _isWindows
          ? await PrintService.instance.listSystemPrinters()
          : await PrintService.instance.listUsbPrinters();
      if (mounted) setState(() => _printers = printers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error buscando impresoras: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingPrinters = false);
    }
  }

  Future<void> _selectPrinter(AppPrinterInfo printer) async {
    if (_isWindows) {
      await PrintService.instance.selectSystemPrinter(printer.id);
    } else {
      await PrintService.instance.selectUsbPrinter(printer.id);
    }
    setState(() => _selectedId = printer.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Impresora seleccionada: ${printer.name}'),
      ));
    }
  }

  Future<void> _testPrint() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PrintService.instance.printTest();
      messenger.showSnackBar(const SnackBar(
        content: Text('Prueba enviada a la impresora.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('No se pudo imprimir la prueba: $e'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _saveBusinessName() async {
    final name = _businessNameController.text.trim();
    if (name.isEmpty) return;
    await SettingsService.instance.setBusinessName(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre del negocio actualizado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(Icons.print, 'Impresora'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isWindows
                      ? 'Impresoras del sistema (PDF 58mm vía driver):'
                      : 'Impresoras térmicas USB (conecta la impresora con tu cable OTG):',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (_loadingPrinters)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  )
                else if (_printers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _isWindows
                          ? 'No se encontraron impresoras instaladas.\n'
                              'Instala el driver de tu impresora 58mm y vuelve a intentar.'
                          : 'No se encontró ninguna impresora USB.\n'
                              'Conecta la impresora con el cable OTG y toca "Buscar de nuevo".\n'
                              'Si Android pide permiso para usar el dispositivo USB, acéptalo.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                else
                  ..._printers.map((p) {
                    final selected = _selectedId == p.id;
                    return ListTile(
                      leading: Icon(
                        selected ? Icons.check_circle : Icons.print,
                        color: selected ? AppTheme.accent : Colors.white54,
                      ),
                      title: Text(p.name),
                      tileColor: selected
                          ? AppTheme.accent.withOpacity(0.1)
                          : null,
                      onTap: () => _selectPrinter(p),
                    );
                  }),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadPrinters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Buscar de nuevo'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _testPrint,
                      icon: const Icon(Icons.receipt),
                      label: const Text('Probar impresora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(Icons.store, 'Negocio'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre que aparece arriba del ticket:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'BOB BURGUER',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveBusinessName,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar nombre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(Icons.info, 'Información'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine('Plataforma',
                    _isWindows ? 'Windows (PDF por driver)' : 'Android (USB OTG ESC/POS)'),
                _infoLine('Base de datos', 'pos_karen.db (v10)'),
                _infoLine('Formato papel', 'Térmico 58 mm'),
                _infoLine('Monedas', 'Bs. productos / \$ combos'),
                if (_isAndroid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Consejo: si la impresora no aparece, prueba otro cable OTG o revisa que la impresora esté encendida. Algunos Android muestran un aviso de permiso USB la primera vez.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
