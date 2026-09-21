import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_catalog.dart';

class CatalogDirectoryDialog extends StatefulWidget {
  const CatalogDirectoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const CatalogDirectoryDialog(),
    );
  }

  @override
  State<CatalogDirectoryDialog> createState() => _CatalogDirectoryDialogState();
}

class _CatalogDirectoryDialogState extends State<CatalogDirectoryDialog> {
  String _searchQuery = '';
  String _selectedCategory = 'All (47)';

  @override
  Widget build(BuildContext context) {
    List<CatalogProduct> items = AmarFoodsCatalog.products;

    if (_selectedCategory != 'All (47)') {
      items = items.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      items = items.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.hsnCode.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q)
      ).toList();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 920,
        height: MediaQuery.of(context).size.height * 0.88,
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
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0F766E), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Amar Foods — 47 Export Products & HSN Directory',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF14B8A6)),
                            ),
                            child: const Text(
                              'ITC-HS Master',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Complete export alliums, vegetable powders, spices, seeds & fried onions with official customs codes.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF14B8A6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final text = AmarFoodsCatalog.formatForBuyerMessage();
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Copied full 47-Product HSN Directory to clipboard!'),
                        backgroundColor: Color(0xFF0F766E),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 16),
                  label: const Text('Copy Catalog (Text)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Stats
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by product name, HSN code (e.g. 07122000), or category...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Showing ${items.length} of 47 Items',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AmarFoodsCatalog.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = AmarFoodsCatalog.categories[idx];
                  final isSel = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: const Color(0xFFCCFBF1),
                    checkmarkColor: const Color(0xFF0F766E),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? const Color(0xFF0F766E) : const Color(0xFF475569),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Product Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No products match your search.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final p = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Sr No
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '#${p.srNo}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Product Name & Description
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
                                      ),
                                      if (p.description.isNotEmpty)
                                        Text(
                                          p.description,
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // HSN Code with 1-Click Copy
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag_rounded, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'HSN: ${p.hsnCode}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: p.hsnCode));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Copied HSN ${p.hsnCode} for ${p.name}'),
                                              backgroundColor: const Color(0xFF0F766E),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                              width: 320,
                                            ),
                                          );
                                        },
                                        child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0F766E)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Category Badge
                                SizedBox(
                                  width: 160,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.category,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Standard Packing
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    p.standardPacking,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
