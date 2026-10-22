import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Datos semilla de la base de datos.
/// Separado de DatabaseHelper para mantener el código organizado.
class DbSeed {
  DbSeed._();

  static final List<Map<String, Object>> categories = [
    {'name': 'Perros Calientes', 'icon': Icons.hot_tub.codePoint},
    {'name': 'Hamburguesas', 'icon': Icons.lunch_dining.codePoint},
    {'name': 'Salchipapas', 'icon': Icons.fastfood.codePoint},
    {'name': 'Otros', 'icon': Icons.restaurant_menu.codePoint},
    {'name': 'Combos', 'icon': Icons.set_meal.codePoint},
    {'name': 'Bebidas', 'icon': Icons.local_drink.codePoint},
  ];

  /// Extras por defecto.
  static const List<Map<String, Object>> extras = [
    {'name': 'Queso extra', 'price': 2.00},
    {'name': 'Tocineta extra', 'price': 3.00},
    {'name': 'Huevo extra', 'price': 2.00},
    {'name': 'Aguacate extra', 'price': 2.50},
    {'name': 'Salchicha extra', 'price': 3.00},
    {'name': 'Carne extra', 'price': 5.00},
    {'name': 'Pollo extra', 'price': 4.00},
    {'name': 'Chuleta extra', 'price': 5.00},
    {'name': 'Chorizo extra', 'price': 3.00},
    {'name': 'Papa extra', 'price': 1.50},
    {'name': 'Maíz extra', 'price': 1.50},
    {'name': 'Queso amarillo extra', 'price': 2.00},
  ];

  /// Combos NUEVOS agregados en la versión 10 de la base de datos.
  /// Menú REAL tomado de bobventas.netlify.app (categoría Combos).
  /// IMPORTANTE: los combos se manejan SOLO en divisas ($).
  /// combo_quantity > 1 hace que la app los reconozca como combos ($).
  /// Los precios son editables desde la app (clic en el lápiz del producto).
  static final List<Map<String, Object>> newCombos = [
    {
      'name': 'Promo Hamburguesa Completo',
      'price': 10.00,
      'ingredients':
          '2 Hamburguesas + 1 combo perro + 1 ración de papa + 1 refresco de 1 litro.',
      'combo_quantity': 2,
      'icon': Icons.workspace_premium.codePoint,
    },
    {
      'name': 'Combo 4 Hamburguesas',
      'price': 10.00,
      'ingredients': '4 Hamburguesas + 1 ración de papa + 1 refresco de 1 litro.',
      'combo_quantity': 4,
      'icon': Icons.lunch_dining.codePoint,
    },
    {
      'name': 'Combo 4 Enrollados',
      'price': 10.00,
      'ingredients': '4 Enrollados + 1 ración de papa + 1 refresco de 1 litro.',
      'combo_quantity': 4,
      'icon': Icons.wrap_text.codePoint,
    },
  ];

  /// Productos NUEVOS (v10) que no existían en la base de datos original
  /// pero sí están en el menú real (bobventas.netlify.app).
  /// Se insertan solo si no existen (dedup por nombre).
  static final List<Map<String, Object>> newProducts = [
    {
      'category': 'Perros Calientes',
      'name': 'Choriperro',
      'price': 3500.00,
      'ingredients': 'Chorizo, papa, repollo, cebolla, salsas al gusto.',
      'icon': Icons.hot_tub.codePoint,
    },
    {
      'category': 'Otros',
      'name': 'Pepito',
      'price': 7000.00,
      'ingredients':
          'Pan especial de pepito, carne o pollo, huevo, tocineta, queso amarillo, papas fritas, repollo, tomate, cebolla y salsas al gusto.',
      'icon': Icons.dinner_dining.codePoint,
    },
  ];

