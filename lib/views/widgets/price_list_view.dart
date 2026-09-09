import 'package:flutter/material.dart';
import '../../models/product_price.dart';
import '../../providers/buyer_provider.dart';
import '../../services/price_pdf_service.dart';

class PriceListView extends StatefulWidget {
  final BuyerProvider provider;

  const PriceListView({super.key, required this.provider});

  @override
  State<PriceListView> createState() => _PriceListViewState();
}

class _PriceListViewState extends State<PriceListView> {
  bool _showHistoryView = false;
  String _selectedHistoryProductFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final prices = p.prices;
    final filtered = p.filteredPrices;
    final history = p.priceHistory;

    final increasedCount = prices.where((x) => x.changeAmount > 0).length;
    final decreasedCount = prices.where((x) => x.changeAmount < 0).length;
    final stableCount = prices.where((x) => x.changeAmount == 0).length;
    final avgPrice = prices.isNotEmpty
        ? (prices.map((x) => x.currentPrice).reduce((a, b) => a + b) / prices.length).toStringAsFixed(0)
        : '0';

    final activeWeekLabel = prices.isNotEmpty && prices.first.validity.isNotEmpty
        ? prices.first.validity
        : 'Week ${DateTime.now().toLocal().toString().split(' ')[0]}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── BANNER HEADER ───────────────────────────────────────────────
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
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1280;

