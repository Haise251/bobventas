import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../ajustes/settings_screen.dart';
import '../pedidos/sales_history_dialog.dart';
import '../reportes/daily_report_dialog.dart';
import 'widgets/cart_panel.dart';
import 'widgets/catalog_dialogs.dart';
import 'widgets/catalog_panel.dart';
import 'widgets/checkout_dialog.dart';
import 'widgets/customization_dialogs.dart';

/// Pantalla principal del POS: catálogo + carrito + atajos de teclado.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.title});

  final String title;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _extras = [];
  Map<String, dynamic>? _selectedCategory;
  late FocusNode _keyboardFocus;

  final List<Map<String, dynamic>> _items = [];

  // Controlador para el nombre personalizado / nota de salchipapa.
  final TextEditingController _customTicketNameController =
      TextEditingController();

  // Controladores del catálogo.
  final _categoryNameController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productIngredientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyboardFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocus.requestFocus();
    });
    _initApp();
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _categoryNameController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productIngredientsController.dispose();
    _customTicketNameController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    await DatabaseHelper.instance.clearPreviousDaySales();
    await _loadData();
    await _loadExtras();
  }

  Future<void> _loadExtras() async {
    final data = await DatabaseHelper.instance.getExtras();
    if (mounted) {
      setState(() => _extras = data);
    }
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.loadAllData();
    if (!mounted) return;
    setState(() {
      _categories = data;
      if (_selectedCategory != null) {
        final id = _selectedCategory!['id'];
        Map<String, dynamic>? match;
        for (final c in _categories) {
          if (c['id'] == id) {
            match = c;
            break;
          }
        }
        _selectedCategory = match;
      }
    });
  }

  // ===========================================================================
  // TOTALES
  // ===========================================================================

  double get _total => _items.fold(
      0.0, (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)));

  ({double bs, double usd}) get _totalsByCurrency =>
      Formatters.splitTotals(_items);

  List<Map<String, dynamic>> _itemsOfTypeFrom(
          List<Map<String, dynamic>> items, String type) =>
      items.where((i) => i['serviceType'] == type).toList();

  // ===========================================================================
  // CATÁLOGO: CRUD
  // ===========================================================================

  void _addCategory(String name) async {
    await DatabaseHelper.instance.addCategory(name);
    await _loadData();
    _categoryNameController.clear();
  }

  void _addProduct(String name, double price, {String ingredients = ''}) async {
    if (_selectedCategory != null) {
      final catId = _selectedCategory!['id'];
      await DatabaseHelper.instance.addProduct(
        catId,
        name,
        price,
        ingredients: ingredients,
      );
      await _loadData();
    }
    _productNameController.clear();
    _productPriceController.clear();
    _productIngredientsController.clear();
  }

  void _showAddCategoryDialog() => showAddCategoryDialog(
        context,
        controller: _categoryNameController,
        onConfirm: _addCategory,
      );

  void _showAddProductDialog() => showAddProductDialog(
        context,
        nameController: _productNameController,
        priceController: _productPriceController,
        ingredientsController: _productIngredientsController,
        onConfirm: _addProduct,
      );

  void _confirmDeleteCategory(int id, String name) =>
      confirmDeleteCategory(context, id: id, name: name, onDeleted: _loadData);

  void _confirmDeleteProduct(int id, String name) =>
      confirmDeleteProduct(context, id: id, name: name, onDeleted: _loadData);

  void _showEditPriceDialog(int id, String name, double currentPrice) =>
      showEditPriceDialog(
        context,
        id: id,
        name: name,
        currentPrice: currentPrice,
        onUpdated: _loadData,
      );

  // ===========================================================================
  // CARRITO
  // ===========================================================================

  void _addToCart(
    Map<String, dynamic> product,
    String notes, {
    List<Map<String, dynamic>> extras = const [],
    double extraTotal = 0,
  }) {
    setState(() {
      _items.add(CartItemFactory.fromProduct(
        product,
        notes,
        extras: extras,
        extraTotal: extraTotal,
      ));
    });
  }

  void _onCartQtyChanged(int index, int delta) {
    setState(() {
      final item = _items[index];
      final qty = (item['quantity'] as num).toInt();
      final next = qty + delta;
      if (next >= 1) item['quantity'] = next;
    });
  }

  void _onToggleServiceType(int index) {
    setState(() {
      final item = _items[index];
      item['serviceType'] = item['serviceType'] == AppConstants.comerAqui
          ? AppConstants.paraLlevar
          : AppConstants.comerAqui;
    });
  }

  void _onRemoveCartItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _onClearCart() {
    setState(() => _items.clear());
  }

  // ===========================================================================
  // DIÁLOGOS DE PERSONALIZACIÓN Y CHECKOUT
  // ===========================================================================

  void _showCustomizationDialog(Map<String, dynamic> product) {
    final comboQty = ((product['combo_quantity'] as num?) ?? 1).toInt();
    final allIng = (product['ingredients'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (comboQty <= 1) {
      showSingleCustomization(
        context,
        product,
        allIng,
        categoryName: _selectedCategory?['name'] as String?,
        onAdd: (notes) => _addToCart(product, notes),
      );
    } else {
      showComboCustomization(
        context,
        product,
        allIng,
        comboQty,
        onAdd: (notes) => _addToCart(product, notes),
      );
    }
  }

  void _showExtrasMenu() {
    showExtrasMenu(context, extras: _extras, items: _items,
        onItemsChanged: () => setState(() {}));
  }

  void _showCheckout() {
    showCheckoutDialog(
      context,
      items: _items,
      customNameController: _customTicketNameController,
      total: _total,
      onFinished: () {
        setState(() => _items.clear());
        _keyboardFocus.requestFocus();
      },
    );
  }

  // ===========================================================================
  // REPORTES Y PEDIDOS
  // ===========================================================================

  void _showDailyReport() {
    showDailyReportDialog(context, onClearToday: () async {
      await DatabaseHelper.instance.clearTodaySales();
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _showSalesHistory() async {
    await showSalesHistoryDialog(context, onDataChanged: _loadData);
  }

  // ===========================================================================
  // AJUSTES
  // ===========================================================================

  Future<void> _openSettings() async {
    _keyboardFocus.unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) _keyboardFocus.requestFocus();
  }

  // ===========================================================================
  // ATAJOS DE TECLADO (Windows)
  // ===========================================================================

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    int? idx;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      idx = 0;
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      idx = 1;
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      idx = 2;
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      idx = 3;
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      idx = 4;
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      idx = 5;
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      idx = 6;
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      idx = 7;
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      idx = 8;
    }

    if (idx != null && mounted) {
      final bool isCategoryView = _selectedCategory == null;
      if (isCategoryView) {
        if (idx < _categories.length) {
          setState(() => _selectedCategory = _categories[idx!]);
        } else if (idx == _categories.length) {
          _showExtrasMenu();
        }
      } else {
        final products = (_selectedCategory!['products'] as List);
        if (idx < products.length) {
          _showCustomizationDialog(products[idx]);
        }
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_items.isNotEmpty) {
        _showCheckout();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.backspace) {
      if (_selectedCategory != null) {
        setState(() => _selectedCategory = null);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'img/logo.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.store, color: AppTheme.accentSoft),
            ),
            const SizedBox(width: 12),
            Text(widget.title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Ajustes (impresora, negocio, prueba)',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _showSalesHistory,
            tooltip: 'Consultar Ventas del Día',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _showDailyReport,
            tooltip: 'Ver Ventas del Día',
          ),
          IconButton(
            icon: const Icon(Icons.extension),
            onPressed: _showExtrasMenu,
            tooltip: 'Extras',
          ),
        ],
      ),
      body: Focus(
        focusNode: _keyboardFocus,
        onKeyEvent: _onKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: CatalogPanel(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (c) =>
                      setState(() => _selectedCategory = c),
                  onBackToCategories: () =>
                      setState(() => _selectedCategory = null),
                  onProductTap: _showCustomizationDialog,
                  onAddCategory: _showAddCategoryDialog,
                  onAddProduct: _showAddProductDialog,
                  onDeleteCategory: _confirmDeleteCategory,
                  onDeleteProduct: _confirmDeleteProduct,
                  onEditPrice: _showEditPriceDialog,
                  onExtras: _showExtrasMenu,
                ),
              ),
              const VerticalDivider(width: 32, color: Colors.transparent),
              Expanded(
                flex: 2,
                child: CartPanel(
                  items: _items,
                  total: _total,
                  totals: _totalsByCurrency,
                  onQtyChanged: _onCartQtyChanged,
                  onToggleService: _onToggleServiceType,
                  onRemove: _onRemoveCartItem,
                  onClear: _onClearCart,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCheckout,
              label: const Text('Generar Ticket'),
              icon: const Icon(Icons.receipt_long),
            ),
    );
  }
}
