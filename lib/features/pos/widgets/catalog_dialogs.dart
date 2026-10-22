import 'package:flutter/material.dart';

import '../../../core/services/database_helper.dart';
import '../../../core/theme/app_theme.dart';

/// Diálogos de gestión del catálogo: categorías, productos y precios.
/// Funciones top-level para no acoplar la UI al estado del POS.

void showAddCategoryDialog(
  BuildContext context, {
  required TextEditingController controller,
  required ValueChanged<String> onConfirm,
}) {
  controller.clear();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nueva Categoría'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              onConfirm(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

void showAddProductDialog(
  BuildContext context, {
  required TextEditingController nameController,
  required TextEditingController priceController,
  required TextEditingController ingredientsController,
  required void Function(String name, double price, {String ingredients})
      onConfirm,
}) {
  nameController.clear();
  priceController.clear();
  ingredientsController.clear();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nuevo Producto'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Nombre del producto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(hintText: 'Precio (Bs. o \$ si es combo)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                hintText: 'Ingredientes (separados por coma)',
                helperText: 'Ej: Lechuga, tomate, queso',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(
                    priceController.text.replaceAll(',', '.')) ??
                0.0;
            if (nameController.text.isNotEmpty) {
              onConfirm(
                nameController.text,
                price,
                ingredients: ingredientsController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

void confirmDeleteCategory(
  BuildContext context, {
  required int id,
  required String name,
  required Future<void> Function() onDeleted,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar Categoría'),
      content: Text(
        '¿Estás seguro de eliminar "$name"? Se borrarán todos sus productos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            await DatabaseHelper.instance.deleteCategory(id);
            await onDeleted();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.orangeAccent),
          ),
        ),
      ],
    ),
  );
}

void confirmDeleteProduct(
  BuildContext context, {
  required int id,
  required String name,
  required Future<void> Function() onDeleted,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar Producto'),
      content: Text('¿Deseas eliminar "$name" del catálogo?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            await DatabaseHelper.instance.deleteProduct(id);
            await onDeleted();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

void showEditPriceDialog(
  BuildContext context, {
  required int id,
  required String name,
  required double currentPrice,
  required Future<void> Function() onUpdated,
}) {
  final editController =
      TextEditingController(text: currentPrice.toString());
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Editar Precio: $name'),
      content: TextField(
        controller: editController,
        decoration:
            const InputDecoration(labelText: 'Nuevo Precio (Bs. o \$)'),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newPrice = double.tryParse(
                    editController.text.replaceAll(',', '.')) ??
                currentPrice;
            await DatabaseHelper.instance.updateProductPrice(id, newPrice);
            await onUpdated();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Actualizar'),
        ),
      ],
    ),
  );
}

/// Diálogo compartido: confirmar limpiar ventas del día.
void confirmClearTodaySales(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Limpiar Ventas del Día'),
      content: const Text(
        '¿Estás seguro? Se eliminarán TODAS las ventas de hoy y el próximo '
        'pedido volverá a ser el #1.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent),
          onPressed: () async {
            await onConfirm();
          },
          child: const Text('Sí, limpiar'),
        ),
      ],
    ),
  );
}

/// SnackBar reutilizable con el color del tema.
SnackBar appSnackBar(String message, {Color? background}) {
  return SnackBar(
    content: Text(message),
    backgroundColor: background ?? AppTheme.accent,
  );
}
