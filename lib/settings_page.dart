import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color kPrimary = Color(0xFF2952E3);

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _future;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = DbHelper.instance.getFixedCosts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = DbHelper.instance.getFixedCosts();
    });
  }

  Future<void> _ongeza() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza jina na kiasi sahihi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await DbHelper.instance.ongezaGharamaYaKudumu(
      name: name,
      monthlyAmount: amount,
    );
    _nameController.clear();
    _amountController.clear();
    setState(() => _isSaving = false);
    _refresh();
  }

  Future<void> _futa(int id) async {
    await DbHelper.instance.futaGharamaYaKudumu(id);
    _refresh();
  }

  String _tsh(num v) => 'TSh ${v.toStringAsFixed(0)}';

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('kodi') || n.contains('rent')) return Icons.apartment;
    if (n.contains('ulinzi') || n.contains('usalama')) return Icons.shield;
    if (n.contains('mshahara') || n.contains('salary')) return Icons.people;
    if (n.contains('umeme') || n.contains('luku')) return Icons.bolt;
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Gharama za Kudumu',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? [];
          final jumlaMwezi = rows.fold<double>(
            0,
            (sum, r) => sum + (r['monthly_amount'] as num).toDouble(),
          );
          final jumlaSiku = jumlaMwezi / 30;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== MUHTASARI =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUHTASARI WA GHARAMA',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_tsh(jumlaMwezi)} / mwezi',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2A4A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF4D6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.lightbulb,
                              color: Color(0xFFE0A500)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Mzigo wa Siku: ${_tsh(jumlaSiku)} / siku\n',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '(Inakatwa kiotomatiki kwenye Baki Halisi)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== ONGEZA GHARAMA MPYA =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ONGEZA GHARAMA MPYA',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Jina la Gharama',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Kodi ya Duka, Mshahara, Ulinzi...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kPrimary, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Kiasi cha Mwezi (TSh)',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kPrimary, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _ongeza,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'ONGEZA GHARAMA',
                          style: GoogleFonts.interTight(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Orodha ya Gharama Zilizopo',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Hakuna gharama ya kudumu bado.',
                      style: GoogleFonts.inter(color: Colors.grey)),
                )
              else
                ...rows.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECFB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_iconFor(r['name'] as String),
                                color: kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${r['name']} - ${_tsh(r['monthly_amount'] as num)} / mwezi',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFD84343)),
                            onPressed: () => _futa(r['id'] as int),
                          ),
                        ],
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
