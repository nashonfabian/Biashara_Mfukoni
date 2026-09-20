import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';
import 'sheet_imeingia.dart';
import 'sheet_imetoka.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color kPrimary = Color(0xFF4B39EF);
  static const Color kRed = Color(0xFFCB0319);
  static const Color kTextDark = Color(0xFF070708);

  late Future<List<ProductRow>> _bidhaaFuture;
  late Future<double> _bajetiMzigoFuture;
  late Future<double> _bakiHalisiFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _bidhaaFuture = DbHelper.instance.getProducts();
      _bajetiMzigoFuture = DbHelper.instance.getBajetiYaMzigo();
      _bakiHalisiFuture = DbHelper.instance.getBakiHalisiLeo();
    });
  }

  Future<void> _fungueImeingia() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return GestureDetector(
          excludeFromSemantics: true,
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: const SheetImeingiaWidget(),
          ),
        );
      },
    );
    _refreshAll();
  }

  Future<void> _fungueImetoka() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return GestureDetector(
          excludeFromSemantics: true,
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: const SheetImetokaWidget(),
          ),
        );
      },
    );
    _refreshAll();
  }

  String _tsh(double v) {
    return 'TSh ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: true,
          centerTitle: false,
          elevation: 2,
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.email, color: kTextDark, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    'Biashara Mfukoni',
                    style: GoogleFonts.inter(
                      color: kTextDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.notifications_sharp,
                color: Color(0xFF050C11),
                size: 24,
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0, -1),
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width,
                maxWidth: 600,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Mstari mwembamba wa hali (Bajeti ya Mzigo) =====
                    FutureBuilder<double>(
                      future: _bajetiMzigoFuture,
                      builder: (context, snapshot) {
                        final v = snapshot.data;
                        return Row(
                          children: [
                            Text(
                              'Bajeti salama ya mzigo:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v == null ? '...' : _tsh(v),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2FA86A),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ===== PESA IMEINGIA =====
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _fungueImeingia,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'PESA IMEINGIA',
                          style: GoogleFonts.interTight(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== PESA IMETOKA =====
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _fungueImetoka,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'PESA IMETOKA',
                          style: GoogleFonts.interTight(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== Baki Halisi ya leo (mstari mwembamba chini) =====
                    FutureBuilder<double>(
                      future: _bakiHalisiFuture,
                      builder: (context, snapshot) {
                        final v = snapshot.data;
                        return Center(
                          child: Text(
                            v == null
                                ? ''
                                : 'Faida halisi ya leo: ${_tsh(v)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 8),

                    Text(
                      'Bidhaa zako',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ===== ORODHA YA BIDHAA (kutoka SQLite) =====
                    FutureBuilder<List<ProductRow>>(
                      future: _bidhaaFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(kPrimary),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Hitilafu: ${snapshot.error}'),
                          );
                        }

                        final rows = snapshot.data ?? [];

                        if (rows.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Hakuna bidhaa bado.'),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                row.name,
                                style: GoogleFonts.inter(letterSpacing: 0.0),
                              ),
                              trailing: Text(
                                'Bei ya mtaji: ${_tsh(row.lastCostPrice)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
