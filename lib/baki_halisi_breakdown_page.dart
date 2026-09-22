import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class BakiHalisiBreakdownPage extends StatefulWidget {
  const BakiHalisiBreakdownPage({super.key});

  @override
  State<BakiHalisiBreakdownPage> createState() => _BakiHalisiBreakdownPageState();
}

class _BakiHalisiBreakdownPageState extends State<BakiHalisiBreakdownPage> {
  late Future<double> _faidaFuture;
  late Future<double> _matumiziFuture;
  late Future<double> _overheadFuture;
  late Future<double> _bakiFuture;
  late Future<List<Map<String, dynamic>>> _matumiziListFuture;

  @override
  void initState() {
    super.initState();
    _faidaFuture = DbHelper.instance.getFaidaLeoJumla();
    _matumiziFuture = DbHelper.instance.getMatumiziLeoJumla();
    _overheadFuture = DbHelper.instance.getDailyOverhead();
    _bakiFuture = DbHelper.instance.getBakiHalisiLeo();
    _matumiziListFuture = DbHelper.instance.getMatumiziYaLeo();
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
        title: Text(
          'Baki Halisi ya Leo',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<double>(
            future: _bakiFuture,
            builder: (context, snapshot) {
              final v = snapshot.data ?? 0;
              final positive = v >= 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: positive ? const Color(0xFFEAFAF0) : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baki Halisi ya leo',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tsh(v),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: positive
                            ? const Color(0xFF0A5C2F)
                            : const Color(0xFF9B1C1C),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Text('Mchanganuo', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _rowKifedha('Faida ghafi ya leo', _faidaFuture, positive: true),
          _rowKifedha('Matumizi ya leo', _matumiziFuture, positive: false),
          _rowKifedha('Gharama ya kudumu ya siku', _overheadFuture, positive: false),

          const SizedBox(height: 24),
          Text('Matumizi ya leo (orodha)',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _matumiziListFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Hakuna matumizi yaliyoingizwa leo.',
                      style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
              return Column(
                children: rows.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (r['description'] as String?) ?? 'Matumizi',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        Text(
                          '- ${_tsh(r['amount'] as num)}',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9B1C1C)),
                        ),
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

  Widget _rowKifedha(String label, Future<double> future, {required bool positive}) {
    return FutureBuilder<double>(
      future: future,
      builder: (context, snapshot) {
        final v = snapshot.data ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
              Text(
                (positive ? '' : '- ') + _tsh(v),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: positive ? const Color(0xFF0A5C2F) : const Color(0xFF9B1C1C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
