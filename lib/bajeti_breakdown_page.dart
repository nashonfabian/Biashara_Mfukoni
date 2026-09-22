import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class BajetiBreakdownPage extends StatefulWidget {
  const BajetiBreakdownPage({super.key});

  @override
  State<BajetiBreakdownPage> createState() => _BajetiBreakdownPageState();
}

class _BajetiBreakdownPageState extends State<BajetiBreakdownPage> {
  static const Color kGreen = Color(0xFF2FA86A);

  late Future<double> _bajetiFuture;
  late Future<List<Map<String, dynamic>>> _mchangoFuture;
  late Future<List<Map<String, dynamic>>> _manunuziFuture;

  @override
  void initState() {
    super.initState();
    _bajetiFuture = DbHelper.instance.getBajetiYaMzigo();
    _mchangoFuture = DbHelper.instance.getMchangoWaBidhaaKwenyeBajeti();
    _manunuziFuture = DbHelper.instance.getManunuziYaKaribuni();
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
          'Bajeti ya Mzigo',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFAF0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bajeti salama ya mzigo mpya',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                FutureBuilder<double>(
                  future: _bajetiFuture,
                  builder: (context, snapshot) {
                    final v = snapshot.data;
                    return Text(
                      v == null ? '...' : _tsh(v),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0A5C2F),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Imechangiwa na mauzo ya:',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mchangoFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Bado hakuna mchango wa mauzo.',
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
                        Text(r['name'] as String,
                            style: GoogleFonts.inter(fontSize: 14)),
                        Text(
                          _tsh(r['jumla'] as num),
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: kGreen),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          Text(
            'Manunuzi ya karibuni:',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _manunuziFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Bado hakuna manunuzi.',
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
                          '${r['name']} (x${r['quantity']})',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        Text(
                          '- ${_tsh(r['jumla'] as num)}',
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
}
