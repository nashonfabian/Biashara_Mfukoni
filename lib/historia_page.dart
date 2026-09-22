import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class HistoriaPage extends StatefulWidget {
  const HistoriaPage({super.key});

  @override
  State<HistoriaPage> createState() => _HistoriaPageState();
}

class _HistoriaPageState extends State<HistoriaPage> {
  String? _filter; // null = Zote

  late Future<List<ActivityRow>> _future;

  static const Map<String, Color> _dotColor = {
    'mauzo': Color(0xFF2FA86A),
    'manunuzi': Color(0xFF3B82F6),
    'matumizi': Color(0xFFE0524D),
  };

  static const Map<String, String> _label = {
    'mauzo': 'Mauzo',
    'manunuzi': 'Manunuzi ya Mzigo',
    'matumizi': 'Matumizi',
  };

  @override
  void initState() {
    super.initState();
    _future = DbHelper.instance.getActivityLog();
  }

  void _setFilter(String? f) {
    setState(() {
      _filter = f;
      _future = DbHelper.instance.getActivityLog(typeFilter: f);
    });
  }

  String _tsh(double v) {
    final sign = v >= 0 ? '+' : '-';
    return '$sign TSh ${v.abs().toStringAsFixed(0)}';
  }

  String _dateHeading(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    const miezi = [
      '', 'JAN', 'FEB', 'MAC', 'APR', 'MEI', 'JUN',
      'JUL', 'AGO', 'SEP', 'OKT', 'NOV', 'DES'
    ];
    final tarehe = '${d.day} ${miezi[d.month]} ${d.year}';
    if (diff == 0) return 'LEO ($tarehe)';
    if (diff == 1) return 'JANA ($tarehe)';
    return tarehe;
  }

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Historia ya Miamala',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('Zote', null, null),
                const SizedBox(width: 10),
                _filterChip('Mauzo', 'mauzo', _dotColor['mauzo']),
                const SizedBox(width: 10),
                _filterChip('Manunuzi', 'manunuzi', _dotColor['manunuzi']),
                const SizedBox(width: 10),
                _filterChip('Matumizi', 'matumizi', _dotColor['matumizi']),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<ActivityRow>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'Hakuna shughuli bado.',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                // Panga kwa tarehe
                final Map<String, List<ActivityRow>> grouped = {};
                for (final r in rows) {
                  final d = DateTime.parse(r.timestamp);
                  final heading = _dateHeading(d);
                  grouped.putIfAbsent(heading, () => []).add(r);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: grouped.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          entry.key,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...entry.value.map((r) => _activityCard(r)),
                    ];
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, Color? dot) {
    final active = _filter == value;
    return InkWell(
      onTap: () => _setFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (dot?.withOpacity(0.15) ?? Colors.grey.shade200)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? (dot ?? Colors.black87) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(ActivityRow r) {
    final d = DateTime.parse(r.timestamp);
    final qtyLabel = r.quantity != null && r.quantity! > 0
        ? ' (x${r.quantity!.toStringAsFixed(r.quantity! % 1 == 0 ? 0 : 1)})'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _dotColor[r.type],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.name}$qtyLabel',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  _tsh(r.amount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: r.amount >= 0
                        ? const Color(0xFF0A5C2F)
                        : const Color(0xFF9B1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_label[r.type]} • ${_time(d)}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
