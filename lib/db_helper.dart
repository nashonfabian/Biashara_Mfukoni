import 'dart:math';

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
  final double amount;
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

/// Matokeo ya Uchambuzi kwa bidhaa moja (RSI + utabiri + mgongano wa
/// manunuzi/mauzo), kwa ajili ya tab ya "Bidhaa" na banner za Home.
class ProductAnalysis {
  final int productId;
  final String name;
  final int salesCount;
  final double? medianSalesGapDays; // null = bado inajifunza
  final double? daysSinceLastSale;
  final double? rsi;
  final double periodProfit;
  final double? estimatedRemainingStock; // null = hakuna ununuzi bado
  final double? predictedDaysRemaining; // null = haiwezekani kutabiri bado
  final double? restockRatio; // null = hakuna data ya kutosha

  ProductAnalysis({
    required this.productId,
    required this.name,
    required this.salesCount,
    this.medianSalesGapDays,
    this.daysSinceLastSale,
    this.rsi,
    required this.periodProfit,
    this.estimatedRemainingStock,
    this.predictedDaysRemaining,
    this.restockRatio,
  });

  bool get inaJifunza => salesCount < 2;
  bool get imesimama => rsi != null && rsi! >= 2.5;
}

class DayAnalysis {
  final DateTime date;
  final double totalSales;
  final String peakBucketLabel; // mfano "Jioni (17:00-21:00)"

  DayAnalysis({
    required this.date,
    required this.totalSales,
    required this.peakBucketLabel,
  });
}

class PeriodRange {
  final DateTime start; // inclusive
  final DateTime endExclusive; // exclusive
  final String label;

  PeriodRange(this.start, this.endExclusive, this.label);
}

