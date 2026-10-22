import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Panel izquierdo: cuadrícula de categorías o de productos,
/// con atajos numerados y acciones de editar/eliminar.
class CatalogPanel extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? selectedCategory;
  final ValueChanged<Map<String, dynamic>> onCategorySelected;
  final VoidCallback onBackToCategories;
  final ValueChanged<Map<String, dynamic>> onProductTap;
  final VoidCallback onAddCategory;
  final VoidCallback onAddProduct;
  final void Function(int id, String name) onDeleteCategory;
  final void Function(int id, String name) onDeleteProduct;
  final void Function(int id, String name, double price) onEditPrice;
  final VoidCallback onExtras;

  const CatalogPanel({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onBackToCategories,
    required this.onProductTap,
    required this.onAddCategory,
    required this.onAddProduct,
    required this.onDeleteCategory,
    required this.onDeleteProduct,
    required this.onEditPrice,
    required this.onExtras,
  });

  bool get _isCategoryView => selectedCategory == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (!_isCategoryView)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: AppTheme.accent,
                    onPressed: onBackToCategories,
                  ),
                Text(
                  _isCategoryView
                      ? 'Categorías Principales'
                      : 'Menú: ${selectedCategory!['name']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: AppTheme.accent,
                size: 30,
              ),
              onPressed: _isCategoryView ? onAddCategory : onAddProduct,
              tooltip: _isCategoryView
                  ? 'Agregar Categoría'
                  : 'Agregar Producto',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _grid()),
      ],
    );
  }

  Widget _grid() {
    final int itemCount = _isCategoryView
        ? categories.length + 1
        : (selectedCategory!['products'] as List).length;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_isCategoryView && index == categories.length) {
          return _extrasCard();
        }
        final dynamic item = _isCategoryView
            ? categories[index]
            : (selectedCategory!['products'] as List)[index];
        return _isCategoryView
            ? _categoryCard(item, index)
            : _productCard(item, index);
      },
    );
  }

  Widget _extrasCard() {
    return InkWell(
      onTap: onExtras,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: AppTheme.accentSoft.withOpacity(0.5),
            width: 2,
          ),
        ),
        color: AppTheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.extension, color: AppTheme.accentSoft, size: 40),
              SizedBox(height: 8),
              Text(
                'EXTRAS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> item, int index) {
    return _tileCard(
      item: item,
      isCategory: true,
      badge: index < 9 ? '${index + 1}' : null,
      onTap: () => onCategorySelected(item),
      topRightAction: IconButton(
        icon: const Icon(Icons.remove_circle_outline,
            size: 20, color: Colors.orangeAccent),
        onPressed: () => onDeleteCategory(item['id'], item['name']),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> item, int index) {
    final currency = Formatters.currencyForProduct(item);
    return _tileCard(
      item: item,
      isCategory: false,
      badge: index < 9 ? '${index + 1}' : null,
      onTap: () => onProductTap(item),
      subtitle: Text(
        '${((item['price'] as num)).toStringAsFixed(2)} $currency',
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      topRightAction: IconButton(
        icon: const Icon(Icons.remove_circle_outline,
            size: 20, color: Colors.orangeAccent),
        onPressed: () => onDeleteProduct(item['id'], item['name']),
      ),
      topLeftAction: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
        onPressed: () => onEditPrice(
            item['id'], item['name'], (item['price'] as num).toDouble()),
      ),
    );
  }

  Widget _tileCard({
    required Map<String, dynamic> item,
    required bool isCategory,
    String? badge,
    Widget? subtitle,
    required VoidCallback onTap,
    Widget? topRightAction,
    Widget? topLeftAction,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: isCategory ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: AppTheme.accent.withOpacity(0.5),
            width: 2,
          ),
        ),
        color: AppTheme.surface,
        child: Stack(
          children: [
            if (badge != null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isCategory ? AppTheme.accent : Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontWeight: isCategory ? FontWeight.w900 : FontWeight.bold,
                      fontSize: isCategory ? 16 : 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) subtitle,
                ],
              ),
            ),
            if (topRightAction != null)
              Positioned(top: 0, right: 0, child: topRightAction),
            if (topLeftAction != null)
              Positioned(top: 0, left: 0, child: topLeftAction),
          ],
        ),
      ),
    );
  }
}
