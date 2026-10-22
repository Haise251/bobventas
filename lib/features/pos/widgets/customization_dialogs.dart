import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Opciones de proteína para hamburguesas (selector de pedidos).
/// - Hamburguesa Mixta: combinaciones dobles del negocio.
/// - Otras hamburguesas (excepto Chuleta y Bob Burguer): carne o pollo.
const List<String> kMixtaProteinOptions = [
  'Doble Pollo',
  'Doble Carne',
  'Pollo + Carne',
  'Carne + Pollo',
  'Chuleta + Pollo',
  'Carne + Chuleta',
];
const List<String> kBasicProteinOptions = ['Carne', 'Pollo'];

/// Diálogo de personalización para productos individuales:
/// elegir proteína (hamburguesas), desmarcar ingredientes y atajos de
/// teclado (Enter = agregar, Esc = cerrar).
void showSingleCustomization(
  BuildContext context,
  Map<String, dynamic> product,
  List<String> ingredients, {
  required void Function(String notes) onAdd,
  String? categoryName,
}) {
  final allIngredients = <String>[...ingredients, ...AppConstants.availableSauces];
  final selectedIngredients = <String, bool>{
    for (var i in allIngredients) i: true,
  };

  // Proteína: solo hamburguesas. La Mixta tiene sus propias combinaciones.
  final productName = (product['name'] as String? ?? '').toLowerCase();
  final catName = (categoryName ?? '').toLowerCase();
  List<String>? proteinOptions;
  if (productName.contains('mixta')) {
    proteinOptions = kMixtaProteinOptions;
  } else if (catName.contains('hamburgues') &&
      !productName.contains('chuleta') &&
      !productName.contains('bob')) {
    proteinOptions = kBasicProteinOptions;
  }
  String selectedProtein =
      proteinOptions != null ? proteinOptions.first : '';

  void commit() {
    final removed = <String>[];
    selectedIngredients.forEach((k, v) {
      if (v == false) removed.add(k);
    });
    final parts = <String>[];
    if (proteinOptions != null && selectedProtein.isNotEmpty) {
      parts.add(selectedProtein.toUpperCase());
    }
    if (removed.isNotEmpty) parts.add('SIN: ${removed.join(',')}');
    onAdd(parts.join(' | '));
    Navigator.of(context, rootNavigator: true).pop();
  }

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                commit();
              } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: AlertDialog(
            title: Text('Personalizar ${product['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proteinOptions != null) ...[
                    const Text(
                      '¿DE QUÉ ES?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: proteinOptions.map((p) {
                        final bool isSel = selectedProtein == p;
                        return ChoiceChip(
                          label: Text(p),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.black : Colors.white70,
                          ),
                          selected: isSel,
                          selectedColor: AppTheme.accent,
                          backgroundColor: Colors.white12,
                          onSelected: (_) =>
                              setDialogState(() => selectedProtein = p),
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                  ],
                  const Text(
                    'INGREDIENTES Y SALSAS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.accent,
                    ),
                  ),
                  const Text(
                    'Desmarca lo que NO quieras que lleve',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  ...allIngredients.map((ing) {
                    return CheckboxListTile(
                      dense: true,
                      title: Text(ing, style: const TextStyle(fontSize: 13)),
                      value: selectedIngredients[ing],
                      activeColor: AppTheme.accent,
                      onChanged: (v) {
                        setDialogState(() {
                          selectedIngredients[ing] = v ?? true;
                        });
                      },
                    );
                  }),
                  const Divider(color: Colors.white24, height: 24),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: commit,
                child: const Text('Agregar'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Diálogo para desglosar combos en grupos con ingredientes y salsas.
void showComboCustomization(
  BuildContext context,
  Map<String, dynamic> product,
  List<String> ingredients,
  int totalQty, {
  required void Function(String notes) onAdd,
}) {
  final groups = <Map<String, dynamic>>[
    {'qty': totalQty, 'removed': <String>[], 'addedSauces': <String>[]},
  ];

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        int currentSum = groups.fold(0, (sum, g) => sum + (g['qty'] as int));

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: AlertDialog(
            title: Text('Desglosar Combo ($totalQty und.)'),
            content: SizedBox(
              width: 500,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...groups.asMap().entries.map((entry) {
                    var group = entry.value;
                    return Card(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(' Cant: '),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: (group['qty'] as int) > 1
                                    ? () => setDialogState(() {
                                          group['qty'] =
                                              (group['qty'] as int) - 1;
                                        })
                                    : null,
                              ),
                              Text(
                                '${group['qty']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: currentSum < totalQty
                                    ? () => setDialogState(() {
                                          group['qty'] =
                                              (group['qty'] as int) + 1;
                                        })
                                    : null,
                              ),
                              if (groups.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => setDialogState(() {
                                    groups.removeAt(entry.key);
                                  }),
                                ),
                            ],
                          ),
                          if (ingredients.isNotEmpty) ...[
                            const Text(
                              'INGREDIENTES:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Wrap(
                              children: ingredients.map((ing) {
                                return FilterChip(
                                  label: Text(ing,
                                      style: const TextStyle(fontSize: 10)),
                                  selected:
                                      !(group['removed'] as List).contains(ing),
                                  onSelected: (v) => setDialogState(() {
                                    if (v) {
                                      (group['removed'] as List).remove(ing);
                                    } else {
                                      (group['removed'] as List).add(ing);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 4),
                          const Text(
                            'SALSAS:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Wrap(
                            children: AppConstants.availableSauces.map((sauce) {
                              return FilterChip(
                                label: Text(sauce,
                                    style: const TextStyle(fontSize: 10)),
                                selected: (group['addedSauces'] as List)
                                    .contains(sauce),
                                onSelected: (v) => setDialogState(() {
                                  if (v) {
                                    (group['addedSauces'] as List).add(sauce);
                                  } else {
                                    (group['addedSauces'] as List)
                                        .remove(sauce);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (currentSum < totalQty)
                    TextButton.icon(
                      onPressed: () => setDialogState(() {
                        groups.add({
                          'qty': 1,
                          'removed': <String>[],
                          'addedSauces': <String>[],
                        });
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar grupo'),
                    ),
                  const Divider(color: Colors.white24, height: 24),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: currentSum == totalQty
                    ? () {
                        final baseNote = groups.map((g) {
                          var s = '${g['qty']}und';
                          final removed = g['removed'] as List;
                          if (removed.isNotEmpty) {
                            s += ' (SIN: ${removed.join(',')})';
                          }
                          final added = g['addedSauces'] as List;
                          if (added.isNotEmpty) {
                            s += ' (CON: ${added.join(',')})';
                          }
                          return s;
                        }).join(' | ');

                        onAdd(baseNote);
                        Navigator.pop(dialogContext);
                      }
                    : null,
                child: const Text('Agregar'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Menú de extras: adjuntar al último producto o agregarlos como ítems.
void showExtrasMenu(
  BuildContext context, {
  required List<Map<String, dynamic>> extras,
  required List<Map<String, dynamic>> items,
  required VoidCallback onItemsChanged,
}) {
  final selected = <String, bool>{
    for (var e in extras) e['name'] as String: false,
  };
  final qtys = <String, int>{for (var e in extras) e['name'] as String: 1};
  final priceControllers = <String, TextEditingController>{
    for (var e in extras)
      e['name'] as String: TextEditingController(
        text: (e['price'] as num).toStringAsFixed(2),
      ),
  };
  bool attachToLast = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: AlertDialog(
            title: const Text('Extras disponibles'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (items.isNotEmpty)
                      CheckboxListTile(
                        title: const Text(
                          'Adjuntar extras al último producto en carrito',
                        ),
                        value: attachToLast,
                        onChanged: (v) =>
                            setDialogState(() => attachToLast = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    const SizedBox(height: 8),
                    ...extras.map((e) {
                      final name = e['name'] as String;
                      return Row(
                        children: [
                          Checkbox(
                            value: selected[name],
                            onChanged: (v) => setDialogState(() {
                              selected[name] = v ?? false;
                            }),
                          ),
                          Expanded(child: Text(name)),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: priceControllers[name],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => setDialogState(() {
                                  if ((qtys[name] ?? 1) > 1) {
                                    qtys[name] = qtys[name]! - 1;
                                  }
                                }),
                              ),
                              Text('${qtys[name]}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setDialogState(() {
                                  qtys[name] = (qtys[name] ?? 1) + 1;
                                }),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final extrasToAttach = <Map<String, dynamic>>[];
                  double extrasSum = 0;
                  for (var e in extras) {
                    final name = e['name'] as String;
                    if (selected[name] == true) {
                      final raw = priceControllers[name]!.text;
                      final price = double.tryParse(
                              raw.replaceAll(',', '.')) ??
                          (e['price'] as num).toDouble();
                      final qty = qtys[name] ?? 1;
                      extrasToAttach.add({
                        'name': name,
                        'price': price,
                        'quantity': qty,
                      });
                      extrasSum += price * qty;
                    }
                  }

                  if (attachToLast && items.isNotEmpty && extrasToAttach.isNotEmpty) {
                    final last = items.last;
                    last['extras'] ??= <Map<String, dynamic>>[];
                    (last['extras'] as List).addAll(extrasToAttach);
                    last['price'] =
                        (last['price'] as num).toDouble() + extrasSum;

                    final extrasNote = extrasToAttach
                        .map((ex) => (ex['quantity'] as int) > 1
                            ? '${ex['name']} x${ex['quantity']} (+${((ex['price'] as num) * (ex['quantity'] as int)).toStringAsFixed(2)})'
                            : '${ex['name']} (+${(ex['price'] as num).toStringAsFixed(2)})')
                        .join(', ');
                    if (extrasNote.isNotEmpty) {
                      String currentNotes = (last['notes'] as String? ?? '');
                      if (currentNotes.isNotEmpty) {
                        last['notes'] = '$currentNotes | CON: $extrasNote';
                      } else {
                        last['notes'] = 'CON: $extrasNote';
                      }
                    }
                  } else if (extrasToAttach.isNotEmpty) {
                    final defaultServiceType = items.isNotEmpty
                        ? items.last['serviceType']
                        : AppConstants.comerAqui;

                    for (var ex in extrasToAttach) {
                      items.add({
                        'name': ex['name'],
                        'price': (ex['price'] as num).toDouble(),
                        'basePrice': (ex['price'] as num).toDouble(),
                        'quantity': ex['quantity'],
                        'notes': '',
                        'isCombo': false,
                        'serviceType': defaultServiceType,
                        'extras': <Map<String, dynamic>>[],
                        'area': AppConstants.areaCocina,
                      });
                    }
                  }

                  onItemsChanged();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Agregar seleccionados'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
