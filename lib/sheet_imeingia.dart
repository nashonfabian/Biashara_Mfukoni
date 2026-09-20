import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';
import 'add_product_popup.dart';

class SheetImeingiaWidget extends StatefulWidget {
  const SheetImeingiaWidget({super.key});

  @override
  State<SheetImeingiaWidget> createState() => _SheetImeingiaWidgetState();
}

class _SheetImeingiaWidgetState extends State<SheetImeingiaWidget> {
  static const Color kPrimary = Color(0xFF4B39EF);

  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _sellingPriceController = TextEditingController();

  Timer? _debounce;
  ProductRow? _selectedProduct;
  bool _isSaving = false;

  late Future<List<ProductRow>> _results;

  @override
  void initState() {
    super.initState();
    _results = DbHelper.instance.searchProducts('');
    _qtyController.addListener(() => setState(() {}));
    _sellingPriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _qtyController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _results = DbHelper.instance.searchProducts(value);
      });
    });
  }

  void _refreshResults() {
    setState(() {
      _results = DbHelper.instance.searchProducts(_searchController.text);
    });
  }

  void _selectProduct(ProductRow p) {
    setState(() {
      _selectedProduct = p;
      _qtyController.text = '1';
      _sellingPriceController.clear();
    });
  }

  double get _qty => double.tryParse(_qtyController.text) ?? 0;
  double get _sellingPrice => double.tryParse(_sellingPriceController.text) ?? 0;

  double get _faidaPreview {
    if (_selectedProduct == null) return 0;
    return (_sellingPrice - _selectedProduct!.lastCostPrice) * _qty;
  }

  Future<void> _thibitishaMauzo() async {
    if (_selectedProduct == null || _qty <= 0 || _sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza idadi na bei ya kuuzia kwa usahihi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await DbHelper.instance.rekodiMauzo(
      productId: _selectedProduct!.id!,
      quantity: _qty,
      sellingPrice: _sellingPrice,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _fungueBidhaaMpya() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: AddProductPopupWidget(
            searchbar: _searchController.text,
          ),
        );
      },
    );
    // Bidhaa mpya iliyoundwa ndani ya popup tayari imerekodi mauzo yake
    // yenyewe, hivyo tunafunga sheet hii pia (mauzo yamekamilika).
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF201771),
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
              Text(
                'PESA IMEINGIA',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 14),

              // ===== SEARCH + ADD =====
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Tafuta & ongeza bidhaa',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFD6CECE), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kPrimary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: GoogleFonts.inter(letterSpacing: 0.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _fungueBidhaaMpya,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ===== CHIPS ZA BIDHAA ZILIZOPO =====
              FutureBuilder<List<ProductRow>>(
                future: _results,
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Hakuna bidhaa iliyopatikana. Bofya "+" kuongeza mpya.',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: results.map((p) {
                      final isSelected = _selectedProduct?.id == p.id;
                      return InkWell(
                        onTap: () => _selectProduct(p),
                        child: Container(
                          width: 100,
                          height: 70,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            p.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // ===== FOMU YA MAUZO YA HARAKA (bidhaa iliyopo tayari) =====
              if (_selectedProduct != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProduct!.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Bei ya mtaji: TSh ${_selectedProduct!.lastCostPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Idadi (Qty)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Bei ya Kuuzia (TSh)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _faidaPreview >= 0
                              ? const Color(0xFFEAFAF0)
                              : const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Faida halisi kwa mauzo haya: TSh ${_faidaPreview.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _faidaPreview >= 0
                                ? const Color(0xFF0A5C2F)
                                : const Color(0xFF9B1C1C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _thibitishaMauzo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2FA86A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Pesa Taslimu (Cash Sale)',
                                  style: GoogleFonts.interTight(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 4),
            ],
          ),
        ),
      ),
    );
  }
}
