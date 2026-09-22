import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/export_price_calculation.dart';
import '../../models/product_price.dart';
import '../../providers/buyer_provider.dart';

class FobCifCalculatorView extends StatefulWidget {
  final BuyerProvider provider;

  const FobCifCalculatorView({super.key, required this.provider});

  @override
  State<FobCifCalculatorView> createState() => _FobCifCalculatorViewState();
}

class _FobCifCalculatorViewState extends State<FobCifCalculatorView> {
  // Global & Calculation State
  double _usdRate = 88.00;
  bool _is40Hc = true; // true = 40' HC (24 MT), false = 20' GP (14 MT)
  double _baseCostInr = 197.00;
  double _profitMarginInr = 10.00;
  String _selectedPortPreset = 'Hai Phong (Vietnam)';
  String _customPortName = 'Hai Phong, Vietnam';
  double _seaFreightUsd = 350.00;
  double _marineInsuranceInr = 2950.00;

  ProductPrice? _selectedProduct;
  String _searchFilter = '';

  late TextEditingController _usdController;
  late TextEditingController _baseCostController;
  late TextEditingController _marginController;
  late TextEditingController _freightController;
  late TextEditingController _insuranceController;
  late TextEditingController _customPortController;

  @override
  void initState() {
    super.initState();
    _usdRate = widget.provider.usdRate;
    _is40Hc = widget.provider.is40Hc;
    _profitMarginInr = widget.provider.profitMarginInr;
    _customPortName = widget.provider.destinationPort;
    _selectedPortPreset = widget.provider.destinationPort;
    _seaFreightUsd = widget.provider.seaFreightUsd;
    _marineInsuranceInr = widget.provider.marineInsuranceInr;

    _usdController = TextEditingController(text: _usdRate.toStringAsFixed(2));
    _baseCostController = TextEditingController(text: _baseCostInr.toStringAsFixed(2));
    _marginController = TextEditingController(text: _profitMarginInr.toStringAsFixed(2));
    _freightController = TextEditingController(text: _seaFreightUsd.toStringAsFixed(0));
    _insuranceController = TextEditingController(text: _marineInsuranceInr.toStringAsFixed(0));
    _customPortController = TextEditingController(text: _customPortName);

    // Select matching product by saved code or first available
    ProductPrice? matched;
    for (final p in widget.provider.prices) {
      if (p.id == widget.provider.selectedProductCode) {
        matched = p;
        break;
      }
    }

    if (matched != null) {
      _selectedProduct = matched;
      _baseCostInr = matched.currentPrice;
      _baseCostController.text = _baseCostInr.toStringAsFixed(2);
    } else if (widget.provider.prices.isNotEmpty) {
      _selectedProduct = widget.provider.prices.first;
      _baseCostInr = _selectedProduct!.currentPrice;
      _baseCostController.text = _baseCostInr.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _usdController.dispose();
    _baseCostController.dispose();
    _marginController.dispose();
    _freightController.dispose();
    _insuranceController.dispose();
    _customPortController.dispose();
    super.dispose();
  }

  ExportPriceCalculation _buildCurrentCalculation() {
    return ExportPriceCalculation(
      usdRate: _usdRate,
      is40Hc: _is40Hc,
      productName: _selectedProduct?.name ?? 'White Onion Flakes (Sorted)',
      productGrade: _selectedProduct?.grade ?? 'A-Grade Optical Sorted',
      baseCostInr: _baseCostInr,
      profitMarginInr: _profitMarginInr,
      originPort: 'Pipavav Port, Gujarat, India',
      destinationPort: _customPortName,
      oceanFreightUsd: _seaFreightUsd,
      marineInsuranceInr: _marineInsuranceInr,
    );
  }

  void _onProductSelected(ProductPrice p) {
    setState(() {
      _selectedProduct = p;
      _baseCostInr = p.currentPrice;
      _baseCostController.text = _baseCostInr.toStringAsFixed(2);
    });
    widget.provider.saveCalculatorSettings(productCode: p.id, syncToSheet: false);
  }

  void _onContainerTypeChanged(bool is40) {
    setState(() {
      _is40Hc = is40;
      final matched = ExportPriceCalculation.destinationPresets.firstWhere(
        (preset) => preset.displayName == _selectedPortPreset,
        orElse: () => ExportPriceCalculation.destinationPresets.first,
      );
      _seaFreightUsd = is40 ? matched.freight40HcUsd : matched.freight20GpUsd;
      _freightController.text = _seaFreightUsd.toStringAsFixed(0);
    });
    widget.provider.saveCalculatorSettings(
      is40Hc: is40,
      freight: _seaFreightUsd,
      syncToSheet: false,
    );
  }

  void _onPortPresetSelected(String presetName) {
    setState(() {
      _selectedPortPreset = presetName;
      if (presetName != 'Custom Port') {
        final preset = ExportPriceCalculation.destinationPresets.firstWhere(
          (p) => p.displayName == presetName,
        );
        _customPortName = preset.displayName;
        _customPortController.text = _customPortName;
        _seaFreightUsd = _is40Hc ? preset.freight40HcUsd : preset.freight20GpUsd;
        _freightController.text = _seaFreightUsd.toStringAsFixed(0);
      }
    });
    widget.provider.saveCalculatorSettings(
      port: _customPortName,
      freight: _seaFreightUsd,
      syncToSheet: false,
    );
  }

  bool _isSyncing = false;

  Future<void> _saveAndSyncAllToSheet() async {
    setState(() => _isSyncing = true);
    await widget.provider.saveCalculatorSettings(
      usdRate: _usdRate,
      is40Hc: _is40Hc,
      margin: _profitMarginInr,
      port: _customPortName,
      freight: _seaFreightUsd,
      insurance: _marineInsuranceInr,
      productCode: _selectedProduct?.id,
      syncToSheet: true,
    );
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved! USD Rate ₹${_usdRate.toStringAsFixed(2)} is preserved permanently on refresh and synced to Google Sheets.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _copyQuotationToClipboard(ExportPriceCalculation calc) {
    final quoteText = calc.generateFormalQuote();
    Clipboard.setData(ClipboardData(text: quoteText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Formal Export Quotation copied to clipboard! Ready to paste.'),
          ],
        ),
        backgroundColor: Color(0xFF0F766E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLogisticsBreakdownDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.anchor_rounded, color: Color(0xFF0F766E), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pipavav Port Logistics Charges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Forwarder Quote dated 14-08-2026 (Pipavav Port, Gujarat)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Line Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text("40' HC (24 MT)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)))),
                    Expanded(flex: 2, child: Text("20' GP (14 MT)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ExportPriceCalculation.officialLogisticsItems.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = ExportPriceCalculation.officialLogisticsItems[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(item.note, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${item.amount40Hc.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${item.amount20Gp.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1.5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text('TOTAL PORT LOGISTICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('₹81,493.80', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('₹68,773.40', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0F766E), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Per-Kg Logistics Impact: 40' HC (24,000 kg) = ₹3.40 / kg  |  20' GP (14,000 kg) = ₹4.91 / kg",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = _buildCurrentCalculation();
    final prices = widget.provider.prices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TOP HEADER BANNER ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E4A)], // Deep Teal
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                final headerInfo = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              const Text(
                                'FOB, CFR & CIF Export Price Calculator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE047),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.anchor_rounded, size: 12, color: Color(0xFF0F172A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pipavav Port (Gujarat)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Live Quotation Engine',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Instantly calculate FOB Pipavav, CFR Destination, and CIF Destination export prices with live daily USD exchange rate, verified forwarder port logistics, and 1-click buyer quotations.',
                            style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _copyQuotationToClipboard(calc),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Formal Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDE047),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showLogisticsBreakdownDialog,
                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                      label: const Text('Pipavav Logistics (12 Items)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _saveAndSyncAllToSheet,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: Text(
                        _isSyncing ? 'Syncing...' : 'Save & Sync Sheet',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerInfo),
                      const SizedBox(width: 16),
                      actionButtons,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerInfo,
                      const SizedBox(height: 16),
                      actionButtons,
                    ],
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // ─── SECTION 1: DAILY USD RATE & CONTROLS ────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "1. Daily Currency & Container Controls",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Text(
                        "Change anytime to recalculate all export prices",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid of controls
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 16,
                        children: [
                          // USD Rate Box
                          SizedBox(
                            width: isWide ? 260 : constraints.maxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        "Today's USD Rate (₹ / \$)",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _usdController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    decoration: const InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() => _usdRate = parsed);
                                        widget.provider.saveCalculatorSettings(usdRate: parsed, syncToSheet: false);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  // Quick rate chips
                                  Wrap(
                                    spacing: 6,
                                    children: [87.50, 88.00, 88.50, 89.00].map((rate) {
                                      final isSelected = (_usdRate == rate);
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _usdRate = rate;
                                            _usdController.text = rate.toStringAsFixed(2);
                                          });
                                          widget.provider.saveCalculatorSettings(usdRate: rate, syncToSheet: false);
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFD97706) : Colors.white,
                                            border: Border.all(color: const Color(0xFFD97706)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '₹${rate.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : const Color(0xFF92400E),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: const [
                                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0F766E)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Saved locally (preserved on refresh)',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF0F766E), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Container Selector Box
                          SizedBox(
                            width: isWide ? 280 : constraints.maxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Container Equipment & Payload",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _onContainerTypeChanged(true),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _is40Hc ? const Color(0xFF0F766E) : Colors.white,
                                              border: Border.all(
                                                color: _is40Hc ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "40' High Cube",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: _is40Hc ? Colors.white : const Color(0xFF334155),
                                                  ),
                                                ),
                                                Text(
                                                  "24,000 kg (24 MT)",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _is40Hc ? const Color(0xFFCCFBF1) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _onContainerTypeChanged(false),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: !_is40Hc ? const Color(0xFF0F766E) : Colors.white,
                                              border: Border.all(
                                                color: !_is40Hc ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "20' GP",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: !_is40Hc ? Colors.white : const Color(0xFF334155),
                                                  ),
                                                ),
                                                Text(
                                                  "14,000 kg (14 MT)",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: !_is40Hc ? const Color(0xFFCCFBF1) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Logistics Cost: ${_is40Hc ? '₹3.40 / kg (₹81,493.80)' : '₹4.91 / kg (₹68,773.40)'}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Product Selector Dropdown
                          SizedBox(
                            width: isWide ? 280 : constraints.maxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Select Product (24 Baseline Items)",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<ProductPrice>(
                                      isExpanded: true,
                                      value: _selectedProduct,
                                      hint: const Text('Pick product'),
                                      items: prices.map((p) {
                                        return DropdownMenuItem<ProductPrice>(
                                          value: p,
                                          child: Text(
                                            '${p.id} - ${p.name} (₹${p.currentPrice.toStringAsFixed(0)})',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (p) {
                                        if (p != null) _onProductSelected(p);
                                      },
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _baseCostController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Base Rate (₹/kg)',
                                            labelStyle: TextStyle(fontSize: 11),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          onChanged: (val) {
                                            final v = double.tryParse(val);
                                            if (v != null) setState(() => _baseCostInr = v);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _marginController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Margin (₹/kg)',
                                            labelStyle: TextStyle(fontSize: 11),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          onChanged: (val) {
                                            final v = double.tryParse(val);
                                            if (v != null) {
                                              setState(() => _profitMarginInr = v);
                                              widget.provider.saveCalculatorSettings(margin: v, syncToSheet: false);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Destination Port & Sea Freight Box
                          SizedBox(
                            width: isWide ? 300 : constraints.maxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Destination Port & Ocean Freight",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedPortPreset,
                                      items: [
                                        ...ExportPriceCalculation.destinationPresets.map((preset) {
                                          return DropdownMenuItem<String>(
                                            value: preset.displayName,
                                            child: Text(
                                              '${preset.displayName} (\$${(_is40Hc ? preset.freight40HcUsd : preset.freight20GpUsd).toStringAsFixed(0)})',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                        const DropdownMenuItem<String>(
                                          value: 'Custom Port',
                                          child: Text('Custom Destination Port...', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) _onPortPresetSelected(val);
                                      },
                                    ),
                                  ),
                                  if (_selectedPortPreset == 'Custom Port') ...[
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _customPortController,
                                      decoration: const InputDecoration(
                                        labelText: 'Custom Port Name',
                                        labelStyle: TextStyle(fontSize: 11),
                                        isDense: true,
                                      ),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      onChanged: (val) {
                                        setState(() => _customPortName = val);
                                        widget.provider.saveCalculatorSettings(port: val, syncToSheet: false);
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _freightController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Freight (\$)',
                                            labelStyle: TextStyle(fontSize: 11),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          onChanged: (val) {
                                            final v = double.tryParse(val);
                                            if (v != null) {
                                              setState(() => _seaFreightUsd = v);
                                              widget.provider.saveCalculatorSettings(freight: v, syncToSheet: false);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _insuranceController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Insurance (₹)',
                                            labelStyle: TextStyle(fontSize: 11),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          onChanged: (val) {
                                            final v = double.tryParse(val);
                                            if (v != null) {
                                              setState(() => _marineInsuranceInr = v);
                                              widget.provider.saveCalculatorSettings(insurance: v, syncToSheet: false);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── SECTION 2: LIVE EXPORT PRICE CARDS (FOB / CFR / CIF) ────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              final width = isWide ? (constraints.maxWidth - 36) / 3 : constraints.maxWidth;

              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  // Card 1: FOB Pipavav Port
                  SizedBox(
                    width: width,
                    child: _buildExportPriceCard(
                      title: 'FOB PIPAVAV PORT',
                      badgeText: 'Free On Board',
                      badgeColor: const Color(0xFF0F766E),
                      usdRatePerKg: calc.formattedFobUsdKg,
                      usdRatePerMt: calc.formattedFobUsdMt,
                      totalContainerUsd: calc.formattedFobTotalUsd,
                      inrRatePerKg: '₹${calc.fobPriceInrPerKg.toStringAsFixed(2)} / kg',
                      icon: Icons.warehouse_rounded,
                      accentColor: const Color(0xFF0F766E),
                      cardBg: const Color(0xFFF0FDFA),
                      description: 'Factory base cost + profit margin + local Pipavav port logistics charges.',
                    ),
                  ),

                  // Card 2: CFR Destination Port
                  SizedBox(
                    width: width,
                    child: _buildExportPriceCard(
                      title: 'CFR ${_customPortName.toUpperCase()}',
                      badgeText: 'Cost & Freight',
                      badgeColor: const Color(0xFF2563EB),
                      usdRatePerKg: calc.formattedCfrUsdKg,
                      usdRatePerMt: calc.formattedCfrUsdMt,
                      totalContainerUsd: calc.formattedCfrTotalUsd,
                      inrRatePerKg: '₹${calc.cfrPriceInrPerKg.toStringAsFixed(2)} / kg',
                      icon: Icons.directions_boat_rounded,
                      accentColor: const Color(0xFF2563EB),
                      cardBg: const Color(0xFFEFF6FF),
                      description: 'FOB Pipavav + Ocean Sea Freight (\$${_seaFreightUsd.toStringAsFixed(0)} + 5% GST).',
                    ),
                  ),

                  // Card 3: CIF Destination Port (The Star Metric)
                  SizedBox(
                    width: width,
                    child: _buildExportPriceCard(
                      title: 'CIF ${_customPortName.toUpperCase()}',
                      badgeText: '🌟 ALL INCLUSIVE',
                      badgeColor: const Color(0xFFB45309),
                      usdRatePerKg: calc.formattedCifUsdKg,
                      usdRatePerMt: calc.formattedCifUsdMt,
                      totalContainerUsd: calc.formattedCifTotalUsd,
                      inrRatePerKg: '₹${calc.cifPriceInrPerKg.toStringAsFixed(2)} / kg',
                      icon: Icons.verified_rounded,
                      accentColor: const Color(0xFFD97706),
                      cardBg: const Color(0xFFFEFCE8),
                      isHighlighted: true,
                      description: 'Final buyer price including Marine Transit Cargo Insurance (₹2,950).',
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // ─── SECTION 3: STEP-BY-STEP COST BUILDUP SUMMARY ─────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Color(0xFF0F766E), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Detailed Price Buildup & Math Verification",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Text(
                        "Payload: ${calc.containerLabel} (${calc.payloadKg.toStringAsFixed(0)} kg)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildSummaryMetricPill(
                        label: '1. Base Ex-Factory',
                        value: '₹${_baseCostInr.toStringAsFixed(2)} / kg',
                        subtext: 'Mahuva Factory',
                        color: const Color(0xFF334155),
                      ),
                      _buildSummaryMetricPill(
                        label: '2. Profit Margin',
                        value: '+ ₹${_profitMarginInr.toStringAsFixed(2)} / kg',
                        subtext: 'Target Return',
                        color: const Color(0xFF0F766E),
                      ),
                      _buildSummaryMetricPill(
                        label: '3. Port Logistics',
                        value: '+ ₹${calc.portLogisticsPerKgInr.toStringAsFixed(2)} / kg',
                        subtext: '₹${calc.portLogisticsTotalInr.toStringAsFixed(0)} / cont.',
                        color: const Color(0xFF0D9488),
                      ),
                      _buildSummaryMetricPill(
                        label: '= FOB Pipavav',
                        value: '\$${calc.fobPriceUsdPerKg.toStringAsFixed(3)} / kg',
                        subtext: '₹${calc.fobPriceInrPerKg.toStringAsFixed(2)} / kg',
                        color: const Color(0xFF0F766E),
                        isBold: true,
                      ),
                      _buildSummaryMetricPill(
                        label: '4. Sea Freight',
                        value: '+ ₹${calc.seaFreightPerKgInr.toStringAsFixed(2)} / kg',
                        subtext: '\$${_seaFreightUsd.toStringAsFixed(0)} + 5% GST',
                        color: const Color(0xFF2563EB),
                      ),
                      _buildSummaryMetricPill(
                        label: '= CFR Destination',
                        value: '\$${calc.cfrPriceUsdPerKg.toStringAsFixed(3)} / kg',
                        subtext: '₹${calc.cfrPriceInrPerKg.toStringAsFixed(2)} / kg',
                        color: const Color(0xFF2563EB),
                        isBold: true,
                      ),
                      _buildSummaryMetricPill(
                        label: '5. Marine Insurance',
                        value: '+ ₹${calc.insurancePerKgInr.toStringAsFixed(2)} / kg',
                        subtext: '₹${_marineInsuranceInr.toStringAsFixed(0)} / cont.',
                        color: const Color(0xFFD97706),
                      ),
                      _buildSummaryMetricPill(
                        label: '🌟 Final CIF Destination',
                        value: '\$${calc.cifPriceUsdPerKg.toStringAsFixed(3)} / kg',
                        subtext: '\$${calc.cifPriceUsdPerMt.toStringAsFixed(0)} / MT',
                        color: const Color(0xFFB45309),
                        isBold: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── SECTION 4: 24 BASELINE PRODUCTS EXPORT PRICE MATRIX ────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_chart_rounded, color: Color(0xFF0F766E), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "24 Baseline Products - Live Export Price Matrix",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              "All export rates auto-recalculate based on Today's USD Rate and Destination Port",
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products (e.g. White Onion, Garlic, Minced, Flakes)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _searchFilter = ''),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchFilter = val),
                  ),
                  const SizedBox(height: 14),

                  // Table of 24 products
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                      dataTextStyle: const TextStyle(fontSize: 12),
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Product Name & Form')),
                        DataColumn(label: Text('Grade / Quality')),
                        DataColumn(label: Text('Ex-Factory (₹/kg)')),
                        DataColumn(label: Text('FOB Pipavav (\$/kg)')),
                        DataColumn(label: Text('CFR Port (\$/kg)')),
                        DataColumn(label: Text('CIF Port (\$/kg)')),
                        DataColumn(label: Text('Container CIF (\$)')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: prices.where((p) {
                        if (_searchFilter.isEmpty) return true;
                        final q = _searchFilter.toLowerCase();
                        return p.id.toLowerCase().contains(q) ||
                            p.name.toLowerCase().contains(q) ||
                            p.category.toLowerCase().contains(q);
                      }).map((p) {
                        final itemCalc = ExportPriceCalculation(
                          usdRate: _usdRate,
                          is40Hc: _is40Hc,
                          productName: p.name,
                          productGrade: p.grade,
                          baseCostInr: p.currentPrice,
                          profitMarginInr: _profitMarginInr,
                          originPort: 'Pipavav Port, Gujarat, India',
                          destinationPort: _customPortName,
                          oceanFreightUsd: _seaFreightUsd,
                          marineInsuranceInr: _marineInsuranceInr,
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(p.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                            DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(p.grade, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                            DataCell(Text('₹${p.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(itemCalc.formattedFobUsdKg, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E)))),
                            DataCell(Text(itemCalc.formattedCfrUsdKg, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  itemCalc.formattedCifUsdKg,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                ),
                              ),
                            ),
                            DataCell(Text(itemCalc.formattedCifTotalUsd, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              IconButton(
                                tooltip: 'Copy Quote for ${p.name}',
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0F766E)),
                                onPressed: () => _copyQuotationToClipboard(itemCalc),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPriceCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String usdRatePerKg,
    required String usdRatePerMt,
    required String totalContainerUsd,
    required String inrRatePerKg,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required String description,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFF59E0B) : accentColor.withValues(alpha: 0.3),
          width: isHighlighted ? 2.0 : 1.2,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price per kg
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                usdRatePerKg,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isHighlighted ? const Color(0xFF92400E) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ kg',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Sub metrics
          Row(
            children: [
              Text(
                '$usdRatePerMt / MT',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 8),
              Text(
                '($inrRatePerKg)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Container Total Value:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                totalContainerUsd,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isHighlighted ? const Color(0xFF92400E) : const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricPill({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
