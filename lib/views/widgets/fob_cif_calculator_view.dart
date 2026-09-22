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
  // ─── LOCAL STATE ───────────────────────────────────────────────────────────
  double _usdRate = 88.00;
  bool _is40Hc = true;
  double _baseCostInr = 197.00;
  double _profitMarginInr = 10.00;
  String _selectedPortPreset = 'Hai Phong (Vietnam)';
  String _customPortName = 'Hai Phong (Vietnam)';
  double _seaFreightUsd = 350.00;
  double _marineInsuranceInr = 2950.00;

  ProductPrice? _selectedProduct;
  String _searchFilter = '';
  bool _isSyncing = false;
  bool _usdSaved = false; // shows "Saved ✓" flash after manual save

  // Track whether we've already synced from provider's async load
  bool _syncedFromProvider = false;

  late TextEditingController _usdController;
  late TextEditingController _baseCostController;
  late TextEditingController _marginController;
  late TextEditingController _freightController;
  late TextEditingController _insuranceController;
  late TextEditingController _customPortController;
  late TextEditingController _searchController;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _usdController = TextEditingController();
    _baseCostController = TextEditingController();
    _marginController = TextEditingController();
    _freightController = TextEditingController();
    _insuranceController = TextEditingController();
    _customPortController = TextEditingController();
    _searchController = TextEditingController();

    // Pull values from provider (may still be defaults if async hasn't finished)
    _pullFromProvider();
  }

  /// Called each time the provider notifies — this is the KEY FIX for the
  /// USD-rate-resets-on-refresh bug. When BuyerProvider.loadCalculatorSettings()
  /// finishes its async SharedPreferences read and calls notifyListeners(),
  /// didChangeDependencies fires here and we refresh all controllers.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only pull fresh if the provider signals its prefs have loaded
    // We do this once after the first async load completes (detected by usdRate != 88.0 default)
    if (!_syncedFromProvider) {
      _pullFromProvider();
      // If the provider has a non-default USD rate, consider it synced
      if (widget.provider.usdRate != 88.00 ||
          widget.provider.destinationPort != 'Hai Phong (Vietnam)') {
        _syncedFromProvider = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant FobCifCalculatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_syncedFromProvider) {
      _pullFromProvider();
    }
  }

  void _pullFromProvider() {
    final p = widget.provider;
    _usdRate = p.usdRate;
    _is40Hc = p.is40Hc;
    _profitMarginInr = p.profitMarginInr;
    _customPortName = p.destinationPort;
    _selectedPortPreset = p.destinationPort;
    _seaFreightUsd = p.seaFreightUsd;
    _marineInsuranceInr = p.marineInsuranceInr;

    _usdController.text = _usdRate.toStringAsFixed(2);
    _marginController.text = _profitMarginInr.toStringAsFixed(2);
    _freightController.text = _seaFreightUsd.toStringAsFixed(0);
    _insuranceController.text = _marineInsuranceInr.toStringAsFixed(0);
    _customPortController.text = _customPortName;

    // Product selection
    if (widget.provider.prices.isNotEmpty) {
      ProductPrice? matched;
      for (final pp in widget.provider.prices) {
        if (pp.id == p.selectedProductCode) {
          matched = pp;
          break;
        }
      }
      _selectedProduct = matched ?? widget.provider.prices.first;
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
    _searchController.dispose();
    super.dispose();
  }

  // ─── BUSINESS LOGIC ────────────────────────────────────────────────────────
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

  void _applyUsdRate(double rate) {
    setState(() {
      _usdRate = rate;
      _usdController.text = rate.toStringAsFixed(2);
      _usdSaved = true;
      _syncedFromProvider = true;
    });
    widget.provider.saveCalculatorSettings(usdRate: rate, syncToSheet: false);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _usdSaved = false);
    });
  }

  Future<void> _saveAndSyncAllToSheet() async {
    // First flush the typed USD value
    final typedRate = double.tryParse(_usdController.text.trim());
    if (typedRate != null && typedRate > 0) {
      setState(() => _usdRate = typedRate);
    }
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
                  'All inputs saved! USD Rate ₹${_usdRate.toStringAsFixed(2)} is now permanently stored and synced to Google Sheets.',
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
                    const Expanded(
                      flex: 2,
                      child: Text('₹81,493.80', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E))),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text('₹68,773.40', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
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
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF0F766E), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Per-Kg Logistics Impact: 40' HC (24,000 kg) = ₹3.40 / kg  |  20' GP (14,000 kg) = ₹4.91 / kg",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
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

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final calc = _buildCurrentCalculation();
    final prices = widget.provider.prices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════════════
          // TOP HEADER BANNER
          // ══════════════════════════════════════════════════════════════════
          _buildHeaderBanner(calc),

          const SizedBox(height: 20),

          // ══════════════════════════════════════════════════════════════════
          // USD RATE CARD — PROMINENT, ALWAYS VISIBLE
          // ══════════════════════════════════════════════════════════════════
          _buildUsdRateCard(),

          const SizedBox(height: 16),

          // ══════════════════════════════════════════════════════════════════
          // SETTINGS ROW: Container | Product | Destination Port
          // ══════════════════════════════════════════════════════════════════
          _buildSettingsRow(prices),

          const SizedBox(height: 24),

          // ══════════════════════════════════════════════════════════════════
          // LIVE PRICE CARDS: FOB | CFR | CIF  (side by side on wide screens)
          // ══════════════════════════════════════════════════════════════════
          _buildPriceCards(calc),

          const SizedBox(height: 24),

          // ══════════════════════════════════════════════════════════════════
          // STEP-BY-STEP MATH BREAKDOWN
          // ══════════════════════════════════════════════════════════════════
          _buildMathBreakdown(calc),

          const SizedBox(height: 24),

          // ══════════════════════════════════════════════════════════════════
          // FULL PRODUCT MATRIX TABLE
          // ══════════════════════════════════════════════════════════════════
          _buildProductMatrix(prices),
        ],
      ),
    );
  }

  // ─── HEADER BANNER ─────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(ExportPriceCalculation calc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final info = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOB · CFR · CIF Export Price Calculator',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _headerChip(Icons.anchor_rounded, 'Pipavav Port, Gujarat', const Color(0xFFFDE047), const Color(0xFF0F172A)),
                      _headerChip(Icons.location_on_rounded, _customPortName, const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
                      _headerChip(Icons.inventory_2_rounded, _selectedProduct?.id ?? '—', Colors.white.withValues(alpha: 0.2), Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _copyQuotationToClipboard(calc),
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copy Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDE047),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showLogisticsBreakdownDialog,
              icon: const Icon(Icons.list_alt_rounded, size: 15),
              label: const Text('Port Logistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : _saveAndSyncAllToSheet,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 13, height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 15),
              label: Text(_isSyncing ? 'Syncing...' : 'Save & Sync', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Expanded(child: info), const SizedBox(width: 16), buttons],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info, const SizedBox(height: 14), buttons],
          );
        }
      }),
    );
  }

  Widget _headerChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  // ─── USD RATE CARD ─────────────────────────────────────────────────────────
  Widget _buildUsdRateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final rateDisplay = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Today's USD Exchange Rate",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                ),
                const SizedBox(width: 10),
                if (_usdSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Saved!', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'This rate is saved permanently — it will not reset on refresh.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
            const SizedBox(height: 12),
            // Large input field
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('₹', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                const SizedBox(width: 6),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _usdController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '88.00',
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _usdRate = parsed);
                        // Auto-save on each valid keystroke
                        widget.provider.saveCalculatorSettings(usdRate: parsed, syncToSheet: false);
                        setState(() {
                          _usdSaved = true;
                          _syncedFromProvider = true;
                        });
                      }
                    },
                    onEditingComplete: () {
                      final parsed = double.tryParse(_usdController.text.trim());
                      if (parsed != null && parsed > 0) {
                        _applyUsdRate(parsed);
                      }
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                const Text(
                  '/ \$1 USD',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ],
        );

        final quickChips = Column(
          crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Select Rate:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [87.00, 87.50, 88.00, 88.50, 89.00, 89.50, 90.00].map((rate) {
                final isSelected = (_usdRate == rate);
                return InkWell(
                  onTap: () => _applyUsdRate(rate),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD97706) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${rate.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: rateDisplay),
              const SizedBox(width: 24),
              quickChips,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [rateDisplay, const SizedBox(height: 16), quickChips],
          );
        }
      }),
    );
  }

  // ─── SETTINGS ROW ──────────────────────────────────────────────────────────
  Widget _buildSettingsRow(List<ProductPrice> prices) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth >= 900;
      final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(width: cardWidth, child: _buildContainerCard()),
          SizedBox(width: cardWidth, child: _buildProductCard(prices)),
          SizedBox(width: cardWidth, child: _buildPortCard()),
        ],
      );
    });
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildContainerCard() {
    return _buildSettingCard(
      title: 'Container Type',
      icon: Icons.inventory_2_rounded,
      iconBg: const Color(0xFFECFDF5),
      iconColor: const Color(0xFF0F766E),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _containerBtn("40' HC", '24,000 kg', true)),
              const SizedBox(width: 8),
              Expanded(child: _containerBtn("20' GP", '14,000 kg', false)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.anchor_rounded, size: 13, color: Color(0xFF0F766E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Port logistics: ${_is40Hc ? '₹3.40/kg (₹81,493.80 total)' : '₹4.91/kg (₹68,773.40 total)'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showLogisticsBreakdownDialog,
            child: const Text(
              'View all 12 port logistics items →',
              style: TextStyle(fontSize: 11, color: Color(0xFF0F766E), decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _containerBtn(String label, String kg, bool is40) {
    final selected = (_is40Hc == is40);
    return InkWell(
      onTap: () => _onContainerTypeChanged(is40),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
          border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? Colors.white : const Color(0xFF334155))),
            Text(kg,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? const Color(0xFFCCFBF1) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(List<ProductPrice> prices) {
    return _buildSettingCard(
      title: 'Product & Margin',
      icon: Icons.inventory_rounded,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      child: Column(
        children: [
          // Product dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<ProductPrice>(
              isExpanded: true,
              value: _selectedProduct,
              hint: const Text('Select product', style: TextStyle(fontSize: 12)),
              items: prices.map((p) {
                return DropdownMenuItem<ProductPrice>(
                  value: p,
                  child: Text(
                    '${p.id} — ${p.name}',
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  controller: _baseCostController,
                  label: 'Ex-Factory Rate (₹/kg)',
                  hint: '197.00',
                  prefix: '₹',
                  onChanged: (val) {
                    final v = double.tryParse(val);
                    if (v != null && v > 0) setState(() => _baseCostInr = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledField(
                  controller: _marginController,
                  label: 'Profit Margin (₹/kg)',
                  hint: '10.00',
                  prefix: '₹',
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
    );
  }

  Widget _buildPortCard() {
    return _buildSettingCard(
      title: 'Destination & Freight',
      icon: Icons.directions_boat_rounded,
      iconBg: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFD97706),
      child: Column(
        children: [
          // Port preset dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: ExportPriceCalculation.destinationPresets
                      .any((p) => p.displayName == _selectedPortPreset)
                  ? _selectedPortPreset
                  : 'Custom Port',
              items: [
                ...ExportPriceCalculation.destinationPresets.map((preset) {
                  return DropdownMenuItem<String>(
                    value: preset.displayName,
                    child: Text(
                      '${preset.displayName} (\$${(_is40Hc ? preset.freight40HcUsd : preset.freight20GpUsd).toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: 'Custom Port',
                  child: Text('Custom Port...', style: TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (val) {
                if (val != null) _onPortPresetSelected(val);
              },
            ),
          ),
          if (_selectedPortPreset == 'Custom Port') ...[
            const SizedBox(height: 8),
            _labeledField(
              controller: _customPortController,
              label: 'Custom Port Name',
              hint: 'e.g. Shanghai, China',
              onChanged: (val) {
                setState(() => _customPortName = val);
                widget.provider.saveCalculatorSettings(port: val, syncToSheet: false);
              },
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  controller: _freightController,
                  label: 'Sea Freight (USD)',
                  hint: '350',
                  prefix: '\$',
                  onChanged: (val) {
                    final v = double.tryParse(val);
                    if (v != null && v >= 0) {
                      setState(() => _seaFreightUsd = v);
                      widget.provider.saveCalculatorSettings(freight: v, syncToSheet: false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledField(
                  controller: _insuranceController,
                  label: 'Marine Insurance (₹)',
                  hint: '2950',
                  prefix: '₹',
                  onChanged: (val) {
                    final v = double.tryParse(val);
                    if (v != null && v >= 0) {
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
    );
  }

  Widget _labeledField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─── PRICE CARDS ───────────────────────────────────────────────────────────
  Widget _buildPriceCards(ExportPriceCalculation calc) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth >= 900;
      final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: cardWidth,
            child: _priceCard(
              title: 'FOB  PIPAVAV PORT',
              subtitle: 'Free On Board',
              icon: Icons.warehouse_rounded,
              accentColor: const Color(0xFF0F766E),
              bgColor: const Color(0xFFF0FDFA),
              borderColor: const Color(0xFF99F6E4),
              pricePerKg: calc.formattedFobUsdKg,
              pricePerMt: calc.formattedFobUsdMt,
              priceInr: '₹${calc.fobPriceInrPerKg.toStringAsFixed(2)} / kg',
              totalUsd: calc.formattedFobTotalUsd,
              description: 'Ex-factory + profit margin + Pipavav port logistics.',
              isHighlighted: false,
              calc: calc,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _priceCard(
              title: 'CFR  ${_customPortName.toUpperCase()}',
              subtitle: 'Cost & Freight',
              icon: Icons.directions_boat_rounded,
              accentColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              pricePerKg: calc.formattedCfrUsdKg,
              pricePerMt: calc.formattedCfrUsdMt,
              priceInr: '₹${calc.cfrPriceInrPerKg.toStringAsFixed(2)} / kg',
              totalUsd: calc.formattedCfrTotalUsd,
              description: 'FOB Pipavav + sea freight (\$${_seaFreightUsd.toStringAsFixed(0)} + 5% GST).',
              isHighlighted: false,
              calc: calc,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _priceCard(
              title: 'CIF  ${_customPortName.toUpperCase()}',
              subtitle: '🌟 All-Inclusive Buyer Price',
              icon: Icons.verified_rounded,
              accentColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEFCE8),
              borderColor: const Color(0xFFF59E0B),
              pricePerKg: calc.formattedCifUsdKg,
              pricePerMt: calc.formattedCifUsdMt,
              priceInr: '₹${calc.cifPriceInrPerKg.toStringAsFixed(2)} / kg',
              totalUsd: calc.formattedCifTotalUsd,
              description: 'CFR + marine insurance (₹${_marineInsuranceInr.toStringAsFixed(0)}/container).',
              isHighlighted: true,
              calc: calc,
            ),
          ),
        ],
      );
    });
  }

  Widget _priceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required String pricePerKg,
    required String pricePerMt,
    required String priceInr,
    required String totalUsd,
    required String description,
    required bool isHighlighted,
    required ExportPriceCalculation calc,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isHighlighted ? 2.0 : 1.2),
        boxShadow: isHighlighted
            ? [BoxShadow(color: accentColor.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accentColor),
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy quotation',
                icon: Icon(Icons.copy_rounded, size: 16, color: accentColor),
                onPressed: () => _copyQuotationToClipboard(calc),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BIG PRICE
          Text(
            pricePerKg,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isHighlighted ? const Color(0xFF92400E) : const Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const Text('per kilogram', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 8),

          // Per MT and INR row
          Row(
            children: [
              Expanded(
                child: _miniMetric('Per MT', pricePerMt, accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniMetric('In INR', priceInr, const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Container total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Container Total (${_is40Hc ? '40\' HC' : '20\' GP'}):',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                totalUsd,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isHighlighted ? const Color(0xFF92400E) : accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ─── MATH BREAKDOWN ────────────────────────────────────────────────────────
  Widget _buildMathBreakdown(ExportPriceCalculation calc) {
    final steps = [
      _MathStep('Ex-Factory (Base Cost)', '₹${_baseCostInr.toStringAsFixed(2)}/kg', null, const Color(0xFF334155)),
      _MathStep('+ Profit Margin', '₹${_profitMarginInr.toStringAsFixed(2)}/kg', null, const Color(0xFF0F766E)),
      _MathStep('+ Port Logistics (Pipavav)', '₹${calc.portLogisticsPerKgInr.toStringAsFixed(2)}/kg',
          '₹${calc.portLogisticsTotalInr.toStringAsFixed(0)}/cont.', const Color(0xFF0D9488)),
      _MathStep('= FOB Pipavav', '\$${calc.fobPriceUsdPerKg.toStringAsFixed(3)}/kg',
          '₹${calc.fobPriceInrPerKg.toStringAsFixed(2)}/kg', const Color(0xFF0F766E), isBold: true),
      _MathStep('+ Sea Freight', '₹${calc.seaFreightPerKgInr.toStringAsFixed(2)}/kg',
          '\$${_seaFreightUsd.toStringAsFixed(0)} + 5% GST', const Color(0xFF2563EB)),
      _MathStep('= CFR Destination', '\$${calc.cfrPriceUsdPerKg.toStringAsFixed(3)}/kg',
          '₹${calc.cfrPriceInrPerKg.toStringAsFixed(2)}/kg', const Color(0xFF2563EB), isBold: true),
      _MathStep('+ Marine Insurance', '₹${calc.insurancePerKgInr.toStringAsFixed(2)}/kg',
          '₹${_marineInsuranceInr.toStringAsFixed(0)}/cont.', const Color(0xFFD97706)),
      _MathStep('= CIF (Final Buyer Price)', '\$${calc.cifPriceUsdPerKg.toStringAsFixed(3)}/kg',
          '\$${calc.cifPriceUsdPerMt.toStringAsFixed(0)}/MT', const Color(0xFFB45309), isBold: true),
    ];

    return Card(
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.functions_rounded, color: Color(0xFF0F766E), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step-by-Step Price Buildup',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('How each price is calculated from base cost → final CIF buyer price',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Payload: ${calc.containerLabel} (${calc.payloadKg.toStringAsFixed(0)} kg)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: steps.map((step) => _mathPill(step)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mathPill(_MathStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: step.color.withValues(alpha: step.isBold ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: step.color.withValues(alpha: step.isBold ? 0.4 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: step.color)),
          const SizedBox(height: 2),
          Text(step.value,
              style: TextStyle(
                  fontSize: step.isBold ? 15 : 13,
                  fontWeight: step.isBold ? FontWeight.w900 : FontWeight.bold,
                  color: step.color)),
          if (step.subValue != null)
            Text(step.subValue!, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ─── PRODUCT MATRIX TABLE ──────────────────────────────────────────────────
  Widget _buildProductMatrix(List<ProductPrice> prices) {
    final filtered = prices.where((p) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return p.id.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Card(
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Color(0xFF0F766E), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Products — Live Export Price Matrix',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('FOB, CFR, CIF prices auto-update when USD rate or port changes',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products (e.g. White Onion, Garlic, Minced)...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() => _searchFilter = '');
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchFilter = val),
            ),
            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                dataTextStyle: const TextStyle(fontSize: 12),
                columnSpacing: 22,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Grade')),
                  DataColumn(label: Text('₹/kg\n(Ex-Factory)')),
                  DataColumn(label: Text('\$/kg\n(FOB)')),
                  DataColumn(label: Text('\$/kg\n(CFR)')),
                  DataColumn(label: Text('\$/kg\n(CIF)')),
                  DataColumn(label: Text('\$ Total\n(Container CIF)')),
                  DataColumn(label: Text('Quote')),
                ],
                rows: filtered.map((p) {
                  final iCalc = ExportPriceCalculation(
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
                  final isSelected = _selectedProduct?.id == p.id;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      return isSelected ? const Color(0xFFF0FDFA) : null;
                    }),
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p.id,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : const Color(0xFF334155))),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _onProductSelected(p),
                          child: Text(p.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF0F766E) : null)),
                        ),
                      ),
                      DataCell(Text(p.grade, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                      DataCell(Text('₹${p.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(iCalc.formattedFobUsdKg, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E)))),
                      DataCell(Text(iCalc.formattedCfrUsdKg, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(iCalc.formattedCifUsdKg,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        ),
                      ),
                      DataCell(Text(iCalc.formattedCifTotalUsd, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        IconButton(
                          tooltip: 'Copy quote for ${p.name}',
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0F766E)),
                          onPressed: () => _copyQuotationToClipboard(iCalc),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No products match your search.', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple data class for math breakdown steps
class _MathStep {
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final bool isBold;

  const _MathStep(this.label, this.value, this.subValue, this.color, {this.isBold = false});
}
