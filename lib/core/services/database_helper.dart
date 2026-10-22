import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import 'db_seed.dart';

/// Acceso a la base de datos SQLite del POS.
///
/// La BD se llama `pos_karen.db` (igual que la versión original) y las
/// migraciones conservan la compatibilidad total con las versiones 1 a 9.
/// La versión 10 SOLO agrega combos nuevos en divisas.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const int dbVersion = 10;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // ignore: avoid_print
    print('--- RUTA DE LA BASE DE DATOS: $path ---');
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  // ===========================================================================
  // CREACIÓN
  // ===========================================================================

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconCode INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_number INTEGER NOT NULL,
        service_type TEXT NOT NULL,
        sale_status TEXT NOT NULL DEFAULT 'FINALIZADO',
        total REAL NOT NULL,
        customer_name TEXT DEFAULT '',
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ticket_counters (
        date_key TEXT PRIMARY KEY,
        last_number INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        notes TEXT DEFAULT '',
        is_combo INTEGER NOT NULL DEFAULT 0,
        service_type TEXT NOT NULL DEFAULT 'COMER_AQUI',
        area TEXT NOT NULL DEFAULT 'COCINA',
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        iconCode INTEGER NOT NULL,
        ingredients TEXT,
        combo_quantity INTEGER DEFAULT 1,
        area TEXT NOT NULL DEFAULT 'COCINA',
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE extras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await DbSeed.seedCatalog(db);
    await DbSeed.seedExtras(db);
  }

  // ===========================================================================
  // MIGRACIONES (compatibles con la BD original v1 → v10)
  // ===========================================================================

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Migración 1 → 2: ticket_number y service_type.
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN ticket_number INTEGER;');
      await db.execute('ALTER TABLE sales ADD COLUMN service_type TEXT;');

      final maxTicket =
          await db.rawQuery('SELECT MAX(ticket_number) as m FROM sales');
      final currentMax = (maxTicket.first['m'] as num?)?.toInt() ?? 0;

      final rows = await db.query('sales', columns: ['id']);
      int counter = currentMax;
      for (final r in rows) {
        counter += 1;
        await db.update(
          'sales',
          {'ticket_number': counter, 'service_type': AppConstants.comerAqui},
          where: 'id = ?',
          whereArgs: [r['id']],
        );
      }
    }

    // Migración 4: estado de venta, notas y combos en ítems.
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE sales ADD COLUMN sale_status TEXT NOT NULL DEFAULT 'FINALIZADO';",
      );
      await db.execute("ALTER TABLE sale_items ADD COLUMN notes TEXT DEFAULT '';");
      await db.execute(
        'ALTER TABLE sale_items ADD COLUMN is_combo INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        "UPDATE sales SET sale_status = 'FINALIZADO' WHERE sale_status IS NULL;",
      );
    }

    // Migración 5: tabla de ajustes.
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }

    // Migración 6: service_type por ítem.
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE sale_items ADD COLUMN service_type TEXT NOT NULL DEFAULT 'COMER_AQUI';",
      );
    }

    // Migración 6 → 7: tabla de extras.
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS extras (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL
        )
      ''');
      await DbSeed.seedExtras(db);
    }

    // Migración 7 → 8: área de preparación + bebidas semilla.
    if (oldVersion < 8) {
      await db.execute(
        "ALTER TABLE products ADD COLUMN area TEXT NOT NULL DEFAULT 'COCINA';",
      );
      await db.execute(
        "ALTER TABLE sale_items ADD COLUMN area TEXT NOT NULL DEFAULT 'COCINA';",
      );
      await db.execute(
        "UPDATE products SET area = 'SALCHIPAPAS' WHERE category_id IN "
        "(SELECT id FROM categories WHERE lower(name) LIKE '%salchipapa%');",
      );
      await db.execute(
        "UPDATE sale_items SET area = 'SALCHIPAPAS' WHERE product_name IN "
        "(SELECT name FROM products WHERE area = 'SALCHIPAPAS');",
      );

      final catRes = await db.rawQuery(
        "SELECT id FROM categories WHERE lower(name) = 'bebidas'",
      );
      int bebidasCatId;
      if (catRes.isNotEmpty) {
        bebidasCatId = (catRes.first['id'] as num).toInt();
      } else {
        bebidasCatId = await db.insert('categories', {
          'name': 'Bebidas',
          'iconCode': Icons.local_drink.codePoint,
        });
      }

      final bebidasProducts = [
        {'name': 'Coca-Cola 500ml', 'price': 1.50},
        {'name': 'Coca-Cola 2L', 'price': 3.50},
        {'name': 'Pepsi 500ml', 'price': 1.25},
        {'name': 'Pepsi 2L', 'price': 3.00},
        {'name': 'Agua Mineral 500ml', 'price': 1.00},
        {'name': 'Malta', 'price': 1.50},
        {'name': 'Jugo Hit 1L', 'price': 2.50},
      ];

      for (var p in bebidasProducts) {
        final existing = await db.rawQuery(
          'SELECT COUNT(*) as c FROM products WHERE lower(name) = ?',
          [(p['name'] as String).toLowerCase()],
        );
        final count = (existing.first['c'] as num?)?.toInt() ?? 0;
        if (count == 0) {
          await db.insert('products', {
            'category_id': bebidasCatId,
            'name': p['name'],
            'price': p['price'],
            'iconCode': Icons.local_drink.codePoint,
            'ingredients': '',
            'combo_quantity': 1,
            'area': AppConstants.areaBebidas,
          });
        }
      }
    }

    // Migración 8 → 9: nombre del cliente.
    if (oldVersion < 9) {
      await db.execute("ALTER TABLE sales ADD COLUMN customer_name TEXT DEFAULT '';");
    }

    // Migración 9 → 10: novedades del menú real (bobventas.netlify.app):
    // combos nuevos en divisas + Choriperro + Pepito.
    if (oldVersion < 10) {
      await DbSeed.seedNewItems(db);
    }
  }

  // ===========================================================================
  // CATÁLOGO
  // ===========================================================================

  /// Iconos del catálogo como referencias directas (aptas para el
  /// tree-shaking). IMPORTANTE: aquí NO se extrae .codePoint — hacer eso
  /// dentro de un contexto const rompe el tree-shaking en release.
  static const List<IconData> _catalogIcons = [
    Icons.hot_tub,
    Icons.lunch_dining,
    Icons.fastfood,
    Icons.restaurant_menu,
    Icons.set_meal,
    Icons.local_drink,
    Icons.local_fire_department,
    Icons.star,
    Icons.workspace_premium,
    Icons.layers,
    Icons.wrap_text,
    Icons.dinner_dining,
    Icons.category,
    Icons.inventory_2,
    Icons.restaurant,
    Icons.store,
    Icons.local_pizza,
    Icons.icecream,
    Icons.coffee,
  ];

  /// Registro codePoint → IconData construido en RUNTIME (fuera de contexto
  /// const) para no interferir con el tree-shaking de iconos.
  static final Map<int, IconData> _iconRegistry = {
    for (final icon in _catalogIcons) icon.codePoint: icon,
  };

  IconData _iconFromCode(int codePoint) =>
      _iconRegistry[codePoint] ?? Icons.restaurant;

  Future<List<Map<String, dynamic>>> loadAllData() async {
    final db = await instance.database;
    final cats = await db.query('categories');
    final List<Map<String, dynamic>> result = [];

    for (var catRow in cats) {
      final prods = await db.query(
        'products',
        where: 'category_id = ?',
        whereArgs: [catRow['id']],
      );
      result.add({
        'id': catRow['id'],
        'name': catRow['name'],
        'icon': _iconFromCode((catRow['iconCode'] as num).toInt()),
        'products': prods
            .map((p) => {
                  'id': p['id'],
                  'name': p['name'],
                  'price': p['price'],
                  'ingredients': p['ingredients'],
                  'combo_quantity': p['combo_quantity'],
                  'area': p['area'] ?? AppConstants.areaCocina,
                  'icon': _iconFromCode((p['iconCode'] as num).toInt()),
                })
            .toList(),
      });
    }
    return result;
  }

  Future<void> addCategory(String name) async {
    final db = await instance.database;
    await db.insert('categories', {
      'name': name,
      'iconCode': Icons.category.codePoint,
    });
  }

  Future<void> addProduct(
    int categoryId,
    String name,
    double price, {
    String ingredients = '',
  }) async {
    final db = await instance.database;
    final catRows = await db.query(
      'categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    String area = AppConstants.areaCocina;
    if (catRows.isNotEmpty) {
      final catName = (catRows.first['name'] as String? ?? '').toLowerCase();
      if (catName.contains('salchipapa')) {
        area = AppConstants.areaSalchipapas;
      } else if (catName.contains('bebida') || catName.contains('gaseosa')) {
        area = AppConstants.areaBebidas;
      }
    }
    await db.insert('products', {
      'category_id': categoryId,
      'name': name,
      'price': price,
      'iconCode': Icons.inventory_2.codePoint,
      'ingredients': ingredients,
      'area': area,
    });
  }

  Future<void> deleteCategory(int id) async {
    final db = await instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductPrice(int id, double newPrice) async {
    final db = await instance.database;
    await db.update(
      'products',
      {'price': newPrice},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // CICLO DEL DÍA OPERATIVO (día de ventas con desplazamiento de -17 horas)
  // ===========================================================================

  Future<String> _currentDayKey() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      "SELECT date(datetime('now', 'localtime', '-17 hours')) as d",
    );
    return rows.first['d'] as String? ?? '';
  }

  String get _todayExpr =>
      "date(datetime(timestamp, 'localtime', '-17 hours'))";

  Future<void> clearPreviousDaySales() async {
    final db = await instance.database;
    final currentDay = await _currentDayKey();

    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['last_cleared_day'],
      limit: 1,
    );
    final lastCleared = rows.isEmpty ? null : rows.first['value'] as String?;

    if (lastCleared == currentDay) return;

    await db.rawDelete(
      "DELETE FROM sales WHERE $_todayExpr < ?",
      [currentDay],
    );
    await db.rawDelete('DELETE FROM ticket_counters WHERE date_key < ?', [
      currentDay,
    ]);
    await db.insert(
      'ticket_counters',
      {'date_key': currentDay, 'last_number': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'app_settings',
      {'key': 'last_cleared_day', 'value': currentDay},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearTodaySales() async {
    final db = await instance.database;
    final currentDay = await _currentDayKey();
    await db.rawDelete(
      "DELETE FROM sales WHERE $_todayExpr = ?",
      [currentDay],
    );
    await db.insert(
      'ticket_counters',
      {'date_key': currentDay, 'last_number': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // AJUSTES (app_settings)
  // ===========================================================================

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // VENTAS
  // ===========================================================================

  Future<int> getTodayNextTicketNumber() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      "SELECT date(datetime('now', 'localtime', '-17 hours')) as d",
    );
    final dateKey = rows.first['d'] as String? ?? '';

    final existing = await db.query(
      'ticket_counters',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('ticket_counters', {'date_key': dateKey, 'last_number': 1});
      return 1;
    }

    final lastNumber = (existing.first['last_number'] as num).toInt();
    final next = lastNumber + 1;
    await db.update(
      'ticket_counters',
      {'last_number': next},
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    return next;
  }

  Future<int> saveSale(
    double total,
    List<Map<String, dynamic>> items,
    String serviceType, {
    int? ticketNumber,
    String saleStatus = 'FINALIZADO',
    String customerName = '',
  }) async {
    final db = await instance.database;
    final ticket = ticketNumber ?? await getTodayNextTicketNumber();

    final saleId = await db.insert('sales', {
      'ticket_number': ticket,
      'service_type': serviceType,
      'sale_status': saleStatus,
      'total': total,
      'customer_name': customerName,
    });

    for (var item in items) {
      await _insertSaleItem(db, saleId, item);
    }
    return ticket;
  }

  Future<void> _insertSaleItem(
      Database db, int saleId, Map<String, dynamic> item) async {
    await db.insert('sale_items', {
      'sale_id': saleId,
      'product_name': item['name'],
      'quantity': item['quantity'],
      'price': item['price'],
      'notes': item['notes'] ?? '',
      'is_combo': (item['isCombo'] == true) ? 1 : 0,
      'service_type': item['serviceType'] ?? AppConstants.comerAqui,
      'area': item['area'] ?? AppConstants.areaCocina,
    });
  }

  Future<List<Map<String, dynamic>>> searchSales({
    int? ticketNumber,
    String? status,
  }) async {
    final db = await instance.database;
    final whereClauses = <String>[];
    final whereArgs = <Object>[];

    if (ticketNumber != null) {
      whereClauses.add('ticket_number = ?');
      whereArgs.add(ticketNumber);
    }
    if (status != null && status != 'ALL') {
      whereClauses.add('sale_status = ?');
      whereArgs.add(status);
    }

    return await db.query(
      'sales',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<String, dynamic>?> getSale(int saleId) async {
    final db = await instance.database;
    final rows = await db.query('sales',
        where: 'id = ?', whereArgs: [saleId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await instance.database;
    return await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );
  }

  Future<void> deleteSale(int saleId) async {
    final db = await instance.database;
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  Future<void> updateSaleMetadata(
      int saleId, String serviceType, String saleStatus) async {
    final db = await instance.database;
    await db.update(
      'sales',
      {'service_type': serviceType, 'sale_status': saleStatus},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> updateSaleWithItems(
    int saleId,
    double total,
    String serviceType,
    String saleStatus,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await instance.database;
    await db.update(
      'sales',
      {'service_type': serviceType, 'sale_status': saleStatus, 'total': total},
      where: 'id = ?',
      whereArgs: [saleId],
    );
    await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    for (var item in items) {
      await _insertSaleItem(db, saleId, item);
    }
  }

  // ===========================================================================
  // REPORTES — con separación por moneda (Bs. para productos, $ para combos)
  // ===========================================================================

  /// Total combinado del día (compatibilidad con la versión original).
  Future<double> getTodaySalesTotal() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(total) as total FROM sales WHERE $_todayExpr = "
      "date(datetime('now', 'localtime', '-17 hours'))",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Totales del día separados por moneda.
  /// totalBs = suma de productos NO combo. totalUsd = suma de combos.
  Future<({double totalBs, double totalUsd})>
      getTodayTotalsByCurrency() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN si.is_combo = 0 THEN si.price * si.quantity ELSE 0 END), 0) AS total_bs,
        COALESCE(SUM(CASE WHEN si.is_combo = 1 THEN si.price * si.quantity ELSE 0 END), 0) AS total_usd
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE date(datetime(s.timestamp, 'localtime', '-17 hours')) =
            date(datetime('now', 'localtime', '-17 hours'))
    ''');
    final row = result.first;
    return (
      totalBs: (row['total_bs'] as num?)?.toDouble() ?? 0.0,
      totalUsd: (row['total_usd'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Resumen por producto del día, separando moneda por combo.
  /// Cada fila incluye: product_name, is_combo, qty, total.
  Future<List<Map<String, dynamic>>> getTodaySalesSummaryByCurrency() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT si.product_name,
             si.is_combo,
             SUM(si.quantity) as qty,
             SUM(si.price * si.quantity) as total
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE date(datetime(s.timestamp, 'localtime', '-17 hours')) =
            date(datetime('now', 'localtime', '-17 hours'))
      GROUP BY si.product_name, si.is_combo
      ORDER BY total DESC
    ''');
  }

  /// Resumen combinado por producto (compatibilidad original).
  Future<List<Map<String, dynamic>>> getTodaySalesSummary() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT product_name, SUM(quantity) as qty, SUM(price * quantity) as total
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE date(datetime(s.timestamp, 'localtime', '-17 hours')) =
            date(datetime('now', 'localtime', '-17 hours'))
      GROUP BY product_name
      ORDER BY qty DESC
    ''');
  }

  /// Ventas de hoy con desglose Bs. / $ por venta.
  /// Cada fila de `sales` incluye las columnas extra: total_bs y total_usd.
  Future<List<Map<String, dynamic>>> getTodaySalesWithCurrency() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT s.*,
             COALESCE(t.total_bs, 0) AS total_bs,
             COALESCE(t.total_usd, 0) AS total_usd
      FROM sales s
      LEFT JOIN (
        SELECT sale_id,
               SUM(CASE WHEN is_combo = 0 THEN price * quantity ELSE 0 END) AS total_bs,
               SUM(CASE WHEN is_combo = 1 THEN price * quantity ELSE 0 END) AS total_usd
        FROM sale_items
        GROUP BY sale_id
      ) t ON t.sale_id = s.id
      WHERE date(datetime(s.timestamp, 'localtime', '-17 hours')) =
            date(datetime('now', 'localtime', '-17 hours'))
      ORDER BY s.ticket_number DESC
    ''');
  }

  /// Ventas de hoy (compatibilidad original).
  Future<List<Map<String, dynamic>>> getTodaySales() async {
    final db = await instance.database;
    return await db.rawQuery(
      "SELECT * FROM sales WHERE $_todayExpr = "
      "date(datetime('now', 'localtime', '-17 hours')) "
      'ORDER BY ticket_number DESC',
    );
  }

  // ===========================================================================
  // EXTRAS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getExtras() async {
    final db = await instance.database;
    return await db.query('extras', orderBy: 'name ASC');
  }

  Future<int> addExtra(String name, double price) async {
    final db = await instance.database;
    return await db.insert('extras', {'name': name, 'price': price});
  }

  Future<void> updateExtra(int id, String name, double price) async {
    final db = await instance.database;
    await db.update(
      'extras',
      {'name': name, 'price': price},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExtra(int id) async {
    final db = await instance.database;
    await db.delete('extras', where: 'id = ?', whereArgs: [id]);
  }
}
