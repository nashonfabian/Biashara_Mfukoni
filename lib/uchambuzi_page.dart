import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class UchambuziPage extends StatefulWidget {
  const UchambuziPage({super.key});

  @override
  State<UchambuziPage> createState() => _UchambuziPageState();
}

class _UchambuziPageState extends State<UchambuziPage> {
  static const Color kPrimary = Color(0xFF2952E3);
  static const Color kGreen = Color(0xFF2FA86A);
  static const Color kAmber = Color(0xFFE0A500);
  static const Color kRed = Color(0xFFD64545);

  String _periodKey = 'wiki_hii';
  int _tab = 0; // 0 = Mauzo, 1 = Bidhaa

  static const _periodOptions = {
    'wiki_hii': 'Wiki Hii',
    'wiki_iliyopita': 'Wiki Iliyopita',
    'mwezi_huu': 'Mwezi Huu',
    'mwezi_uliopita': 'Mwezi Uliopita',
    'mwaka_huu': 'Mwaka Huu',
  };

  late Future<List<DayAnalysis>> _sikuFuture;
  late Future<List<ProductAnalysis>> _bidhaaFuture;
  late Future<Map<String, dynamic>?> _sikuYaDhahabuFuture;
  late Future<Map<String, dynamic>?> _masaaYaDhahabuFuture;
  late Future<List<ProductRow>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _sikuYaDhahabuFuture = DbHelper.instance.getSikuYaDhahabu();
    _masaaYaDhahabuFuture = DbHelper.instance.getMasaaYaDhahabu();
    _productsFuture = DbHelper.instance.getProducts();
  }

  void _loadData() {
    final period = DbHelper.instance.resolvePeriod(_periodKey);
    _sikuFuture = DbHelper.instance.getSikuRanking(period);
    _bidhaaFuture = DbHelper.instance.getBidhaaRanking(period);
  }

  String _tsh(num v) => 'TSh ${v.toStringAsFixed(0)}';

  String _weekdayJina(int weekday) {
    const wiki = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
    return wiki[weekday - 1];
  }

  String _tareheFupi(DateTime d) {
    const miezi = ['', 'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${miezi[d.month]}';
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _periodOptions.entries.map((e) {
              return ListTile(
                title: Text(e.value, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                trailing: _periodKey == e.key ? const Icon(Icons.check, color: kPrimary) : null,
                onTap: () {
                  setState(() {
                    _periodKey = e.key;
                    _loadData();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Uchambuzi wa Duka',
            style: GoogleFonts.inter(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          InkWell(
            onTap: _showPeriodPicker,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 15, color: Color(0xFF4B5563)),
                  const SizedBox(width: 6),
                  Text(_periodOptions[_periodKey]!,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _tabButton('Mauzo', 0)),
              const SizedBox(width: 8),
              Expanded(child: _tabButton('Bidhaa', 1)),
            ],
          ),
          const SizedBox(height: 16),
          _tab == 0 ? _buildMauzoTab() : _buildBidhaaTab(),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  // ===================== TAB: MAUZO =====================

  Widget _buildMauzoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _sikuYaDhahabuFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return _summaryCard(
                    'SIKU YA DHAHABU',
                    data == null ? '—' : data['siku'] as String,
                    data == null ? '' : 'Wastani: ${_tsh(data['wastani'] as double)}',
                    kGreen,
                    const Color(0xFFEAFAF0),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FutureBuilder<List<DayAnalysis>>(
                future: _sikuFuture,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? [];
                  final total = rows.fold<double>(0, (sum, r) => sum + r.totalSales);
                  return _summaryCard(
                    'MAUZO YA KIPINDI',
                    _tsh(total),
                    'Siku ${rows.length}',
                    kAmber,
                    const Color(0xFFFEF3E2),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>?>(
          future: _masaaYaDhahabuFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                border: Border.all(color: const Color(0xFFF0C869)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: kAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masaa ya Dhahabu: ${data['bucket']} (asilimia ${(data['percent'] as double).toStringAsFixed(0)} ya mauzo yote)',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF7A5300)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Text('Ranking ya Siku (${_periodOptions[_periodKey]})',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        FutureBuilder<List<DayAnalysis>>(
          future: _sikuFuture,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Hakuna mauzo kwenye kipindi hiki bado.', style: GoogleFonts.inter(color: Colors.grey)),
              );
            }
            final maxVal = rows.first.totalSales;
            return Column(
              children: List.generate(rows.length, (i) {
                final r = rows[i];
                final borderColor = i == 0 ? kGreen : (i == 1 ? kPrimary : (r.totalSales < maxVal * 0.5 ? kRed : Colors.grey.shade300));
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: borderColor, width: 3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text('#${i + 1}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_weekdayJina(r.date.weekday)} • ${_tareheFupi(r.date)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                            if (r.peakBucketLabel.isNotEmpty)
                              Text('Kilele: ${r.peakBucketLabel}',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text(_tsh(r.totalSales), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  // ===================== TAB: BIDHAA =====================

  Widget _buildBidhaaTab() {
    return FutureBuilder<List<ProductRow>>(
      future: _productsFuture,
      builder: (context, productSnapshot) {
        final products = productSnapshot.data ?? [];
        final costById = {for (final p in products) p.id: p.lastCostPrice};

        return FutureBuilder<List<ProductAnalysis>>(
          future: _bidhaaFuture,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];

            ProductAnalysis? topProfit;
            for (final r in rows) {
              if (topProfit == null || r.periodProfit > topProfit.periodProfit) topProfit = r;
            }

            ProductAnalysis? mostTrapped;
            double trappedValue = 0;
            for (final r in rows) {
              if (r.imesimama && r.estimatedRemainingStock != null) {
                final value = r.estimatedRemainingStock! * (costById[r.productId] ?? 0);
                if (value > trappedValue) {
                  trappedValue = value;
                  mostTrapped = r;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'TOP PROFIT',
                        topProfit?.name ?? '—',
                        topProfit == null ? '' : 'Faida: ${_tsh(topProfit.periodProfit)}',
                        kGreen,
                        const Color(0xFFEAFAF0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        'MTAJI ULIOKWAMA',
                        mostTrapped == null ? 'TSh 0' : _tsh(trappedValue),
                        mostTrapped == null ? '' : '${mostTrapped.name}: hazijauzwa muda mrefu',
                        kAmber,
                        const Color(0xFFFEF3E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Ranking ya Bidhaa (${_periodOptions[_periodKey]})',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Hakuna bidhaa zenye shughuli kwenye kipindi hiki.', style: GoogleFonts.inter(color: Colors.grey)),
                  )
                else
                  Column(
                    children: List.generate(rows.length, (i) {
                      final r = rows[i];
                      final isStagnant = r.imesimama;
                      final borderColor = isStagnant ? kRed : (i == 0 ? kGreen : (i == 1 ? kPrimary : Colors.grey.shade300));
                      String subtitle;
                      if (r.inaJifunza) {
                        subtitle = 'Bado inajifunza mzunguko wake';
                      } else if (isStagnant) {
                        subtitle = '⚠ Haijauzwa muda mrefu kuliko kawaida';
                      } else {
                        subtitle = 'Mauzo ${r.salesCount} • Wastani siku ${r.medianSalesGapDays?.toStringAsFixed(1) ?? "-"}';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isStagnant ? const Color(0xFFFDF2F2) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: borderColor, width: 3)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('#${i + 1}',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text(subtitle,
                                      style: GoogleFonts.inter(
                                          fontSize: 11.5, color: isStagnant ? const Color(0xFF9B1C1C) : Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Text(
                              _tsh(r.periodProfit),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: r.periodProfit > 0 ? const Color(0xFF0A5C2F) : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, String sub, Color textColor, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
              overflow: TextOverflow.ellipsis),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.inter(fontSize: 11, color: textColor), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
