import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'uchambuzi_page.dart';
import 'historia_page.dart';
import 'settings_page.dart';

/// Shell kuu ya app — ina Scaffold MOJA yenye bottom navigation bar
/// inayoshirikiwa na tabs zote nne. Kila tab ni maudhui tu (bila
/// Scaffold/AppBar yake mwenyewe), ili navigation ibaki thabiti.
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _index = 0;

  static const _tabs = [
    HomeTabContent(),
    UchambuziPage(),
    HistoriaPage(),
    SettingsPage(),
  ];

  static const _labels = ['Nyumbani', 'Uchambuzi', 'Historia', 'Mipangilio'];
  static const _icons = [
    Icons.home_rounded,
    Icons.bar_chart_rounded,
    Icons.history_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(4, (i) {
              final active = _index == i;
              final color = active ? const Color(0xFF2952E3) : Colors.grey.shade400;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icons[i], size: 22, color: color),
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
