import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db_helper.dart';

/// Fomu inayoonekana MARA MOJA TU kwa kila bidhaa — wakati bidhaa
/// inauzwa kwa mara ya kwanza kabisa. Baada ya hapa, bidhaa hii
/// inakuwa chip ya kudumu.
class AddProductPopupWidget extends StatefulWidget {
  const AddProductPopupWidget({super.key, required this.searchbar});

  final String? searchbar;

  @override
  State<AddProductPopupWidget> createState() => _AddProductPopupWidgetState();
}

class _AddProductPopupWidgetState extends State<AddProductPopupWidget> {
  static const Color kPrimary = Color(0xFF2952E3);

  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  bool _isSaving = false;

  @override
  void dispose() {
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.inter(letterSpacing: 0.0, color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFA39C9C), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kPrimary, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _pakiaMauzo() async {
    final productName = (widget.searchbar ?? '').trim();
    final costPrice = double.tryParse(_costPriceController.text.trim());
    final sellingPrice = double.tryParse(_salePriceController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (productName.isEmpty ||
        costPrice == null ||
        sellingPrice == null ||
        quantity == null ||
        quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali jaza jina, bei zote mbili, na idadi kwa usahihi!'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final productId = await DbHelper.instance.getOrCreateProduct(
      productName,
      costPrice: costPrice,
    );

    await DbHelper.instance.rekodiMauzo(
      productId: productId,
      quantity: quantity,
      sellingPrice: sellingPrice,
      costPriceSnapshot: costPrice,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasName = (widget.searchbar ?? '').trim().isNotEmpty;

    return Center(
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.88,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasName ? widget.searchbar! : 'Bidhaa Mpya',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Umeinunua kwa bei gani? (mara moja tu)',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _costPriceController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Gharama za bidhaa (TZS)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salePriceController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Bei ya mauzo (TZS)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Idadi/kiasi'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _pakiaMauzo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Pakia mauzo', style: GoogleFonts.interTight(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