                final headerInfo = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 28),
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
                                'Product Price List & Weekly Quotations',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 4),
                                    Text(
                                      activeWeekLabel.isNotEmpty ? activeWeekLabel : 'Daily Spot Rate',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.currency_rupee_rounded, size: 12, color: Color(0xFF92400E)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Ex-Factory Rate',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Weekly Ex-Factory (Mahuva) price tracking in Indian Rupees (₹ / kg) with automatic Google Sheets history sync and 1-click PDF quotations.',
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
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // PDF Download Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await PricePdfService.downloadOrPrintPriceList(
                            prices: prices,
                            weekLabel: activeWeekLabel,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error generating PDF: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Download PDF Price List', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDE047), // Vibrant Gold
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                    // Update Weekly Prices Button
                    OutlinedButton.icon(
                      onPressed: () => _showWeeklyUpdateDialog(context, p, prices, activeWeekLabel),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text('Update Weekly Prices', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    // Add Product Button
                    OutlinedButton.icon(
                      onPressed: () => _showAddProductDialog(context, p, activeWeekLabel),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCCFBF1),
                        side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    // Sync / Reset 24 Products Button
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Row(
                              children: [
                                Icon(Icons.currency_rupee_rounded, color: Color(0xFF0F766E)),
                                SizedBox(width: 8),
                                Text('Sync 24 Products (₹ / kg)'),
                              ],
                            ),
                            content: const Text(
                              'This will load all 24 official products with Sorted (Export Quality) & Unsorted (Commercial) Flakes across White Onion, Red Onion, Pink Onion, and Garlic in Indian Rupees (₹ / kg) and sync them to your Google Sheet.\n\nDo you want to proceed?',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Sync Now'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await p.resetToDefault20Prices();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Successfully loaded all 24 products in ₹ / kg!'),
                                backgroundColor: Color(0xFF15803D),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.currency_rupee_rounded, size: 15, color: Color(0xFFCCFBF1)),
                      label: const Text('Sync 24 Items (₹)', style: TextStyle(color: Color(0xFFCCFBF1), fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    // Refresh Button
                    IconButton(
                      tooltip: 'Refresh from Google Sheets',
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: () => p.loadPrices(forceRefresh: true),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: headerInfo),
                      const SizedBox(width: 20),
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
          const SizedBox(height: 16),

          // ─── BOLD EX-FACTORY & 7-DAY VALIDITY NOTICE BANNER ───────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Light Amber
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFB45309), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                      children: [
                        TextSpan(
                          text: 'NOTE: ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF78350F)),
                        ),
                        TextSpan(
                          text: 'Due to daily raw material market fluctuations, all prices are quoted on a daily spot basis (Ex-Factory Mahuva in ₹ / kg) and are subject to final reconfirmation at the time of order booking. Customized packaging is available as per buyer requirement.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── STATS CARDS ─────────────────────────────────────────────────
          Row(
            children: [
              _buildStatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF0F766E),
                bgColor: const Color(0xFFF0FDFA),
                title: 'TOTAL PRODUCTS',
                value: '${prices.length}',
                subtitle: 'Ex-Factory catalog',
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                title: 'AVERAGE FACTORY RATE',
                value: '₹$avgPrice',
                subtitle: '₹ / kg Ex-Factory Mahuva',
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                title: 'PRICE MOVEMENTS',
                value: '$increasedCount ↑  $decreasedCount ↓',
                subtitle: '$stableCount products stable',
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                icon: Icons.history_edu_rounded,
                iconColor: const Color(0xFF8B2C69),
                bgColor: const Color(0xFFFDF4FF),
                title: 'HISTORY ARCHIVE',
                value: '${history.length}',
                subtitle: 'Weekly price logs saved',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── VIEW TOGGLE & CATEGORY SELECTOR ─────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;

              final viewToggle = Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn(
                      title: 'Current Price List',
                      icon: Icons.table_chart_outlined,
                      isActive: !_showHistoryView,
                      onTap: () => setState(() => _showHistoryView = false),
                    ),
                    _buildToggleBtn(
                      title: 'Weekly History & Trends (${history.length})',
                      icon: Icons.history_rounded,
                      isActive: _showHistoryView,
                      onTap: () {
                        setState(() => _showHistoryView = true);
                        if (history.isEmpty) p.loadPriceHistory();
                      },
                    ),
                  ],
                ),
              );

              final categoryFilter = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'All',
                  'White Onion',
                  'Red Onion',
                  'Pink Onion',
                  'Garlic',
                ].map((cat) {
                  final isSel = p.priceCategoryFilter.toLowerCase() == cat.toLowerCase();
                  return ChoiceChip(
                    label: Text(
                      cat == 'All' ? 'All (${prices.length})' : cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF0F766E),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                    ),
                    onSelected: (_) => p.setPriceCategoryFilter(cat),
                  );
                }).toList(),
              );

              if (isWide) {
                return Row(
                  children: [
                    viewToggle,
                    if (!_showHistoryView) ...[
                      const Spacer(),
                      categoryFilter,
                    ],
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    viewToggle,
                    if (!_showHistoryView) ...[
                      const SizedBox(height: 12),
                      categoryFilter,
                    ],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 18),

          // ─── MAIN CONTENT: ACTIVE LIST OR HISTORY LOG ────────────────────
          if (_showHistoryView)
            _buildHistoryTable(context, history, prices)
          else
            _buildActivePricesTable(context, p, filtered, activeWeekLabel),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE PRICING TABLE ─────────────────────────────────────────────────
  Widget _buildActivePricesTable(
    BuildContext context,
    BuyerProvider p,
    List<ProductPrice> prices,
    String weekLabel,
  ) {
    if (prices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('No products found matching this category.'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('SR', style: _headerStyle)),
                Expanded(flex: 3, child: Text('PRODUCT NAME & SPEC', style: _headerStyle)),
                Expanded(flex: 2, child: Text('PACKAGING', style: _headerStyle)),
                Expanded(flex: 1, child: Text('MOQ', style: _headerStyle)),
                Expanded(flex: 2, child: Text('EX-FACTORY RATE (₹/KG)', style: _headerStyle)),
                Expanded(flex: 2, child: Text('PREV WEEK', style: _headerStyle)),
                Expanded(flex: 2, child: Text('WEEKLY CHANGE', style: _headerStyle)),
                SizedBox(width: 90, child: Text('ACTION', textAlign: TextAlign.right, style: _headerStyle)),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prices.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = prices[index];
              final isIncreased = item.changeAmount > 0;
              final isDecreased = item.changeAmount < 0;
              final sym = item.currencySymbol.isNotEmpty ? item.currencySymbol : '₹';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                color: index.isEven ? Colors.white : const Color(0xFFFCFDFD),
                child: Row(
                  children: [
                    // Sr
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Product & Category
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(item.category).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(item.category),
                                  ),
                                ),
                              ),
                              if (item.grade.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  item.grade,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Packaging
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.packing.isNotEmpty ? item.packing : '14/20/25 kg Bag',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ),
                    // MOQ
                    Expanded(
                      flex: 1,
                      child: Text(
                        item.moq.isNotEmpty ? item.moq : '1 FCL',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    // Current Price
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.currentPrice > 0 ? '$sym${item.currentPrice.toStringAsFixed(0)}' : 'On Request',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          Text(
                            item.currency,
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    // Prev Week Price
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.prevPrice > 0 ? '$sym${item.prevPrice.toStringAsFixed(0)}' : '-',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    // Weekly Change Trend Badge
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isIncreased
                              ? const Color(0xFFF0FDF4)
                              : (isDecreased ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isIncreased
                                ? const Color(0xFFBBF7D0)
                                : (isDecreased ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isIncreased
                                  ? Icons.arrow_upward_rounded
                                  : (isDecreased ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                              size: 13,
                              color: isIncreased
                                  ? const Color(0xFF16A34A)
                                  : (isDecreased ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isIncreased
                                  ? '+$sym${item.changeAmount.toStringAsFixed(0)} (${item.changePercent})'
                                  : (isDecreased
                                      ? '-$sym${item.changeAmount.abs().toStringAsFixed(0)} (${item.changePercent})'
                                      : 'Stable'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isIncreased
                                    ? const Color(0xFF16A34A)
                                    : (isDecreased ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action: Edit & Delete
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit Product',
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F766E)),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => _showSingleEditDialog(context, p, item, weekLabel),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Delete Product',
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteProduct(context, p, item),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── WEEKLY HISTORY & FLUCTUATIONS TABLE ──────────────────────────────────
  Widget _buildHistoryTable(
    BuildContext context,
    List<PriceHistoryItem> history,
    List<ProductPrice> prices,
  ) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_rounded, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No price history records found yet.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            SizedBox(height: 4),
            Text(
              'When you click "Update Weekly Prices" and save changes, snapshots will be archived here automatically.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final filteredHistory = _selectedHistoryProductFilter == 'All'
        ? history
        : history.where((h) => h.name.toLowerCase().contains(_selectedHistoryProductFilter.toLowerCase())).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: Color(0xFF0F766E), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Historical Weekly Price Snapshots',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                const Text('Filter by Product: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHistoryProductFilter,
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Products')),
                        ...prices.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedHistoryProductFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('RECORDED DATE', style: _headerStyle)),
                Expanded(flex: 2, child: Text('WEEK LABEL', style: _headerStyle)),
                Expanded(flex: 3, child: Text('PRODUCT & GRADE', style: _headerStyle)),
                Expanded(flex: 2, child: Text('PACKING', style: _headerStyle)),
                Expanded(flex: 2, child: Text('PRICE RECORDED', style: _headerStyle)),
                Expanded(flex: 2, child: Text('CHANGE DIFF', style: _headerStyle)),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final h = filteredHistory[index];
              final isPos = h.changeAmount > 0;
              final isNeg = h.changeAmount < 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(h.recordedAt, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                    Expanded(flex: 2, child: Text(h.weekLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)))),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          if (h.grade.isNotEmpty) Text(h.grade, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text(h.packing, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${h.currency.contains('₹') || h.currency.toUpperCase().contains('INR') ? '₹' : (h.currency.contains(r'$') || h.currency.toUpperCase().contains('USD') ? r'$' : '')}${h.price.toStringAsFixed(0)} ${h.currency}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        isPos
                            ? '+${h.currency.contains('₹') || h.currency.toUpperCase().contains('INR') ? '₹' : r'$'}${h.changeAmount.toStringAsFixed(0)} (${h.changePercent})'
                            : (isNeg ? '-${h.currency.contains('₹') || h.currency.toUpperCase().contains('INR') ? '₹' : r'$'}${h.changeAmount.abs().toStringAsFixed(0)} (${h.changePercent})' : '0.0%'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPos ? const Color(0xFF16A34A) : (isNeg ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── WEEKLY BATCH UPDATE DIALOG ──────────────────────────────────────────
  void _showWeeklyUpdateDialog(
    BuildContext context,
    BuyerProvider p,
    List<ProductPrice> currentPrices,
    String currentWeekLabel,
  ) {
    final weekCtrl = TextEditingController(text: currentWeekLabel);
    final controllers = <String, TextEditingController>{};

    for (var prod in currentPrices) {
      controllers[prod.id] = TextEditingController(
        text: prod.currentPrice > 0 ? prod.currentPrice.toStringAsFixed(0) : '',
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 780,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF0F766E), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Update Weekly Ex-Factory Rates (₹ / kg)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Enter new factory rates for each product. Previous rates will automatically be archived.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.currency_rupee_rounded, color: Color(0xFFB45309), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'NOTE: All prices are Ex-Factory rates (Mahuva, Gujarat) and valid for 7 days only.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Week Label & Validity
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weekCtrl,
                            decoration: InputDecoration(
                              labelText: 'Week Identifier / Validity',
                              hintText: 'e.g., Week 37 (08-Sep to 14-Sep 2026)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Products Price Input List
                    Expanded(
                      child: ListView.separated(
                        itemCount: currentPrices.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final prod = currentPrices[idx];
                          final ctrl = controllers[prod.id]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${prod.grade} • ${prod.packing}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Prev: ${prod.currencySymbol.isNotEmpty ? prod.currencySymbol : '₹'}${prod.currentPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 160,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '${prod.currencySymbol.isNotEmpty ? prod.currencySymbol : '₹'} ',
                                      suffixText: prod.currency,
                                      labelText: 'New Rate',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dialog Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final updatedList = <ProductPrice>[];
                            for (var prod in currentPrices) {
                              final ctrlVal = controllers[prod.id]?.text.trim() ?? '';
                              final newPrice = double.tryParse(ctrlVal) ?? prod.currentPrice;
                              updatedList.add(prod.copyWith(
                                currentPrice: newPrice,
                                prevPrice: prod.currentPrice,
                                validity: weekCtrl.text.trim(),
                                lastUpdated: DateTime.now().toLocal().toString().split(' ')[0],
                              ));
                            }

                            Navigator.of(ctx).pop();

                            final success = await p.updateWeeklyPrices(
                              updatedList,
                              weekLabel: weekCtrl.text.trim(),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? '✅ Weekly prices updated and archived to Google Sheets!'
                                      : '⚠️ Updated locally. Saved to offline cache.'),
                                  backgroundColor: const Color(0xFF0F766E),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: const Text('Publish & Save Snapshot', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── SINGLE ITEM EDIT DIALOG ─────────────────────────────────────────────
  void _showSingleEditDialog(
    BuildContext context,
    BuyerProvider p,
    ProductPrice item,
    String weekLabel,
  ) {
    final priceCtrl = TextEditingController(text: item.currentPrice.toStringAsFixed(0));
    final specCtrl = TextEditingController(text: item.grade);
    final packingCtrl = TextEditingController(text: item.packing);
    final moqCtrl = TextEditingController(text: item.moq);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Edit ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (${item.currency})',
                prefixText: '${item.currencySymbol.isNotEmpty ? item.currencySymbol : '₹'} ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specCtrl,
              decoration: const InputDecoration(labelText: 'Grade / Specification'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: packingCtrl,
              decoration: const InputDecoration(labelText: 'Packaging'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moqCtrl,
              decoration: const InputDecoration(labelText: 'MOQ'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text.trim()) ?? item.currentPrice;
              final updated = item.copyWith(
                currentPrice: newPrice,
                prevPrice: item.currentPrice,
                grade: specCtrl.text.trim(),
                packing: packingCtrl.text.trim(),
                moq: moqCtrl.text.trim(),
                lastUpdated: DateTime.now().toLocal().toString().split(' ')[0],
              );
              p.saveProductPrice(updated, weekLabel: weekLabel);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Price for ${item.name} saved and synced to Google Sheet!'),
                  backgroundColor: const Color(0xFF15803D),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── ADD NEW PRODUCT DIALOG ──────────────────────────────────────────────
  void _showAddProductDialog(BuildContext context, BuyerProvider p, String weekLabel) {
    final nameCtrl = TextEditingController();
    String selectedCategory = 'White Onion';
    final specCtrl = TextEditingController(text: 'Export Quality');
    final packingCtrl = TextEditingController(text: '20 kg Bag');
    final moqCtrl = TextEditingController(text: '1000 kg');
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. White Onion Flakes (Sorted)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'White Onion', child: Text('White Onion')),
                    DropdownMenuItem(value: 'Red Onion', child: Text('Red Onion')),
                    DropdownMenuItem(value: 'Pink Onion', child: Text('Pink Onion')),
                    DropdownMenuItem(value: 'Garlic', child: Text('Garlic')),
                    DropdownMenuItem(value: 'Spices', child: Text('Spices')),
                    DropdownMenuItem(value: 'General', child: Text('General')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ex-Factory Rate * (₹ / kg)',
                    prefixText: '₹ ',
                    hintText: 'e.g. 185',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specCtrl,
                  decoration: const InputDecoration(labelText: 'Grade / Specification', hintText: 'e.g. A-Grade (Optical Sorted)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: packingCtrl,
                  decoration: const InputDecoration(labelText: 'Packaging', hintText: 'e.g. 14 kg Bag or 25 kg Bag'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: moqCtrl,
                  decoration: const InputDecoration(labelText: 'MOQ', hintText: 'e.g. 1000 kg'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid product name and rate.')),
                  );
                  return;
                }
                String prefix = 'PRD';
                if (selectedCategory == 'White Onion') prefix = 'WO';
                if (selectedCategory == 'Red Onion') prefix = 'RO';
                if (selectedCategory == 'Pink Onion') prefix = 'PO';
                if (selectedCategory == 'Garlic') prefix = 'GA';
                final newId = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                final newProduct = ProductPrice(
                  id: newId,
                  category: selectedCategory,
                  name: name,
                  grade: specCtrl.text.trim(),
                  packing: packingCtrl.text.trim().isNotEmpty ? packingCtrl.text.trim() : '20 kg Bag',
                  currency: '₹ / kg',
                  currentPrice: price,
                  prevPrice: price,
                  moq: moqCtrl.text.trim().isNotEmpty ? moqCtrl.text.trim() : '1000 kg',
                  validity: weekLabel,
                  lastUpdated: DateTime.now().toLocal().toString().split(' ')[0],
                );
                p.saveProductPrice(newProduct, weekLabel: weekLabel);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Added "$name" and synced to Google Sheet!'),
                    backgroundColor: const Color(0xFF15803D),
                  ),
                );
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONFIRM DELETE PRODUCT DIALOG ───────────────────────────────────────
  void _confirmDeleteProduct(BuildContext context, BuyerProvider p, ProductPrice item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(child: Text('Delete ${item.name}?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${item.name}" from the active price catalog and Google Sheets?\n\nThis will remove it from future quotations.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              p.deleteProductPrice(item.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ Removed "${item.name}" from Google Sheet.'),
                  backgroundColor: const Color(0xFFB91C1C),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static Color _getCategoryColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('white')) return const Color(0xFF0F766E);
    if (lower.contains('pink')) return const Color(0xFFDB2777);
    if (lower.contains('red')) return const Color(0xFFE11D48);
    if (lower.contains('garlic')) return const Color(0xFFD97706);
    if (lower.contains('spice')) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF475569),
    letterSpacing: 0.5,
  );
}
