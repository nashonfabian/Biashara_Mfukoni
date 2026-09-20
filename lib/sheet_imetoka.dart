import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

enum ImetokaMode { mzigo, matumizi }

enum DivideMode { bulk, single }

/// Pesa Imetoka: matawi mawili — Nunua Mzigo (restock, huzalisha/husasisha
/// bei ya mtaji) na Matumizi (nauli, chakula, n.k. — chanzo cha Erosion
/// Alert ya Pillar 2 na Baki Halisi ya Pillar 3).
class SheetImetokaWidget extends StatefulWidget {
  const SheetImetokaWidget({super.key});

  @override
  State<SheetImetokaWidget> createState() => _SheetImetokaWidgetState();
}

class _SheetImetokaWidgetState extends State<SheetImetokaWidget> {
  static const Color kPrimary = Color(0xFF4B39EF);
  static const Color kInactive = Color(0xFFB2B1B8);

  ImetokaMode _mode = ImetokaMode.mzigo;
  DivideMode _divideMode = DivideMode.bulk;

  final _searchController = TextEditingController();
  final _totalController = TextEditingController(); // "Jumla ya pesa iliyotoka"
  final _quantityController = TextEditingController(); // "Kiasi & Idadi"

  Timer? _debounce;
  ProductRow? _selectedProduct;

  late Future<List<ProductRow>> _productResults;
  late Future<List<String>> _expenseResults;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productResults = DbHelper.instance.searchProducts('');
    _expenseResults = DbHelper.instance.searchExpenseDescriptions('');
    _totalController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _totalController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _selectedProduct = null;
        if (_mode == ImetokaMode.mzigo) {
          _productResults = DbHelper.instance.searchProducts(value);
        } else {
          _expenseResults = DbHelper.instance.searchExpenseDescriptions(value);
        }
      });
    });
  }

  void _switchMode(ImetokaMode mode) {
    setState(() {
      _mode = mode;
      _selectedProduct = null;
      _searchController.clear();
      _totalController.clear();
      _quantityController.clear();
      if (mode == ImetokaMode.mzigo) {
        _productResults = DbHelper.instance.searchProducts('');
      } else {
        _expenseResults = DbHelper.instance.searchExpenseDescriptions('');
      }
    });
  }

  double get _bePerUnit {
    final total = double.tryParse(_totalController.text) ?? 0;
    final qty = double.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) return 0;
    return _divideMode == DivideMode.bulk ? total / qty : total;
  }

  Future<void> _thibitishaUnunuzi() async {
    final qty = double.tryParse(_quantityController.text);

    if (_mode == ImetokaMode.mzigo) {
      final productName = _selectedProduct?.name ?? _searchController.text.trim();
      if (productName.isEmpty || qty == null || qty <= 0 || _bePerUnit <= 0) {
        _onyeshaKosa('Chagua/andika bidhaa, jaza jumla na idadi kwa usahihi.');
        return;
      }
      setState(() => _isSaving = true);

      final productId = await DbHelper.instance.getOrCreateProduct(productName);
      await DbHelper.instance.rekodiUnunuziMzigo(
        productId: productId,
        quantity: qty,
        unitCostPrice: _bePerUnit,
      );
    } else {
      final amount = double.tryParse(_totalController.text);
      if (amount == null || amount <= 0) {
        _onyeshaKosa('Jaza kiasi cha matumizi.');
        return;
      }
      setState(() => _isSaving = true);
      await DbHelper.instance.rekodiMatumizi(
        amount: amount,
        description: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  void _onyeshaKosa(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),

              // ===== TOGGLE: Nunua mzigo / Matumizi =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabButton('Nunua mzigo', ImetokaMode.mzigo),
                  const SizedBox(width: 12),
                  _tabButton('Matumizi', ImetokaMode.matumizi),
                ],
              ),
              const SizedBox(height: 16),

              // ===== SEARCH BAR =====
              TextFormField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _mode == ImetokaMode.mzigo
                      ? 'Tafuta & Ongeza bidhaa'
                      : 'Tafuta au andika maelezo ya matumizi',
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFB6B1B1), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.inter(letterSpacing: 0.0),
              ),
              const SizedBox(height: 10),

              // ===== CHIPS ZA MATOKEO =====
              _mode == ImetokaMode.mzigo
                  ? FutureBuilder<List<ProductRow>>(
                      future: _productResults,
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [];
                        return _chipsRow(
                          results.map((p) => p.name).toList(),
                          onTap: (i) => setState(() => _selectedProduct = results[i]),
                          selectedLabel: _selectedProduct?.name,
                        );
                      },
                    )
                  : FutureBuilder<List<String>>(
                      future: _expenseResults,
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [];
                        return _chipsRow(
                          results,
                          onTap: (i) => setState(() => _searchController.text = results[i]),
                          selectedLabel: null,
                        );
                      },
                    ),

              const SizedBox(height: 16),

              // ===== SEHEMU YA BEI / MATUMIZI =====
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_mode == ImetokaMode.mzigo) ...[
                      Text(
                        'Aina ya ununuzi',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _divideButton('Auto divide (bulk)', DivideMode.bulk),
                          const SizedBox(width: 12),
                          _divideButton('Single unit', DivideMode.single),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    _amountFields(),
                    const SizedBox(height: 10),
                    if (_mode == ImetokaMode.mzigo)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFAF0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'TSh ${_bePerUnit.toStringAsFixed(0)} kwa kitengo 1',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF0A5C2F),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _thibitishaUnunuzi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _mode == ImetokaMode.mzigo
                                    ? 'Thibitisha ununuzi'
                                    : 'Thibitisha matumizi',
                                style: GoogleFonts.interTight(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, ImetokaMode mode) {
    final active = _mode == mode;
    return ElevatedButton(
      onPressed: () => _switchMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? kPrimary : kInactive,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.interTight(color: Colors.white)),
    );
  }

  Widget _divideButton(String label, DivideMode mode) {
    final active = _divideMode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => _divideMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? kPrimary : kInactive,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.interTight(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _chipsRow(List<String> items,
      {required void Function(int) onTap, String? selectedLabel}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Hakuna kilichopatikana bado.',
            style: GoogleFonts.inter(color: Colors.grey)),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final isSelected = items[i] == selectedLabel;
        return InkWell(
          onTap: () => onTap(i),
          child: Container(
            width: 100,
            height: 70,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? kPrimary.withOpacity(0.15) : Colors.white,
              border: Border.all(color: isSelected ? kPrimary : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(items[i],
                textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13)),
          ),
        );
      }),
    );
  }

  Widget _amountFields() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _mode == ImetokaMode.mzigo
                ? (_divideMode == DivideMode.bulk
                    ? 'Jumla ya pesa iliyotoka'
                    : 'Bei ya kitengo kimoja')
                : 'Kiasi cha matumizi',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _totalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            hintText: '1000',
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF948B8B), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_mode == ImetokaMode.mzigo) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Kiasi & Idadi',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              hintText: '5',
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF948B8B), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
