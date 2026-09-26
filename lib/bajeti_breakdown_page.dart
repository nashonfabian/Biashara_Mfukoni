import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class BajetiBreakdownPage extends StatefulWidget {
  const BajetiBreakdownPage({super.key});

  @override
  State<BajetiBreakdownPage> createState() => _BajetiBreakdownPageState();
}

class _BajetiBreakdownPageState extends State<BajetiBreakdownPage> {
  late Future<double> _bajetiFuture;
  late Future<List<Map<String, dynamic>>> _mchangoFuture;
  late Future<List<Map<String, dynamic>>> _manunuziFuture;
  late Future<Map<String, dynamic>?> _trendFuture;
  late Future<List<Map<String, dynamic>>> _perProductFuture;

  @override
  void initState() {
    super.initState();
    _bajetiFuture = DbHelper.instance.getBajetiYaMzigo();
    _mchangoFuture = DbHelper.instance.getMchangoWaBidhaaKwenyeBajeti();
    _manunuziFuture = DbHelper.instance.getManunuziYaKaribuni();
    _trendFuture = DbHelper.instance.getBudgetTrend();
    _perProductFuture = _loadPerProductAllocation();
  }

  Future<List<Map<String, dynamic>>> _loadPerProductAllocation() async {
    final products = await DbHelper.instance.getProducts();
    final results = <Map<String, dynamic>>[];
    for (final p in products) {
      final balance = await DbHelper.instance.getBajetiYaBidhaa(p.id!);
      if (balance != 0) {
        results.add({'name': p.name, 'balance': balance});
      }
    }
    results.sort((a, b) => (b['balance'] as double).compareTo(a['balance'] as double));
    return results;
  }

  String _tsh(num v) => 'TSh ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Bajeti ya Mzigo',
            style: GoogleFonts.inter(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFEAFAF0), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bajeti salama ya mzigo mpya', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                FutureBuilder<double>(
                  future: _bajetiFuture,
                  builder: (context, snapshot) {
                    final v = snapshot.data;
                    return Text(v == null ? '...' : _tsh(v),
                        style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: const Color(0xFF0A5C2F)));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== Mwelekeo wa Bajeti =====
          FutureBuilder<Map<String, dynamic>?>(
            future: _trendFuture,
            builder: (context, snapshot) {
              final trend = snapshot.data;
              if (trend == null) return const SizedBox.shrink();
              final pct = trend['percentChange'] as double;
              final positive = pct >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: positive ? const Color(0xFFEAFAF0) : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(positive ? Icons.trending_up : Icons.trending_down,
                        color: positive ? const Color(0xFF0A5C2F) : const Color(0xFF9B1C1C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mwelekeo: ${positive ? "+" : ""}${pct.toStringAsFixed(0)}% ukilinganisha na wastani wa wiki 4 zilizopita',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: positive ? const Color(0xFF0A5C2F) : const Color(0xFF9B1C1C)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Text('Imechangiwa na mauzo ya:', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mchangoFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Bado hakuna mchango wa mauzo.', style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
              return Column(
                children: rows.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(r['name'] as String, style: GoogleFonts.inter(fontSize: 14))),
                        Text(_tsh(r['jumla'] as num),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2FA86A))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          Text('Bajeti salama kwa kila bidhaa:', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Kiasi kilichochangwa na bidhaa hii ambacho bado hakijatumika kununulia mzigo wake',
              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _perProductFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Bado hakuna data ya kutosha.', style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
              return Column(
                children: rows.map((r) {
                  final balance = r['balance'] as double;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(r['name'] as String, style: GoogleFonts.inter(fontSize: 14))),
                        Text(
                          balance >= 0 ? _tsh(balance) : '- ${_tsh(balance.abs())}',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: balance >= 0 ? const Color(0xFF0A5C2F) : const Color(0xFF9B1C1C)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          Text('Manunuzi ya karibuni:', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _manunuziFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Bado hakuna manunuzi.', style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
              return Column(
                children: rows.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${r['name']} (x${r['quantity']})', style: GoogleFonts.inter(fontSize: 14))),
                        Text('- ${_tsh(r['jumla'] as num)}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF9B1C1C))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