  /// Productos iniciales por categoría (catálogo original completo).
  static Future<void> seedCatalog(Database db) async {
    for (final cat in categories) {
      final id = await db.insert('categories', {
        'name': cat['name'],
        'iconCode': cat['icon'],
      });

      switch (cat['name']) {
        // Precios del menú real (bobventas.netlify.app), en Bs.
        case 'Perros Calientes':
          await _insertProduct(db, id, 'Perro Sencillo', 1000.00,
              Icons.hot_tub.codePoint,
              'Salchicha polaca, papa, repollo, cebolla.', 1);
          await _insertProduct(db, id, 'Perro Especial', 1500.00,
              Icons.hot_tub.codePoint,
              'Salchicha polaca, papa, repollo, cebolla, maíz, queso amarillo.',
              1);
          await _insertProduct(db, id, 'Perro Super Especial', 2000.00,
              Icons.hot_tub.codePoint,
              'Salchicha polaca, papa, repollo, cebolla, maíz, queso amarillo, tocineta, aguacate.',
              1);
          await _insertProduct(db, id, 'Perro Parrilla', 3000.00,
              Icons.local_fire_department.codePoint,
              'Parrilla, papa, repollo, cebolla, maíz, queso amarillo, tocineta, aguacate.',
              1);
          await _insertProduct(db, id, 'Choriperro', 3500.00,
              Icons.hot_tub.codePoint,
              'Chorizo, papa, repollo, cebolla, salsas al gusto.', 1);
          await _insertProduct(db, id, 'Jumbo', 3000.00, Icons.star.codePoint,
              'Doble salchicha polaca, papa, repollo, cebolla, maíz, queso amarillo, huevo, tocineta, aguacate.',
              1);
          break;

        case 'Hamburguesas':
          await _insertProduct(db, id, 'Mini', 1500.00,
              Icons.lunch_dining.codePoint, 'Pollo, lechuga, tomate.', 1);
          await _insertProduct(db, id, 'Hamburguesa Sencilla', 3000.00,
              Icons.lunch_dining.codePoint,
              'Carne o pollo, repollo, cebolla, papas, tomate, lechuga.', 1);
          await _insertProduct(db, id, 'Hamburguesa Especial', 4000.00,
              Icons.lunch_dining.codePoint,
              'Carne o pollo, repollo, papa, cebolla, lechuga, tomate, huevo, queso amarillo, maíz, tocineta.',
              1);
          await _insertProduct(db, id, 'Hamburguesa Chuleta', 4500.00,
              Icons.set_meal.codePoint,
              'Chuleta, repollo, cebolla, papas, lechuga, tomate, tocineta, huevo, queso amarillo, maíz.',
              1);
          await _insertProduct(db, id, 'Hamburguesa Mixta', 5500.00,
              Icons.layers.codePoint,
              'Carne o pollo o chuleta, repollo, cebolla, papa, tomate, lechuga, huevo, queso amarillo, maíz, tocineta.',
              1);
          await _insertProduct(db, id, 'Bob Burguer', 8000.00,
              Icons.workspace_premium.codePoint,
              'Carne, pollo, chuleta, chorizo, repollo, cebolla, papa, lechuga, tomate, huevo, tocineta, queso amarillo.',
              1);
          break;

        case 'Salchipapas':
          await _insertProduct(db, id, 'Salchipapa Sencilla', 4000.00,
              Icons.fastfood.codePoint, 'Papas, salchicha, queso amarillo.', 1,
              area: AppConstants.areaSalchipapas);
          await _insertProduct(db, id, 'Salchiparrilla', 5000.00,
              Icons.local_fire_department.codePoint,
              'Papas, salchicha, parrilla, queso amarillo, tocineta.', 1,
              area: AppConstants.areaSalchipapas);
          break;

        case 'Otros':
          await _insertProduct(db, id, 'Enrollado Mixto', 4000.00,
              Icons.wrap_text.codePoint,
              'Carne, pollo, chorizos, tocineta, papas, lechuga, tomate, queso amarillo.',
              1);
          await _insertProduct(db, id, 'Pepito', 7000.00,
              Icons.dinner_dining.codePoint,
              'Pan especial de pepito, carne o pollo, huevo, tocineta, queso amarillo, papas fritas, repollo, tomate, cebolla y salsas al gusto.',
              1);
          break;

        case 'Combos':
          // Combos originales (en divisas).
          await _insertProduct(db, id, '6 Perros Especiales', 5.00,
              Icons.hot_tub.codePoint,
              'Salchicha polaca, papa, repollo, cebolla, maíz, queso amarillo.',
              6);
          await _insertProduct(db, id, '6 Mini Hamburguesas', 5.00,
              Icons.lunch_dining.codePoint, 'Pollo, lechuga, tomate.', 6);
          await _insertProduct(db, id, '2 Hamburguesas Especiales', 5.00,
              Icons.layers.codePoint,
              'Carne o pollo, repollo, papa, cebolla, lechuga, tomate, huevo, queso amarillo, maíz, tocineta.',
              2);
          await _insertProduct(db, id, '2 Enrollados', 5.00,
              Icons.wrap_text.codePoint,
              'Carne, pollo, chorizos, tocineta, papas, lechuga, tomate, queso.',
              2);
          await _insertProduct(db, id, '2 Jumbos', 5.00, Icons.star.codePoint,
              'Doble salchicha polaca, papa, repollo, cebolla, maíz, queso amarillo, huevo, tocineta, aguacate.',
              2);
          // Combos nuevos (v10, en divisas).
          for (final combo in newCombos) {
            await db.insert('products', {
              'category_id': id,
              'name': combo['name'],
              'price': combo['price'],
              'iconCode': combo['icon'],
              'ingredients': combo['ingredients'],
              'combo_quantity': combo['combo_quantity'],
              'area': AppConstants.areaCocina,
            });
          }
          break;

        case 'Bebidas':
          await _insertProduct(db, id, 'Coca-Cola 500ml', 1.50,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Coca-Cola 2L', 3.50,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Pepsi 500ml', 1.25,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Pepsi 2L', 3.00,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Agua Mineral 500ml', 1.00,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Malta', 1.50, Icons.local_drink.codePoint,
              '', 1,
              area: AppConstants.areaBebidas);
          await _insertProduct(db, id, 'Jugo Hit 1L', 2.50,
              Icons.local_drink.codePoint, '', 1,
              area: AppConstants.areaBebidas);
          break;
      }
    }
  }

