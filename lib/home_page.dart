import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';
import 'sheet_imeingia.dart';
import 'sheet_imetoka.dart';
import 'bajeti_breakdown_page.dart';
import 'baki_halisi_breakdown_page.dart';

/// Maudhui ya tab ya "Nyumbani" pekee — haina Scaffold/AppBar yake
/// mwenyewe, kwa sababu MainNavShell ndiyo inayotoa Scaffold na
/// bottom navigation bar inayoshirikiwa na tabs zote nne.
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  static const Color kPrimary = Color(0xFF2952E3);
  static const Color kRed = Color(0xFFD64545);
  static const Color kGreen = Color(0xFF2FA86A);

  late Future<double> _bajetiFuture;
  late Future<double> _bakiHalisiFuture;
  late Future<Map<String, dynamic>?> _bannerFuture;

  bool _muhtasariDismissed = false;
  Future<Map<String, dynamic>?>? _muhtasariFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _maybeLoadMuhtasari();
  }

  Future<void> _maybeLoadMuhtasari() async {
    final shouldShow = await DbHelper.instance.shouldShowMuhtasariWaJana();
    if (shouldShow && mounted) {
      setState(() {
        _muhtasariFuture = DbHelper.instance.getMuhtasariWaJana();
      });
    }
  }

  void _refreshAll() {
    setState(() {
      _bajetiFuture = DbHelper.instance.getBajetiYaMzigo();
      _bakiHalisiFuture = DbHelper.instance.getBakiHalisiLeo();
      _bannerFuture = DbHelper.instance.getHomeBannerSignal();
    });
  }

  String _tsh(num v) => 'TSh ${v.toStringAsFixed(0)}';

  Future<void> _fungueImeingia() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const SheetImeingiaWidget(),
      ),
    );
    _refreshAll();
  }

  Future<void> _fungueImetoka() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const SheetImetokaWidget(),
      ),
    );
    _refreshAll();
  }

  Future<void> _fungaDuka() async {
    final summary = await DbHelper.instance.getFungaDukaSummary();
    if (!mounted) return;
    await showModalBottomSheet(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muhtasari wa Kufunga',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _summaryLine('Jumla ya mauzo', summary['mauzo'] as double, positive: true),
            _summaryLine('Faida ghafi', summary['faida'] as double, positive: true),
            _summaryLine('Matumizi', summary['matumizi'] as double, positive: false),
            _summaryLine('Gharama ya kudumu ya siku', summary['overhead'] as double,
                positive: false),
            const Divider(height: 24),
            _summaryLine('Baki Halisi', summary['bakiHalisi'] as double,
                positive: (summary['bakiHalisi'] as double) >= 0, bold: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Sawa', style: GoogleFonts.interTight(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, double value, {required bool positive, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  color: Colors.grey.shade700)),
          Text(
            _tsh(value),
            style: GoogleFonts.inter(
              fontSize: bold ? 17 : 14,
              fontWeight: FontWeight.w700,
              color: positive ? const Color(0xFF0A5C2F) : const Color(0xFF9B1C1C),
            ),
          ),
        ],
      ),
    );
  }

  Color _bannerColor(String type) {
    if (type == 'utabiri' || type == 'margin') return const Color(0xFFD64545);
    return const Color(0xFFE0A500);
  }

  IconData _bannerIcon(String type) {
    switch (type) {
      case 'utabiri':
        return Icons.hourglass_bottom;
      case 'margin':
        return Icons.trending_down;
      case 'restock_mismatch':
        return Icons.sync_problem;
      case 'budget_trend':
        return Icons.show_chart;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Biashara Mfukoni',
                style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            // ===== Muhtasari wa Jana =====
            if (!_muhtasariDismissed && _muhtasariFuture != null)
              FutureBuilder<Map<String, dynamic>?>(
                future: _muhtasariFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null) return const SizedBox.shrink();
                  final bakiHalisi = data['bakiHalisi'] as double;
                  final bora = data['bidhaaBora'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MUHTASARI WA JANA',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3730A3))),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
                                  children: [
                                    const TextSpan(text: 'Baki Halisi: '),
                                    TextSpan(
                                      text: _tsh(bakiHalisi),
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A5C2F)),
                                    ),
                                    if (bora != null) TextSpan(text: ' • Bora zaidi: $bora'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await DbHelper.instance.markMuhtasariWaJanaShown();
                            setState(() => _muhtasariDismissed = true);
                          },
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ===== Banner ya kipaumbele (moja tu) =====
            FutureBuilder<Map<String, dynamic>?>(
              future: _bannerFuture,
              builder: (context, snapshot) {
                final signal = snapshot.data;
                if (signal == null) return const SizedBox.shrink();
                final type = signal['type'] as String;
                final color = _bannerColor(type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    border: Border.all(color: color.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(_bannerIcon(type), color: color, size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          signal['message'] as String,
                          style: GoogleFonts.inter(fontSize: 12.5, color: color.withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ===== Bajeti ya Mzigo (bofya kuona zaidi) =====
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BajetiBreakdownPage()),
                );
                _refreshAll();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFAF0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bajeti salama ya mzigo mpya',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          FutureBuilder<double>(
                            future: _bajetiFuture,
                            builder: (context, snapshot) {
                              final v = snapshot.data;
                              return Text(
                                v == null ? '...' : _tsh(v),
                                style: GoogleFonts.inter(
                                    fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0A5C2F)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF0A5C2F)),
                  ],
                ),
              ),
            ),

            // ===== Vitufe viwili vikuu =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fungueImeingia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_down, size: 22),
                    const SizedBox(width: 8),
                    Text('PESA IMEINGIA',
                        style: GoogleFonts.interTight(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fungueImetoka,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_up, size: 22),
                    const SizedBox(width: 8),
                    Text('PESA IMETOKA',
                        style: GoogleFonts.interTight(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Baki Halisi ya leo (bofya kuona zaidi) =====
            Center(
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BakiHalisiBreakdownPage()),
                  );
                  _refreshAll();
                },
                child: FutureBuilder<double>(
                  future: _bakiHalisiFuture,
                  builder: (context, snapshot) {
                    final v = snapshot.data;
                    return Text(
                      v == null ? '' : 'Faida halisi ya leo: ${_tsh(v)}  ›',
                      style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey.shade600),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ===== Funga Duka =====
            OutlinedButton.icon(
              onPressed: _fungaDuka,
              icon: const Icon(Icons.meeting_room_outlined, size: 18),
              label: Text('Funga Duka — Ona Muhtasari',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