// ===================== DB HELPER =====================

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
      version: 2,
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

        // end_date = NULL inamaanisha gharama bado iko hai. Kufuta
        // kwenye UI kunaweka tu end_date = leo (soft-end), ili Baki
        // Halisi za siku za nyuma zibaki sahihi kihistoria.
        await db.execute('''
          CREATE TABLE fixed_costs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            monthly_amount REAL NOT NULL,
            start_date DATE DEFAULT CURRENT_DATE,
            end_date DATE
          )
        ''');

        // Kwa mambo madogo ya UI state, mfano tarehe ya mwisho
        // Muhtasari wa Jana ulipoonekana.
        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT
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

  // ===================== FIXED COSTS (Settings) =====================

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

  /// Orodha ya gharama ZILIZO HAI pekee (kwa ajili ya Settings screen).
  Future<List<Map<String, dynamic>>> getFixedCosts() async {
    final db = await database;
    return db.query(
      'fixed_costs',
      where: 'end_date IS NULL',
      orderBy: 'name ASC',
    );
  }

  /// "Kufuta" hakuondoi rekodi — kunaweka tu end_date = leo, ili
  /// Baki Halisi za siku zilizopita zibaki sahihi kihistoria.
  Future<int> futaGharamaYaKudumu(int id) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return db.update(
      'fixed_costs',
      {'end_date': today},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Gharama ya kudumu ya siku MOJA MAHUSUSI (kwa tarehe yoyote, si leo
  /// tu) — inazingatia start_date/end_date, hivyo ripoti za nyuma
  /// zinabaki sahihi hata baada ya gharama kufutwa/kuongezwa leo.
  Future<double> getDailyOverheadForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT SUM(monthly_amount) AS jumla FROM fixed_costs
      WHERE start_date <= ?
        AND (end_date IS NULL OR end_date > ?)
    ''', [dateStr, dateStr]);
    final jumla = (rows.first['jumla'] as num?)?.toDouble() ?? 0;
    return jumla / 30;
  }

  Future<double> getDailyOverhead() => getDailyOverheadForDate(DateTime.now());

  // ===================== APP STATE =====================

  Future<String?> getAppState(String key) async {
    final db = await database;
    final rows = await db.query('app_state', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setAppState(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===================== MUHTASARI WA SIKU (Home Screen) =====================

  Future<double> getMauzoLeoJumla() async {
    final sales = await getMauzoYaLeo();
    return sales.fold<double>(0, (sum, s) => sum + (s.sellingPrice * s.quantity));
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
    return expenseRows.fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());
  }

  /// Pillar 2: Bajeti ya Mzigo inayoendelea kukusanyika (pooled).
  Future<double> getBajetiYaMzigo() async {
    final db = await database;

    final salesRows = await db.query('sales');
    final restockCapitalAccrued = salesRows.fold<double>(
      0,
      (sum, s) =>
          sum +
          (s['cost_price_snapshot'] as num).toDouble() * (s['quantity'] as num).toDouble(),
    );

    final purchaseRows = await db.query('stock_purchases');
    final totalSpentOnRestock =
        purchaseRows.fold<double>(0, (sum, p) => sum + (p['total_amount'] as num).toDouble());

    return restockCapitalAccrued - totalSpentOnRestock;
  }

  /// Bajeti ya Mzigo (pooled) kama ilivyokuwa hadi tarehe fulani —
  /// inatumika kujenga "Mwelekeo wa Bajeti".
  Future<double> getBajetiYaMzigoAsOf(DateTime asOf) async {
    final db = await database;
    final asOfStr = asOf.toIso8601String();

    final salesRows = await db.rawQuery(
      'SELECT cost_price_snapshot, quantity FROM sales WHERE timestamp <= ?',
      [asOfStr],
    );
    final accrued = salesRows.fold<double>(
      0,
      (sum, s) =>
          sum + (s['cost_price_snapshot'] as num).toDouble() * (s['quantity'] as num).toDouble(),
    );

    final purchaseRows = await db.rawQuery(
      'SELECT total_amount FROM stock_purchases WHERE timestamp <= ?',
      [asOfStr],
    );
    final spent =
        purchaseRows.fold<double>(0, (sum, p) => sum + (p['total_amount'] as num).toDouble());

    return accrued - spent;
  }

  /// Mwelekeo wa Bajeti: % mabadiliko ya Bajeti ya sasa dhidi ya wastani
  /// wa wiki 4 zilizopita — inagundua mtaji unaoyeyuka taratibu kabla
  /// hujafikia hatua mbaya. Null = bado hakuna historia ya kutosha
  /// (chini ya wiki 4 za data).
  Future<Map<String, dynamic>?> getBudgetTrend() async {
    final now = DateTime.now();
    final current = await getBajetiYaMzigo();

    final pastValues = <double>[];
    for (var i = 1; i <= 4; i++) {
      pastValues.add(await getBajetiYaMzigoAsOf(now.subtract(Duration(days: 7 * i))));
    }

    // Kama zote nne za nyuma ni sifuri (duka jipya kabisa), bado
    // hakuna cha kulinganisha nacho.
    final hasHistory = pastValues.any((v) => v != 0);
    if (!hasHistory) return null;

    final avgPast = pastValues.reduce((a, b) => a + b) / pastValues.length;
    if (avgPast == 0) return null;

    final percentChange = ((current - avgPast) / avgPast.abs()) * 100;

    return {
      'current': current,
      'wastaniWiki4': avgPast,
      'percentChange': percentChange, // hasi = bajeti inashuka
    };
  }

  Future<double> getBakiHalisiLeo() async {
    final faida = await getFaidaLeoJumla();
    final matumizi = await getMatumiziLeoJumla();
    final overhead = await getDailyOverhead();
    return faida - matumizi - overhead;
  }

  // ===================== HISTORIA =====================

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

      SELECT 'matumizi' AS type, COALESCE(e.description, 'Matumizi') AS name,
             NULL AS quantity, -e.amount AS amount, e.timestamp AS timestamp
      FROM expenses e

      ORDER BY timestamp DESC
    ''');

    final all = rows.map((e) => ActivityRow.fromMap(e)).toList();
    if (typeFilter == null) return all;
    return all.where((a) => a.type == typeFilter).toList();
  }

  // ===================== BAJETI BREAKDOWN =====================

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

  /// Bajeti salama ya BIDHAA MAHUSUSI (si jumla ya duka zima) — kiasi
  /// gani cha mtaji uliochangwa na bidhaa hii bado hakijatumika
  /// kununulia mzigo mpya wa bidhaa hii hii.
  Future<double> getBajetiYaBidhaa(int productId) async {
    final db = await database;

    final salesRows = await db.query(
      'sales',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    final accrued = salesRows.fold<double>(
      0,
      (sum, s) =>
          sum + (s['cost_price_snapshot'] as num).toDouble() * (s['quantity'] as num).toDouble(),
    );

    final purchaseRows = await db.query(
      'stock_purchases',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    final spent =
        purchaseRows.fold<double>(0, (sum, pRow) => sum + (pRow['total_amount'] as num).toDouble());

    return accrued - spent;
  }

  // ===================== HELPER: MEDIAN =====================

  double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }

  // ===================== AWAMU 2: UCHAMBUZI (Pillar 1) =====================

  /// RSI + utabiri + restock ratio kwa kila bidhaa. Hii ndiyo msingi wa
  /// tab ya "Bidhaa" kwenye Uchambuzi, na banner za Home.
  Future<List<ProductAnalysis>> getProductAnalysis({DateTime? periodStart}) async {
    final db = await database;
    final products = await getProducts();
    final now = DateTime.now();
    final results = <ProductAnalysis>[];

    for (final product in products) {
      final saleRows = await db.query(
        'sales',
        where: 'product_id = ?',
        whereArgs: [product.id],
        orderBy: 'timestamp ASC',
      );
      final saleTimes = saleRows.map((r) => DateTime.parse(r['timestamp'] as String)).toList();

      // Faida ya kipindi (au maisha yote kama periodStart si maalum)
      final periodSales = periodStart == null
          ? saleRows
          : saleRows.where((r) => DateTime.parse(r['timestamp'] as String).isAfter(periodStart)).toList();
      final periodProfit =
          periodSales.fold<double>(0, (sum, r) => sum + (r['gross_margin'] as num).toDouble());

      double? medianGap;
      double? rsi;
      double? daysSinceLast;

      if (saleTimes.length >= 2) {
        final gaps = <double>[];
        for (var i = 1; i < saleTimes.length; i++) {
          gaps.add(saleTimes[i].difference(saleTimes[i - 1]).inHours / 24.0);
        }
        medianGap = _median(gaps);
        daysSinceLast = now.difference(saleTimes.last).inHours / 24.0;
        if (medianGap != null && medianGap > 0) {
          rsi = daysSinceLast / medianGap;
        }
      }

      // Stock iliyobaki + Utabiri — inahitaji angalau ununuzi 1
      final purchaseRows = await db.query(
        'stock_purchases',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );

      double? estimatedRemaining;
      double? predictedDays;
      double? restockRatio;

      if (purchaseRows.isNotEmpty) {
        final totalPurchased =
            purchaseRows.fold<double>(0, (sum, r) => sum + (r['quantity'] as num).toDouble());
        final totalSold =
            saleRows.fold<double>(0, (sum, r) => sum + (r['quantity'] as num).toDouble());
        estimatedRemaining = totalPurchased - totalSold;

        // Kasi ya mauzo (units/siku) kutoka vipindi vya mauzo vilivyopo
        if (saleTimes.length >= 2 && medianGap != null && medianGap > 0) {
          final avgQtyPerSale =
              saleRows.fold<double>(0, (sum, r) => sum + (r['quantity'] as num).toDouble()) /
                  saleRows.length;
          final unitsPerDay = avgQtyPerSale / medianGap;
          if (unitsPerDay > 0 && estimatedRemaining > 0) {
            predictedDays = estimatedRemaining / unitsPerDay;
          }
        }

        // Restock Ratio: wastani wa muda kati ya manunuzi ÷ wastani wa mauzo
        if (purchaseRows.length >= 2 && medianGap != null && medianGap > 0) {
          final purchaseTimes =
              purchaseRows.map((r) => DateTime.parse(r['timestamp'] as String)).toList()..sort();
          final purchaseGaps = <double>[];
          for (var i = 1; i < purchaseTimes.length; i++) {
            purchaseGaps.add(purchaseTimes[i].difference(purchaseTimes[i - 1]).inHours / 24.0);
          }
          final medianRestockGap = _median(purchaseGaps);
          if (medianRestockGap != null && medianRestockGap > 0) {
            restockRatio = medianRestockGap / medianGap;
          }
        }
      }

      results.add(ProductAnalysis(
        productId: product.id!,
        name: product.name,
        salesCount: saleTimes.length,
        medianSalesGapDays: medianGap,
        daysSinceLastSale: daysSinceLast,
        rsi: rsi,
        periodProfit: periodProfit,
        estimatedRemainingStock: estimatedRemaining,
        predictedDaysRemaining: predictedDays,
        restockRatio: restockRatio,
      ));
    }

    return results;
  }

  /// Bidhaa moja yenye kipaumbele cha juu zaidi cha kuonekana kwenye
  /// Home banner (Utabiri > Mtaji Uliokwama), au null kama hakuna
  /// kinachohitaji tahadhari.
  Future<Map<String, dynamic>?> getHomeBannerSignal() async {
    final analysis = await getProductAnalysis();

    // Kipaumbele 1: Utabiri wa stockout (siku <= 2)
    final stockoutRisks = analysis
        .where((a) => a.predictedDaysRemaining != null && a.predictedDaysRemaining! <= 2)
        .toList()
      ..sort((a, b) => a.predictedDaysRemaining!.compareTo(b.predictedDaysRemaining!));
    if (stockoutRisks.isNotEmpty) {
      final p = stockoutRisks.first;
      return {
        'type': 'utabiri',
        'message':
            'Kwa mwendo wa mauzo, ${p.name} itaisha ndani ya siku ${p.predictedDaysRemaining!.ceil()}',
      };
    }

    // Kipaumbele 2 (baadaye): Margin Health — angalia getMarginHealth()
    final marginHealth = await getMarginHealth();
    if (marginHealth != null && marginHealth['dropPercent'] as double >= 15) {
      return {
        'type': 'margin',
        'message':
            'Faida yako (margin) imeshuka kwa asilimia ${(marginHealth['dropPercent'] as double).toStringAsFixed(0)} ukilinganisha na kawaida yako',
      };
    }

    // Kipaumbele 3: RSI / Mtaji Uliokwama (bidhaa yenye mtaji mkubwa zaidi uliozuiliwa)
    final stagnant = analysis.where((a) => a.imesimama && a.estimatedRemainingStock != null).toList();
    if (stagnant.isNotEmpty) {
      // Chagua yenye thamani kubwa zaidi ya mtaji uliozuiliwa
      ProductAnalysis? best;
      double bestValue = 0;
      for (final a in stagnant) {
        final product = await getProducts();
        final match = product.firstWhere((p2) => p2.id == a.productId);
        final value = (a.estimatedRemainingStock ?? 0) * match.lastCostPrice;
        if (value > bestValue) {
          bestValue = value;
          best = a;
        }
      }
      if (best != null && bestValue > 0) {
        return {
          'type': 'rsi',
          'message':
              '${best.name} imekaa muda mrefu zaidi ya kawaida — TSh ${bestValue.toStringAsFixed(0)} ya mtaji imezuiliwa',
        };
      }
    }

    // Kipaumbele 4: Restock vs Sales Mismatch (mtaji unafungwa mapema,
    // au hatari ya kukosa bidhaa)
    final mismatches = analysis.where((a) => a.restockRatio != null).toList();
    for (final a in mismatches) {
      if (a.restockRatio! < 1) {
        return {
          'type': 'restock_mismatch',
          'message':
              'Unanunua mzigo mpya wa ${a.name} mara nyingi kuliko kasi ya mauzo yake',
        };
      }
      if (a.restockRatio! > 1.5) {
        return {
          'type': 'restock_mismatch',
          'message':
              'Unanunua mzigo wa ${a.name} polepole kuliko kasi ya mauzo — hatari ya kukosa bidhaa',
        };
      }
    }

    // Kipaumbele 5: Mwelekeo wa Bajeti (mtaji unayeyuka taratibu)
    final trend = await getBudgetTrend();
    if (trend != null && (trend['percentChange'] as double) <= -20) {
      return {
        'type': 'budget_trend',
        'message':
            'Bajeti ya mzigo imepungua kwa asilimia ${(trend['percentChange'] as double).abs().toStringAsFixed(0)} ukilinganisha na wastani wako wa wiki 4',
      };
    }

    return null; // hakuna kinachohitaji tahadhari — Home inabaki kimya
  }

  // ===================== AWAMU 2: WEEKDAY PATTERN =====================

  /// Linganisha mauzo ya LEO na wastani wa siku hii ya wiki (mfano
  /// Jumatatu zote zilizopita), si wastani wa jumla wa siku zote.
  Future<Map<String, dynamic>?> getWeekdayPattern() async {
    final db = await database;
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1=Jumatatu ... 7=Jumapili

    final rows = await db.rawQuery('''
      SELECT date(timestamp) AS siku, SUM(selling_price * quantity) AS jumla
      FROM sales
      GROUP BY siku
      ORDER BY siku ASC
    ''');

    final sameWeekdayTotals = <double>[];
    double todayTotal = 0;
    final todayStr = now.toIso8601String().substring(0, 10);

    for (final row in rows) {
      final dateStr = row['siku'] as String;
      final date = DateTime.parse(dateStr);
      final jumla = (row['jumla'] as num).toDouble();
      if (dateStr == todayStr) {
        todayTotal = jumla;
      } else if (date.weekday == todayWeekday) {
        sameWeekdayTotals.add(jumla);
      }
    }

    if (sameWeekdayTotals.length < 2) return null; // bado inajifunza

    final avg = sameWeekdayTotals.reduce((a, b) => a + b) / sameWeekdayTotals.length;
    if (avg == 0) return null;

    final percentDiff = ((todayTotal - avg) / avg) * 100;

    return {
      'todayTotal': todayTotal,
      'historicalAverage': avg,
      'percentDiff': percentDiff,
    };
  }

  // ===================== AWAMU 2: MARGIN HEALTH =====================

  Future<Map<String, dynamic>?> getMarginHealth({int recentDays = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: recentDays));
    final cutoffStr = cutoff.toIso8601String();

    final recentRows = await db.rawQuery('''
      SELECT SUM(gross_margin) AS faida, SUM(selling_price * quantity) AS mauzo
      FROM sales WHERE timestamp >= ?
    ''', [cutoffStr]);

    final lifetimeRows = await db.rawQuery('''
      SELECT SUM(gross_margin) AS faida, SUM(selling_price * quantity) AS mauzo
      FROM sales WHERE timestamp < ?
    ''', [cutoffStr]);

    final recentFaida = (recentRows.first['faida'] as num?)?.toDouble() ?? 0;
    final recentMauzo = (recentRows.first['mauzo'] as num?)?.toDouble() ?? 0;
    final lifetimeFaida = (lifetimeRows.first['faida'] as num?)?.toDouble() ?? 0;
    final lifetimeMauzo = (lifetimeRows.first['mauzo'] as num?)?.toDouble() ?? 0;

    if (recentMauzo == 0 || lifetimeMauzo == 0) return null; // hazina data ya kutosha

    final recentMarginPct = (recentFaida / recentMauzo) * 100;
    final lifetimeMarginPct = (lifetimeFaida / lifetimeMauzo) * 100;

    if (lifetimeMarginPct == 0) return null;

    final dropPercent = ((lifetimeMarginPct - recentMarginPct) / lifetimeMarginPct) * 100;

    return {
      'recentMarginPct': recentMarginPct,
      'lifetimeMarginPct': lifetimeMarginPct,
      'dropPercent': dropPercent, // chanya = margin imeshuka
    };
  }

  // ===================== AWAMU 3: MUHTASARI WA JANA / FUNGA DUKA =====================

  Future<Map<String, dynamic>> getMuhtasariWaJana() async {
    final db = await database;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr = yesterday.toIso8601String().substring(0, 10);

    final saleRows = await db.rawQuery('''
      SELECT p.name AS name, s.gross_margin AS gross_margin,
             s.selling_price AS selling_price, s.quantity AS quantity
      FROM sales s JOIN products p ON p.id = s.product_id
      WHERE date(s.timestamp) = ?
    ''', [dateStr]);

    final faida = saleRows.fold<double>(0, (sum, r) => sum + (r['gross_margin'] as num).toDouble());

    final matumiziRows = await db.query('expenses', where: "date(timestamp) = ?", whereArgs: [dateStr]);
    final matumizi = matumiziRows.fold<double>(0, (sum, r) => sum + (r['amount'] as num).toDouble());

    final overhead = await getDailyOverheadForDate(yesterday);
    final bakiHalisi = faida - matumizi - overhead;

    // Bidhaa bora zaidi ya jana kwa faida
    final Map<String, double> profitByProduct = {};
    for (final r in saleRows) {
      final name = r['name'] as String;
      profitByProduct[name] = (profitByProduct[name] ?? 0) + (r['gross_margin'] as num).toDouble();
    }
    String? bora;
    double bestVal = 0;
    profitByProduct.forEach((name, val) {
      if (val > bestVal) {
        bestVal = val;
        bora = name;
      }
    });

    return {
      'date': dateStr,
      'bakiHalisi': bakiHalisi,
      'bidhaaBora': bora,
    };
  }

  Future<Map<String, dynamic>> getFungaDukaSummary() async {
    final mauzo = await getMauzoLeoJumla();
    final faida = await getFaidaLeoJumla();
    final matumizi = await getMatumiziLeoJumla();
    final overhead = await getDailyOverhead();
    return {
      'mauzo': mauzo,
      'faida': faida,
      'matumizi': matumizi,
      'overhead': overhead,
      'bakiHalisi': faida - matumizi - overhead,
    };
  }

  /// Je, Muhtasari wa Jana unapaswa kuonekana leo (bado haujaonyeshwa)?
  Future<bool> shouldShowMuhtasariWaJana() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastShown = await getAppState('muhtasari_last_shown_date');
    return lastShown != todayStr;
  }

  Future<void> markMuhtasariWaJanaShown() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await setAppState('muhtasari_last_shown_date', todayStr);
  }

  // ===================== UCHAMBUZI: PERIOD RANGES (kalenda halisi) =====================

  PeriodRange resolvePeriod(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (key) {
      case 'wiki_hii':
        final start = today.subtract(Duration(days: today.weekday - 1));
        return PeriodRange(start, start.add(const Duration(days: 7)), 'Wiki Hii');
      case 'wiki_iliyopita':
        final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final start = thisWeekStart.subtract(const Duration(days: 7));
        return PeriodRange(start, thisWeekStart, 'Wiki Iliyopita');
      case 'mwezi_huu':
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return PeriodRange(start, end, 'Mwezi Huu');
      case 'mwezi_uliopita':
        final start = DateTime(today.year, today.month - 1, 1);
        final end = DateTime(today.year, today.month, 1);
        return PeriodRange(start, end, 'Mwezi Uliopita');
      case 'mwaka_huu':
        final start = DateTime(today.year, 1, 1);
        final end = DateTime(today.year + 1, 1, 1);
        return PeriodRange(start, end, 'Mwaka Huu');
      default:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return PeriodRange(start, start.add(const Duration(days: 7)), 'Wiki Hii');
    }
  }

  // ===================== UCHAMBUZI: TAB YA BIDHAA =====================

  Future<List<ProductAnalysis>> getBidhaaRanking(PeriodRange period) async {
    final all = await getProductAnalysis(periodStart: period.start);
    final withActivity = all.where((a) => a.salesCount > 0 || a.periodProfit != 0).toList();
    withActivity.sort((a, b) => b.periodProfit.compareTo(a.periodProfit));
    return withActivity;
  }

  // ===================== UCHAMBUZI: TAB YA MAUZO (siku/masaa) =====================

  static const List<Map<String, dynamic>> _timeBuckets = [
    {'label': 'Usiku (22:00-05:59)', 'startHour': 22, 'endHour': 6},
    {'label': 'Asubuhi (06:00-11:59)', 'startHour': 6, 'endHour': 12},
    {'label': 'Mchana (12:00-16:59)', 'startHour': 12, 'endHour': 17},
    {'label': 'Jioni (17:00-21:59)', 'startHour': 17, 'endHour': 22},
  ];

  String _bucketFor(int hour) {
    for (final b in _timeBuckets) {
      final start = b['startHour'] as int;
      final end = b['endHour'] as int;
      if (start < end) {
        if (hour >= start && hour < end) return b['label'] as String;
      } else {
        // bucket inayovuka usiku wa manane (mfano Usiku 22-6)
        if (hour >= start || hour < end) return b['label'] as String;
      }
    }
    return 'Haijulikani';
  }

  Future<List<DayAnalysis>> getSikuRanking(PeriodRange period) async {
    final db = await database;
    final rows = await db.query(
      'sales',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [period.start.toIso8601String(), period.endExclusive.toIso8601String()],
    );

    final Map<String, double> totalPerDay = {};
    final Map<String, Map<String, double>> bucketTotalsPerDay = {};

    for (final r in rows) {
      final ts = DateTime.parse(r['timestamp'] as String);
      final dayKey = ts.toIso8601String().substring(0, 10);
      final amount = (r['selling_price'] as num).toDouble() * (r['quantity'] as num).toDouble();

      totalPerDay[dayKey] = (totalPerDay[dayKey] ?? 0) + amount;

      final bucket = _bucketFor(ts.hour);
      bucketTotalsPerDay.putIfAbsent(dayKey, () => {});
      bucketTotalsPerDay[dayKey]![bucket] = (bucketTotalsPerDay[dayKey]![bucket] ?? 0) + amount;
    }

    final results = <DayAnalysis>[];
    totalPerDay.forEach((dayKey, total) {
      final buckets = bucketTotalsPerDay[dayKey] ?? {};
      String peakBucket = '';
      double peakVal = -1;
      buckets.forEach((label, val) {
        if (val > peakVal) {
          peakVal = val;
          peakBucket = label;
        }
      });
      results.add(DayAnalysis(
        date: DateTime.parse(dayKey),
        totalSales: total,
        peakBucketLabel: peakBucket,
      ));
    });

    results.sort((a, b) => b.totalSales.compareTo(a.totalSales));
    return results;
  }

  /// Siku ya Dhahabu: siku ya wiki (Jumatatu..Jumapili) yenye wastani
  /// mkubwa zaidi wa mauzo, kihistoria (maisha yote, si kipindi kimoja).
  Future<Map<String, dynamic>?> getSikuYaDhahabu() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT date(timestamp) AS siku, SUM(selling_price * quantity) AS jumla
      FROM sales GROUP BY siku
    ''');

    const wiki = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
    final Map<int, List<double>> byWeekday = {};

    for (final r in rows) {
      final date = DateTime.parse(r['siku'] as String);
      final jumla = (r['jumla'] as num).toDouble();
      byWeekday.putIfAbsent(date.weekday, () => []).add(jumla);
    }

    if (byWeekday.isEmpty) return null;

    int? bestWeekday;
    double bestAvg = -1;
    byWeekday.forEach((weekday, totals) {
      final avg = totals.reduce((a, b) => a + b) / totals.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestWeekday = weekday;
      }
    });

    if (bestWeekday == null) return null;

    return {
      'siku': wiki[bestWeekday! - 1],
      'wastani': bestAvg,
    };
  }

  /// Masaa ya Dhahabu: kipindi cha muda (bucket) chenye asilimia kubwa
  /// zaidi ya mauzo yote, kihistoria.
  Future<Map<String, dynamic>?> getMasaaYaDhahabu() async {
    final db = await database;
    final rows = await db.query('sales');
    if (rows.isEmpty) return null;

    final Map<String, double> bucketTotals = {};
    double grandTotal = 0;

    for (final r in rows) {
      final ts = DateTime.parse(r['timestamp'] as String);
      final amount = (r['selling_price'] as num).toDouble() * (r['quantity'] as num).toDouble();
      final bucket = _bucketFor(ts.hour);
      bucketTotals[bucket] = (bucketTotals[bucket] ?? 0) + amount;
      grandTotal += amount;
    }

    if (grandTotal == 0) return null;

    String bestBucket = '';
    double bestVal = -1;
    bucketTotals.forEach((label, val) {
      if (val > bestVal) {
        bestVal = val;
        bestBucket = label;
      }
    });

    return {
      'bucket': bestBucket,
      'percent': (bestVal / grandTotal) * 100,
    };
  }
}
