import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ===================== MODELS =====================

class ProductRow {
  final int? id;
  final String name;
  final double lastCostPrice;
  final String? createdAt;

  ProductRow({
    this.id,
    required this.name,
    this.lastCostPrice = 0,
    this.createdAt,
  });

  factory ProductRow.fromMap(Map<String, dynamic> m) => ProductRow(
        id: m['id'] as int?,
        name: m['name'] as String,
        lastCostPrice: (m['last_cost_price'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] as String?,
      );
}

class SaleRow {
  final int? id;
  final int productId;
  final double quantity;
  final double sellingPrice;
  final double costPriceSnapshot;
  final double grossMargin;
  final String? timestamp;

  SaleRow({
    this.id,
    required this.productId,
    required this.quantity,
    required this.sellingPrice,
    required this.costPriceSnapshot,
    required this.grossMargin,
    this.timestamp,
  });

  factory SaleRow.fromMap(Map<String, dynamic> m) => SaleRow(
        id: m['id'] as int?,
        productId: m['product_id'] as int,
        quantity: (m['quantity'] as num).toDouble(),
        sellingPrice: (m['selling_price'] as num).toDouble(),
        costPriceSnapshot: (m['cost_price_snapshot'] as num).toDouble(),
        grossMargin: (m['gross_margin'] as num).toDouble(),
        timestamp: m['timestamp'] as String?,
      );
}

class ActivityRow {
  final String type; // 'mauzo' | 'manunuzi' | 'matumizi'
  final String name;
  final double? quantity;
  final double amount; // chanya (mauzo) au hasi (manunuzi/matumizi)
  final String timestamp;

  ActivityRow({
    required this.type,
    required this.name,
    this.quantity,
    required this.amount,
    required this.timestamp,
  });

