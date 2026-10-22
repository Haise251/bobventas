import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Diálogo para editar los ítems de un pedido ya guardado:
/// agregar productos del catálogo, cambiar notas y cantidades.
class EditableSaleDialog extends StatefulWidget {
  final int ticketNumber;
  final List<Map<String, dynamic>> items;
  final String serviceType;

  const EditableSaleDialog({
    super.key,
    required this.ticketNumber,
    required this.items,
    required this.serviceType,
  });

  @override
  State<EditableSaleDialog> createState() => _EditableSaleDialogState();
}

class _EditableSaleDialogState extends State<EditableSaleDialog> {
  late final List<Map<String, dynamic>> _editableItems;
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _editableItems = List<Map<String, dynamic>>.from(widget.items);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final data = await DatabaseHelper.instance.loadAllData();
    if (mounted) {
      setState(() => _categories = data);
    }
  }

  double get _total => _editableItems.fold(
      0.0, (sum, i) => sum + ((i['price'] as num) * (i['quantity'] as num)));

  List<Map<String, dynamic>> _allProducts() {
    final result = <Map<String, dynamic>>[];
    for (final c in _categories) {
      result.addAll((c['products'] as List).cast<Map<String, dynamic>>());
    }
    return result;
  }

  void _addProductToEdit(Map<String, dynamic> product) {
    final isCombo = ((product['combo_quantity'] as num?) ?? 1) > 1;
    setState(() {
      _editableItems.add({
        'name': product['name'],
        'price': (product['price'] as num).toDouble(),
        'quantity': 1,
        'notes': '',
        'isCombo': isCombo,
        'serviceType': widget.serviceType == AppConstants.paraLlevar
            ? AppConstants.paraLlevar
            : AppConstants.comerAqui,
      });
    });
  }

  void _editItemNotes(int index) {
    final item = _editableItems[index];
    final notesController = TextEditingController(text: item['notes'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar notas/ingredientes'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej: SIN: Lechuga, tomate',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['notes'] = notesController.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        width: 850,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    'Editar Pedido #${widget.ticketNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accent,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(Formatters.serviceTypeLabel(widget.serviceType)),
                    backgroundColor: AppTheme.accent,
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.accent),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: ChoiceChip(
                                  label: const Text('Todos'),
                                  selected: _selectedCategory == null,
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = null),
                                  selectedColor: AppTheme.accent,
                                ),
                              ),
                              for (final c in _categories)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(c['name']),
                                    selected:
                                        _selectedCategory?['id'] == c['id'],
                                    onSelected: (_) =>
                                        setState(() => _selectedCategory = c),
                                    selectedColor: AppTheme.accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: _selectedCategory == null
                                ? _categories.fold<int>(
                                    0,
                                    (s, c) =>
                                        s + (c['products'] as List).length)
                                : (_selectedCategory!['products'] as List)
                                    .length,
                            itemBuilder: (context, index) {
                              final dynamic product =
                                  _selectedCategory == null
                                      ? _allProducts()[index]
                                      : _selectedCategory!['products'][index];
                              return InkWell(
                                onTap: () => _addProductToEdit(product),
                                borderRadius: BorderRadius.circular(10),
                                child: Card(
                                  color: AppTheme.cardDark,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product['name'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '${((product['price'] as num)).toStringAsFixed(2)} ${Formatters.currencyForProduct(product)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.white24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Productos del pedido',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _editableItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Sin productos. Toca un producto del catálogo para agregarlo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _editableItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _editableItems[index];
                                    final currency = Formatters.currencyFor(
                                        isCombo: item['isCombo'] == true);
                                    return Card(
                                      color: AppTheme.cardDark,
                                      child: ListTile(
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8),
                                        title: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => setState(() {
                                                item['serviceType'] =
                                                    item['serviceType'] ==
                                                            AppConstants
                                                                .comerAqui
                                                        ? AppConstants
                                                            .paraLlevar
                                                        : AppConstants
                                                            .comerAqui;
                                              }),
                                              child: Text(
                                                item['serviceType'] ==
                                                        AppConstants.comerAqui
                                                    ? 'Comer aquí'
                                                    : 'Para llevar',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.accent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (item['notes'] != null &&
                                                (item['notes'] as String)
                                                    .isNotEmpty)
                                              Text(
                                                item['notes'],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontStyle:
                                                      FontStyle.italic,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _editItemNotes(index),
                                              child: const Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_note,
                                                      color: Colors.amber,
                                                      size: 16),
                                                  SizedBox(width: 2),
                                                  Text('Nota',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.amber)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!(item['isCombo'] as bool))
                                              IconButton(
                                                icon: const Icon(
                                                    Icons
                                                        .remove_circle_outline,
                                                    color:
                                                        Colors.orangeAccent,
                                                    size: 20),
                                                onPressed: () =>
                                                    setState(() {
                                                  if ((item['quantity']
                                                          as int) >
                                                      1) {
                                                    item['quantity']--;
                                                  }
                                                }),
                                              ),
                                            if (!(item['isCombo'] as bool))
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    color:
                                                        Colors.greenAccent,
                                                    size: 20),
                                                onPressed: () =>
                                                    setState(() {
                                                  item['quantity']++;
                                                }),
                                              ),
                                            Text(
                                              '${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)} $currency',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accent,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                  size: 20),
                                              onPressed: () => setState(
                                                    () => _editableItems
                                                        .removeAt(index),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.accent),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL: ${_total.toStringAsFixed(2)} Bs.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppTheme.accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _editableItems),
                        child: const Text('Guardar Cambios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
