import 'line_item_model.dart';

enum TaxMode { exclusive, inclusive }

enum QuoteStatus { draft, sent, accepted }

class Quote {
  String clientName;
  String clientAddress;
  String reference;
  List<LineItem> items;
  TaxMode taxMode;
  QuoteStatus status;
  String currencySymbol;

  Quote({
    this.clientName = '',
    this.clientAddress = '',
    this.reference = '',
    List<LineItem>? items,
    this.taxMode = TaxMode.exclusive,
    this.status = QuoteStatus.draft,
    this.currencySymbol = '₹',
  }) : items = items ?? [LineItem()];

  Map<String, dynamic> toJson() => {
    'clientName': clientName,
    'clientAddress': clientAddress,
    'reference': reference,
    'items': items.map((e) => e.toJson()).toList(),
    'taxMode': taxMode.name,
    'status': status.name,
    'currencySymbol': currencySymbol,
  };
}