  factory ActivityRow.fromMap(Map<String, dynamic> m) => ActivityRow(
        type: m['type'] as String,
        name: m['name'] as String,
        quantity: (m['quantity'] as num?)?.toDouble(),
        amount: (m['amount'] as num).toDouble(),
        timestamp: m['timestamp'] as String,
      );
}

// ===================== DB HELPER =====================

/// Hii inachukua nafasi ya `SQLiteManager.instance` ya FlutterFlow.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'biashara_mfukoni.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            last_cost_price REAL DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            quantity REAL NOT NULL,
            selling_price REAL NOT NULL,
            cost_price_snapshot REAL NOT NULL,
            gross_margin REAL NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE stock_purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            quantity REAL NOT NULL,
            unit_cost_price REAL NOT NULL,
            total_amount REAL NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            amount REAL NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE fixed_costs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            monthly_amount REAL NOT NULL,
            start_date DATE DEFAULT CURRENT_DATE
          )
        ''');
      },
    );
  }

  // ===================== PRODUCTS =====================

  Future<List<ProductRow>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map((e) => ProductRow.fromMap(e)).toList();
  }

  /// "Predictive chips" — mtu anaandika, bidhaa zinazofanana zinatokea
  /// kama chips za kubofya, badala ya kuandika kila herufi.
  Future<List<ProductRow>> searchProducts(String query) async {
    final db = await database;
    if (query.trim().isEmpty) {
      final rows = await db.query('products', orderBy: 'name ASC', limit: 20);
      return rows.map((e) => ProductRow.fromMap(e)).toList();
    }
    final rows = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
      limit: 20,
    );
    return rows.map((e) => ProductRow.fromMap(e)).toList();
  }

  /// Kwa "Matumizi" tab ya sheet_imetoka — chips za maelezo ya matumizi
  /// yaliyoshaandikwa nyuma (mfano "Nauli", "Umeme").
  Future<List<String>> searchExpenseDescriptions(String query) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT description FROM expenses
      WHERE description IS NOT NULL AND description LIKE ?
      ORDER BY description ASC LIMIT 20
      ''',
      ['%$query%'],
    );
    return rows.map((e) => e['description'] as String).toList();
  }

  /// Inaunda bidhaa mpya, au inarudisha id ya iliyopo kama jina linafanana.
  Future<int> getOrCreateProduct(String name, {double costPrice = 0}) async {
    final db = await database;
    final existing = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    return db.insert('products', {
      'name': name,
      'last_cost_price': costPrice,
    });
  }

  // ===================== SALES (Pesa Imeingia) =====================

  /// Inarekodi mauzo. Pillar 2: `costPriceSnapshot` unaweza kupitishwa
  /// moja kwa moja (bidhaa mpya, bei ikiwa bado haijaandikwa kwenye
  /// `products`) au ukiachwa null ili uchukuliwe kutoka `products.last_cost_price`
  /// (bidhaa iliyopo tayari) — faida inabaki sahihi hata bei ya mzigo
  /// ikibadilika kesho, kwa sababu snapshot inahifadhiwa kwenye rekodi
  /// ya mauzo yenyewe, si kuchukuliwa upya kila wakati.
  Future<int> rekodiMauzo({
    required int productId,
    required double quantity,
    required double sellingPrice,
    double? costPriceSnapshot,
  }) async {
    final db = await database;

    double costPrice;
    if (costPriceSnapshot != null) {
      costPrice = costPriceSnapshot;
    } else {
      final productRows =
          await db.query('products', where: 'id = ?', whereArgs: [productId]);
      costPrice = (productRows.first['last_cost_price'] as num).toDouble();
    }

    final grossMargin = (sellingPrice - costPrice) * quantity;

    return db.insert('sales', {
      'product_id': productId,
      'quantity': quantity,
      'selling_price': sellingPrice,
      'cost_price_snapshot': costPrice,
      'gross_margin': grossMargin,
    });
  }

  Future<List<SaleRow>> getMauzoYaLeo() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query(
      'sales',
      where: "date(timestamp) = ?",
      whereArgs: [today],
      orderBy: 'timestamp DESC',
    );
    return rows.map((e) => SaleRow.fromMap(e)).toList();
  }

  // ===================== STOCK PURCHASES (Pesa Imetoka -> Mzigo) =====================

  /// Inarekodi ununuzi wa mzigo NA inasasisha last_cost_price ya bidhaa hiyo,
  /// ili mauzo yajayo yatumie bei mpya ya mzigo (Cost Price Inflation Tracking).
  Future<int> rekodiUnunuziMzigo({
    required int productId,
    required double quantity,
    required double unitCostPrice,
  }) async {
    final db = await database;
    final totalAmount = quantity * unitCostPrice;

    final id = await db.insert('stock_purchases', {
      'product_id': productId,
      'quantity': quantity,
      'unit_cost_price': unitCostPrice,
      'total_amount': totalAmount,
    });

    await db.update(
      'products',
      {'last_cost_price': unitCostPrice},
      where: 'id = ?',
      whereArgs: [productId],
    );

    return id;
  }

  // ===================== EXPENSES (Pesa Imetoka -> Matumizi) =====================

  Future<int> rekodiMatumizi({
    required double amount,
    String? description,
  }) async {
    final db = await database;
    return db.insert('expenses', {
      'description': description,
      'amount': amount,
    });
  }

  // ===================== FIXED COSTS (Pillar 3, Settings) =====================

  Future<int> ongezaGharamaYaKudumu({
    required String name,
    required double monthlyAmount,
  }) async {
    final db = await database;
    return db.insert('fixed_costs', {
      'name': name,
      'monthly_amount': monthlyAmount,
    });
  }

  Future<List<Map<String, dynamic>>> getFixedCosts() async {
    final db = await database;
    return db.query('fixed_costs', orderBy: 'name ASC');
  }

  Future<int> futaGharamaYaKudumu(int id) async {
    final db = await database;
    return db.delete('fixed_costs', where: 'id = ?', whereArgs: [id]);
  }

  /// Pillar 3: gharama za kudumu / siku 30 — kikato hiki kinakatwa kila
  /// siku bila kujali mauzo ya siku hiyo (uamuzi wa makusudi: kodi
  /// haisubiri mauzo, hivyo Baki Halisi inaonyesha ukweli, siyo picha
  /// nzuri ya uongo).
  Future<double> getDailyOverhead() async {
    final db = await database;
    final rows = await db.query('fixed_costs');
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['monthly_amount'] as num).toDouble(),
    );
    return total / 30;
  }

  // ===================== MUHTASARI WA SIKU (Home Screen) =====================

  Future<double> getMauzoLeoJumla() async {
    final sales = await getMauzoYaLeo();
    return sales.fold<double>(
      0,
      (sum, s) => sum + (s.sellingPrice * s.quantity),
    );
  }

  Future<double> getFaidaLeoJumla() async {
    final sales = await getMauzoYaLeo();
    return sales.fold<double>(0, (sum, s) => sum + s.grossMargin);
  }

  Future<double> getMatumiziLeoJumla() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final expenseRows = await db.query(
      'expenses',
      where: "date(timestamp) = ?",
      whereArgs: [today],
    );
    return expenseRows.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );
  }

  /// Pillar 2: Bajeti ya Mzigo inayoendelea kukusanyika = jumla ya cost-price
  /// bucket kutoka mauzo YOTE (si leo tu) - jumla ya matumizi ya kununua
  /// mzigo (stock_purchases). Hii ni akiba ya kudumu, si ya siku moja.
  Future<double> getBajetiYaMzigo() async {
    final db = await database;

    final salesRows = await db.query('sales');
    final restockCapitalAccrued = salesRows.fold<double>(
      0,
      (sum, s) =>
          sum +
          (s['cost_price_snapshot'] as num).toDouble() *
              (s['quantity'] as num).toDouble(),
    );

    final purchaseRows = await db.query('stock_purchases');
    final totalSpentOnRestock = purchaseRows.fold<double>(
      0,
      (sum, p) => sum + (p['total_amount'] as num).toDouble(),
    );

    return restockCapitalAccrued - totalSpentOnRestock;
  }

  /// Pillar 3: Baki Halisi ya leo = faida ya leo - matumizi ya leo - overhead ya siku
  Future<double> getBakiHalisiLeo() async {
    final faida = await getFaidaLeoJumla();
    final matumizi = await getMatumiziLeoJumla();
    final overhead = await getDailyOverhead();
    return faida - matumizi - overhead;
  }

  // ===================== HISTORIA (Awamu 1) =====================

  /// Inaunganisha mauzo, manunuzi, na matumizi kuwa orodha moja, kwa
  /// mpangilio wa muda (mpya kwanza). `typeFilter` inaweza kuwa
  /// 'mauzo', 'manunuzi', 'matumizi', au null (zote).
  Future<List<ActivityRow>> getActivityLog({String? typeFilter}) async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT 'mauzo' AS type, p.name AS name, s.quantity AS quantity,
             (s.selling_price * s.quantity) AS amount, s.timestamp AS timestamp
      FROM sales s JOIN products p ON p.id = s.product_id

      UNION ALL

      SELECT 'manunuzi' AS type, p.name AS name, sp.quantity AS quantity,
             -sp.total_amount AS amount, sp.timestamp AS timestamp
      FROM stock_purchases sp JOIN products p ON p.id = sp.product_id

      UNION ALL

      SELECT 'matumizi' AS type,
             COALESCE(e.description, 'Matumizi') AS name,
             NULL AS quantity,
             -e.amount AS amount, e.timestamp AS timestamp
      FROM expenses e

      ORDER BY timestamp DESC
    ''');

    final all = rows.map((e) => ActivityRow.fromMap(e)).toList();
    if (typeFilter == null) return all;
    return all.where((a) => a.type == typeFilter).toList();
  }

  // ===================== BREAKDOWN (Awamu 1 sub-pages) =====================

  /// Pillar 2 breakdown: mchango wa kila bidhaa kwenye Bajeti ya Mzigo
  /// (jumla ya cost-price kutoka mauzo yake, kwa sasa - hairekebishi
  /// kwa manunuzi tayari yaliyofanyika kwa bidhaa hiyo mahususi).
  Future<List<Map<String, dynamic>>> getMchangoWaBidhaaKwenyeBajeti() async {
    final db = await database;
    return db.rawQuery('''
      SELECT p.name AS name,
             SUM(s.cost_price_snapshot * s.quantity) AS jumla
      FROM sales s JOIN products p ON p.id = s.product_id
      GROUP BY p.id
      HAVING jumla > 0
      ORDER BY jumla DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getManunuziYaKaribuni({int limit = 5}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT p.name AS name, sp.quantity AS quantity,
             sp.total_amount AS jumla, sp.timestamp AS timestamp
      FROM stock_purchases sp JOIN products p ON p.id = sp.product_id
      ORDER BY sp.timestamp DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getMatumiziYaLeo() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return db.query(
      'expenses',
      where: "date(timestamp) = ?",
      whereArgs: [today],
      orderBy: 'timestamp DESC',
    );
  }
}
