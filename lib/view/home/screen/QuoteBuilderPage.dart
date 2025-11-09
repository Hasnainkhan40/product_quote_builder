// QuoteBuilder_Modern.dart
// Modernized UI: blended Neumorphism + Glassmorphism + Material You touches
// Preserves your core logic (LineItem, calculations, save/load). Only presentation changed.

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:product_quote_builder/model/LineItem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteBuilderApp extends StatefulWidget {
  QuoteBuilderApp({Key? key}) : super(key: key);

  @override
  State<QuoteBuilderApp> createState() => _QuoteBuilderAppState();
}

class _QuoteBuilderAppState extends State<QuoteBuilderApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(
      () => _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    final light = base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      cardColor: Colors.white.withOpacity(0.7),
      textTheme: base.textTheme.apply(bodyColor: Colors.black87),
    );

    final dark = base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      cardColor: Colors.white.withOpacity(0.06),
      textTheme: base.textTheme.apply(bodyColor: Colors.white),
    );

    return MaterialApp(
      title: 'Product Quote Builder',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      home: QuoteBuilderPage(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class QuoteBuilderPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const QuoteBuilderPage({
    Key? key,
    required this.onToggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<QuoteBuilderPage> createState() => _QuoteBuilderPageState();
}

class _QuoteBuilderPageState extends State<QuoteBuilderPage>
    with SingleTickerProviderStateMixin {
  final _clientNameCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientRefCtrl = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  bool _taxInclusive = false;
  List<LineItem> items = [];
  String _status = 'Draft';
  bool _pageVisible = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _addItem();
    _loadSavedQuote();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(() => _pageVisible = true),
    );
  }

  Future<void> _loadSavedQuote() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('saved_quote');
    if (raw == null) return;
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      _clientNameCtrl.text = data['clientName'] ?? '';
      _clientAddressCtrl.text = data['clientAddress'] ?? '';
      _clientRefCtrl.text = data['clientRef'] ?? '';
      _status = data['status'] ?? 'Draft';
      _taxInclusive = data['taxInclusive'] ?? false;
      final list = data['items'] as List<dynamic>? ?? [];
      setState(() {
        for (final it in items) it.dispose();
        items = list.map((e) {
          final map = e as Map<String, dynamic>;
          return LineItem(
            name: map['name'] ?? '',
            qty: (map['qty'] ?? 1) as int,
            rate: (map['rate'] ?? 0.0) as double,
            discount: (map['discount'] ?? 0.0) as double,
            tax: (map['tax'] ?? 0.0) as double,
          );
        }).toList();
        if (items.isEmpty) _addItem();
      });
    } catch (_) {}
  }

  Future<void> _saveQuoteLocally() async {
    final sp = await SharedPreferences.getInstance();
    final map = {
      'clientName': _clientNameCtrl.text,
      'clientAddress': _clientAddressCtrl.text,
      'clientRef': _clientRefCtrl.text,
      'status': _status,
      'taxInclusive': _taxInclusive,
      'items': items.map((e) => e.toJson()).toList(),
    };
    await sp.setString('saved_quote', json.encode(map));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quote saved locally')));
  }

  void _addItem() {
    setState(() => items.add(LineItem()));
  }

  void _removeItem(int idx) {
    setState(() {
      items[idx].dispose();
      items.removeAt(idx);
    });
  }

  double _perItemTotal(LineItem item) {
    final qty = int.tryParse(item.qtyCtrl.text) ?? 0;
    final rate = double.tryParse(item.rateCtrl.text) ?? 0.0;
    final discount = double.tryParse(item.discountCtrl.text) ?? 0.0;
    final taxPct = double.tryParse(item.taxCtrl.text) ?? 0.0;
    final base = (rate - discount) * qty;
    if (_taxInclusive) {
      return base;
    } else {
      final taxAmount = base * (taxPct / 100.0);
      return base + taxAmount;
    }
  }

  double _subtotal() {
    double s = 0.0;
    for (final it in items) {
      final qty = int.tryParse(it.qtyCtrl.text) ?? 0;
      final rate = double.tryParse(it.rateCtrl.text) ?? 0.0;
      final discount = double.tryParse(it.discountCtrl.text) ?? 0.0;
      final taxPct = double.tryParse(it.taxCtrl.text) ?? 0.0;
      final base = (rate - discount) * qty;
      if (_taxInclusive) {
        s += base;
      } else {
        final taxAmount = base * (taxPct / 100.0);
        s += base + taxAmount;
      }
    }
    return s;
  }

  double _grandTotal() => _subtotal();

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientRefCtrl.dispose();
    for (final it in items) it.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.withOpacity(0.12)
                    : Colors.black.withOpacity(0.6),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _neumorphicButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-6, -6),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.black12,
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: const Offset(6, 6),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }

  Widget _modernTextField(
    TextEditingController ctrl,
    String label, {
    TextInputType inputType = TextInputType.text,
    IconData? leading,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final focus = FocusScope.of(context).hasFocus;

    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (focus)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: inputType,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: leading != null
                ? Icon(
                    leading,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.8),
                  )
                : null,
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: isLight
                ? Colors.grey.shade100
                : Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemCard(int idx, LineItem it) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Dismissible(
          key: ValueKey(it.hashCode ^ idx),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(idx),
          child: _glassCard(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 640;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _modernTextField(
                              it.nameCtrl,
                              'Product / Service',
                              leading: Icons.edit,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 84,
                            child: _modernTextField(
                              it.qtyCtrl,
                              'Qty',
                              inputType: TextInputType.number,
                              leading: Icons.format_list_numbered,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: _modernTextField(
                              it.rateCtrl,
                              'Rate',
                              inputType: TextInputType.number,
                              leading: Icons.price_check,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: _modernTextField(
                              it.discountCtrl,
                              'Discount',
                              inputType: TextInputType.number,
                              leading: Icons.local_offer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 96,
                            child: _modernTextField(
                              it.taxCtrl,
                              'Tax %',
                              inputType: TextInputType.number,
                              leading: Icons.percent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormatter.format(_perItemTotal(it)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _neumorphicButton(
                                onTap: () => _removeItem(idx),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 6),
                                    Text('Remove'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _modernTextField(
                            it.nameCtrl,
                            'Product / Service',
                            leading: Icons.edit,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _modernTextField(
                                  it.qtyCtrl,
                                  'Qty',
                                  inputType: TextInputType.number,
                                  leading: Icons.format_list_numbered,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _modernTextField(
                                  it.rateCtrl,
                                  'Rate',
                                  inputType: TextInputType.number,
                                  leading: Icons.price_check,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _modernTextField(
                                  it.discountCtrl,
                                  'Discount',
                                  inputType: TextInputType.number,
                                  leading: Icons.local_offer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _modernTextField(
                                  it.taxCtrl,
                                  'Tax %',
                                  inputType: TextInputType.number,
                                  leading: Icons.percent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: ${_currencyFormatter.format(_perItemTotal(it))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeItem(idx),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernDropdown() {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (FocusScope.of(context).hasFocus)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _status,
          items: ['Draft', 'Sent', 'Accepted']
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _status = v ?? 'Draft'),
          decoration: InputDecoration(
            labelText: 'Quote Status',
            labelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: isLight
                ? Colors.grey.shade100
                : Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
          dropdownColor: isLight
              ? Colors.white
              : Colors.grey.shade900.withOpacity(0.98),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: _pageVisible ? 1.0 : 0.0,
      curve: Curves.easeIn,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App header (glass + gradient blur)
                const SizedBox(height: 12),

                // Client Info
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Info',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _modernTextField(
                        _clientNameCtrl,
                        'Client Name',
                        leading: Icons.person,
                      ),
                      const SizedBox(height: 8),
                      _modernTextField(
                        _clientAddressCtrl,
                        'Client Address',
                        leading: Icons.home,
                      ),
                      const SizedBox(height: 8),
                      _modernTextField(
                        _clientRefCtrl,
                        'Reference',
                        leading: Icons.receipt_long,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Header with controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Line Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: _taxInclusive,
                              onChanged: (v) =>
                                  setState(() => _taxInclusive = v),
                            ),
                            const SizedBox(width: 4),
                            const Text('Tax inclusive'),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Item',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                                backgroundColor: const Color(
                                  0xFF6C63FF,
                                ), // Modern purple accent
                                shadowColor: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.4),
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return const Color(0xFF5848E0);
                                      } else if (states.contains(
                                        WidgetState.hovered,
                                      )) {
                                        return const Color(0xFF7D75FF);
                                      }
                                      return const Color(0xFF6C63FF);
                                    }),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items list
                Column(
                  children: List.generate(
                    items.length,
                    (i) => _buildLineItemCard(i, items[i]),
                  ),
                ),

                const SizedBox(height: 12),

                // Totals
                _glassCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      key: ValueKey(_subtotal().toStringAsFixed(2)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(_currencyFormatter.format(_subtotal())),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _currencyFormatter.format(_grandTotal()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _modernDropdown()),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveQuoteLocally,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                            backgroundColor: const Color(
                              0xFF00BFA6,
                            ), // Modern teal accent
                            shadowColor: const Color(
                              0xFF00BFA6,
                            ).withOpacity(0.4),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color(0xFF009E8C);
                              } else if (states.contains(WidgetState.hovered)) {
                                return const Color(0xFF19D1B9);
                              }
                              return const Color(0xFF00BFA6);
                            }),
                          ),
                    ),

                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _status = 'Sent');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quote sent (simulated)'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'Send',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                            backgroundColor: const Color(
                              0xFF2979FF,
                            ), // Modern blue for “Send”
                            shadowColor: const Color(
                              0xFF2979FF,
                            ).withOpacity(0.4),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color(0xFF1E63D1);
                              } else if (states.contains(WidgetState.hovered)) {
                                return const Color(0xFF448AFF);
                              }
                              return const Color(0xFF2979FF);
                            }),
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),

                Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _buildPreviewCard(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernItemTable(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.grey.shade100 : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.04 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== Table Header =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.08),
                  colorScheme.surface.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Description',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: colorScheme.primary.withOpacity(0.95),
                    ),
                  ),
                ),
                _buildHeaderCell(context, 'Qty'),
                _buildHeaderCell(context, 'Rate'),
                _buildHeaderCell(context, 'Tax %'),
                Expanded(
                  child: Text(
                    'Total',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===== Table Body =====
          Column(
            children: List.generate(items.length, (i) {
              final it = items[i];
              final qty = int.tryParse(it.qtyCtrl.text) ?? 0;
              final rate = double.tryParse(it.rateCtrl.text) ?? 0.0;
              final tax = double.tryParse(it.taxCtrl.text) ?? 0.0;
              final total = _perItemTotal(it);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        it.nameCtrl.text.isEmpty ? '—' : it.nameCtrl.text,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    _buildDataCell(context, qty.toString()),
                    _buildDataCell(context, _currencyFormatter.format(rate)),
                    _buildDataCell(context, '${tax.toStringAsFixed(2)}%'),
                    Expanded(
                      child: Text(
                        _currencyFormatter.format(total),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ACME Solutions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('123 Business Road'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quote',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ref: ${_clientRefCtrl.text.isEmpty ? '—' : _clientRefCtrl.text}',
                  ),
                  const SizedBox(height: 6),
                  Text('Date: ${DateFormat.yMMMd().format(DateTime.now())}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Bill To: ${_clientNameCtrl.text}'),
          if (_clientAddressCtrl.text.isNotEmpty) Text(_clientAddressCtrl.text),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _modernItemTable(context),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Subtotal: '),
                    Text(_currencyFormatter.format(_subtotal())),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Grand Total: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currencyFormatter.format(_grandTotal()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(0.15),
              flexibleSpace: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              titleSpacing: 16,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.98, end: 1.03).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Quote Builder',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.9),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create beautiful quotes quickly',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: widget.themeMode == ThemeMode.light
                        ? 'Switch to dark'
                        : 'Switch to light',
                    onPressed: widget.onToggleTheme,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    icon: Icon(
                      widget.themeMode == ThemeMode.light
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 22,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: _buildForm(),
    );
  }
}
