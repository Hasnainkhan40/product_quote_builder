import 'package:flutter/material.dart';

class LineItem {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController taxCtrl;

  LineItem({
    String name = '',
    int qty = 1,
    double rate = 0.0,
    double discount = 0.0,
    double tax = 0.0,
  }) : nameCtrl = TextEditingController(text: name),
       qtyCtrl = TextEditingController(text: qty.toString()),
       rateCtrl = TextEditingController(text: rate.toStringAsFixed(2)),
       discountCtrl = TextEditingController(text: discount.toStringAsFixed(2)),
       taxCtrl = TextEditingController(text: tax.toStringAsFixed(2));

  Map<String, dynamic> toJson() => {
    'name': nameCtrl.text,
    'qty': int.tryParse(qtyCtrl.text) ?? 0,
    'rate': double.tryParse(rateCtrl.text) ?? 0.0,
    'discount': double.tryParse(discountCtrl.text) ?? 0.0,
    'tax': double.tryParse(taxCtrl.text) ?? 0.0,
  };

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    taxCtrl.dispose();
  }
}
