class LineItem {
  String name;
  double quantity;
  double rate;
  double discount; // per unit
  double taxPercent;

  LineItem({
    this.name = '',
    this.quantity = 1,
    this.rate = 0.0,
    this.discount = 0.0,
    this.taxPercent = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'rate': rate,
    'discount': discount,
    'taxPercent': taxPercent,
  };

  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(
    name: json['name'] ?? '',
    quantity: (json['quantity'] ?? 1).toDouble(),
    rate: (json['rate'] ?? 0).toDouble(),
    discount: (json['discount'] ?? 0).toDouble(),
    taxPercent: (json['taxPercent'] ?? 0).toDouble(),
  );
}