  /// Inserta un producto individual.
  static Future<void> _insertProduct(
    Database db,
    int catId,
    String name,
    double price,
    int icon,
    String ingredients,
    int comboQuantity, {
    String area = AppConstants.areaCocina,
  }) async {
    await db.insert('products', {
      'category_id': catId,
      'name': name,
      'price': price,
      'iconCode': icon,
      'ingredients': ingredients,
      'combo_quantity': comboQuantity,
      'area': area,
    });
  }

  /// Siembra los extras evitando duplicados.
  static Future<void> seedExtras(Database db) async {
    for (final e in extras) {
      final count = await db.rawQuery(
        'SELECT COUNT(*) as c FROM extras WHERE name = ?',
        [e['name']],
      );
      final existing = (count.first['c'] as num?)?.toInt() ?? 0;
      if (existing == 0) {
        await db.insert('extras', {'name': e['name'], 'price': e['price']});
      }
    }
  }

  /// Inserta los combos y productos nuevos (v10) evitando duplicados por nombre.
  /// Menú real: bobventas.netlify.app.
  static Future<void> seedNewItems(Database db) async {
    // 1) Combos nuevos (Promo Hamburguesa Completo, Combo 4 Hamburguesas,
    //    Combo 4 Enrollados) en divisas.
    final catRes = await db.rawQuery(
      "SELECT id FROM categories WHERE lower(name) = 'combos' LIMIT 1",
    );
    int catId;
    if (catRes.isEmpty) {
      catId = await db.insert('categories', {
        'name': 'Combos',
        'iconCode': Icons.set_meal.codePoint,
      });
    } else {
      catId = (catRes.first['id'] as num).toInt();
    }

    for (final combo in newCombos) {
      final existing = await db.rawQuery(
        'SELECT COUNT(*) as c FROM products WHERE lower(name) = ?',
        [(combo['name'] as String).toLowerCase()],
      );
      final count = (existing.first['c'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        await db.insert('products', {
          'category_id': catId,
          'name': combo['name'],
          'price': combo['price'],
          'iconCode': combo['icon'],
          'ingredients': combo['ingredients'],
          'combo_quantity': combo['combo_quantity'],
          'area': AppConstants.areaCocina,
        });
      }
    }

    // 2) Productos nuevos del menú real (Choriperro, Pepito).
    for (final p in newProducts) {
      final catName = p['category'] as String;
      final pRes = await db.rawQuery(
        'SELECT id FROM categories WHERE lower(name) = ? LIMIT 1',
        [catName.toLowerCase()],
      );
      int prodCatId;
      if (pRes.isEmpty) {
        prodCatId = await db.insert('categories', {
          'name': catName,
          'iconCode': p['icon'],
        });
      } else {
        prodCatId = (pRes.first['id'] as num).toInt();
      }

      final existing = await db.rawQuery(
        'SELECT COUNT(*) as c FROM products WHERE lower(name) = ?',
        [(p['name'] as String).toLowerCase()],
      );
      final count = (existing.first['c'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        await db.insert('products', {
          'category_id': prodCatId,
          'name': p['name'],
          'price': p['price'],
          'iconCode': p['icon'],
          'ingredients': p['ingredients'],
          'combo_quantity': 1,
          'area': AppConstants.areaCocina,
        });
      }
    }
  }
}
