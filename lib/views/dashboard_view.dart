import 'package:flutter/material.dart';
import '../models/buyer.dart';
import '../providers/buyer_provider.dart';
import '../services/url_utils.dart';
import 'buyer_dialog.dart';
import 'config_dialog.dart';
import 'widgets/daily_work_area_view.dart';
import 'widgets/email_work_section.dart';

enum DisplayLayout { table, kanban }

class DashboardView extends StatefulWidget {
  final BuyerProvider provider;

  const DashboardView({super.key, required this.provider});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      widget.provider.loadMoreCategory('first_emails');
      widget.provider.loadMoreCategory('all_followup_queue');
      widget.provider.loadMoreCategory('filtered');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------------
            // 1. TOP EXECUTIVE NAVIGATION HEADER BAR (Matching All Screenshots)
            // ------------------------------------------------------------------
            _buildVibrantExecutiveHeader(context, p),

            // ------------------------------------------------------------------
            // 2. MAIN CONTENT AREA (Switches between Daily Work Area, All Importers, & Analytics)
            // ------------------------------------------------------------------
            Expanded(
              child: SelectionArea(
                child: p.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2C69)))
                    : p.activeTab == MainTab.dailyWorkArea
                        ? DailyWorkAreaView(provider: p)
                        : p.activeTab == MainTab.analytics
                            ? _buildAnalyticsView(p)
                            : _buildAllImportersView(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Executive Header Bar matching ALL 5 Screenshots
  Widget _buildVibrantExecutiveHeader(BuildContext context, BuyerProvider p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF8B2C69), // Deep Purple
      ),
      child: Row(
        children: [
          // Logo Icon Square
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),

          // Title & Tagline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'AMAR FOODS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009647),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BUYER CRM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Dehydrated Onion, Garlic & Food Products Importer Follow-Up Tracker',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Navigation Segmented Tabs Bar (Matching Screenshots!)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildNavTab(
                  label: 'Daily Work Area',
                  icon: Icons.calendar_today_rounded,
                  isActive: p.activeTab == MainTab.dailyWorkArea,
                  onTap: () => p.setActiveTab(MainTab.dailyWorkArea),
                ),
                _buildNavTab(
                  label: 'All Importers (${p.totalBuyersCount})',
                  icon: Icons.people_outline_rounded,
                  isActive: p.activeTab == MainTab.allImporters,
                  onTap: () => p.setActiveTab(MainTab.allImporters),
                ),
                _buildNavTab(
                  label: 'Analytics',
                  icon: Icons.bar_chart_rounded,
                  isActive: p.activeTab == MainTab.analytics,
                  onTap: () => p.setActiveTab(MainTab.analytics),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Settings Button
          IconButton(
            tooltip: 'Sheet Configuration',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ConfigDialog(
                  currentUrl: p.scriptUrl,
                  onSaveUrl: (url) => p.setScriptUrl(url),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Green + Add Buyer Button (Matching Screenshots!)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009647),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BuyerDialog(
                  onSave: (buyer) => p.saveBuyer(buyer),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Add Buyer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF8B2C69) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF8B2C69) : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// All Importers View — Today's Email Work section + Search + Metric Cards + Full Table
  Widget _buildAllImportersView(BuyerProvider p) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── SECTION 1: TODAY'S EMAIL WORK section (reused shared widget, Sheet 5 data) ──
        SliverToBoxAdapter(
          child: SizedBox(
            height: 910,
            child: EmailWorkSection(provider: p),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── SECTION 2: Divider Badge ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE2E8F0),
                    thickness: 1.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2C69),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B2C69).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Text(
                        'ALL IMPORTERS DATABASE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE2E8F0),
                    thickness: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── SECTION 3: Search Box + Metric Cards ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSearchBox(p),
              const SizedBox(height: 20),
              _buildSixExecutiveMetricCards(p),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── SECTION 4: Full Buyer Table (All Importers) ──
        _buildAllImportersTable(p),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Full buyer table — all records from Sheet 5
  Widget _buildAllImportersTable(BuyerProvider p) {
    final buyers = p.paginatedFilteredBuyers;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Table header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                  left: BorderSide(color: Color(0xFFE2E8F0)),
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  // Header row with filter dropdowns
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.table_rows_rounded, color: Color(0xFF8B2C69), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'All Importers',
                          style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${p.filteredBuyers.length} records',
                            style: const TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        // Reply filter
                        _buildDropdown(
                          value: p.replyFilter,
                          hint: 'Reply',
                          items: [
                            'All Replies',
                            'Pending',
                            'Yes',
                            'Hold',
                            'No Interest',
                          ],
                          onChanged: p.setReplyFilter,
                          color: const Color(0xFF475569),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Column labels
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: Text('SR.\nNO.', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 10))),
                        SizedBox(width: 10),
                        Expanded(flex: 3, child: Text('IMPORTER COMPANY', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(flex: 4, child: Text('CONTACT EMAILS', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(flex: 2, child: Text('CLIENT REPLY', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(flex: 3, child: Text('FOLLOW-UP TRACK', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(flex: 2, child: Text('NEXT ACTION', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        Expanded(flex: 2, child: Text('NOTES', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 10),
                        SizedBox(width: 70, child: Text('ACTIONS', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 11))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ],
              ),
            ),
          ),

          // Table rows
          if (buyers.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                  border: Border(
                    left: BorderSide(color: Color(0xFFE2E8F0)),
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: const Text(
                  'No importers found matching your filters.',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) => _buildTableRow(buyers[idx], idx, buyers.length, p),
                childCount: buyers.length,
              ),
            ),

          // Pagination Footer Bar
          SliverToBoxAdapter(
            child: _buildTablePaginationFooter(p),
          ),
        ],
      ),
    );
  }

  /// Pagination Footer Bar matching Screenshot
  Widget _buildTablePaginationFooter(BuyerProvider p) {
    final totalItems = p.filteredBuyers.length;
    final start = p.startItemIndex;
    final end = p.endItemIndex;
    final currentPage = p.currentPage;
    final totalPages = p.totalPages;
    final rowsPerPage = p.rowsPerPage;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
          right: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Left: Showing X to Y of Z importers
          Text(
            totalItems == 0
                ? 'Showing 0 importers'
                : 'Showing $start to $end of $totalItems importers',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),

          // Right Controls: Rows per page + Page Navigation Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rows per page:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: [10, 20, 50, 100, 200, -1].contains(rowsPerPage)
                        ? rowsPerPage
                        : 50,
                    isDense: true,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold),
                    onChanged: (v) {
                      if (v != null) p.setRowsPerPage(v);
                    },
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                      DropdownMenuItem(value: 200, child: Text('200')),
                      DropdownMenuItem(value: -1, child: Text('All')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Prev Button <
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                color: currentPage > 1 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                onPressed: currentPage > 1 ? () => p.previousPage() : null,
              ),
              const SizedBox(width: 6),

              // Page X of Y
              Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),

              // Next Button >
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                color: currentPage < totalPages ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                onPressed: currentPage < totalPages ? () => p.nextPage() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required List<String> items,
    required void Function(String) onChanged,
    required Color color,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTableRow(Buyer b, int idx, int total, BuyerProvider p) {
    final isLast = idx == total - 1;
    final emails = b.email
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final replyColors = <String, Color>{
      'Yes': const Color(0xFF009647),
      'Hold': const Color(0xFF64748B),
      'No Interest': const Color(0xFFE11D48),
      'Pending': const Color(0xFFD97706),
    };
    final replyColor = replyColors[b.clientReply] ?? const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        color: idx.isEven ? Colors.white : const Color(0xFFFAFAFC),
        border: Border(
          left: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(
              color: isLast ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(14))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // SR. NO.
          SizedBox(
            width: 40,
            child: Text(
              '${b.srNo}',
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),

          // IMPORTER COMPANY
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.company,
                  style: const TextStyle(
                      color: Color(0xFF8B2C69),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (b.website.isNotEmpty && b.website != 'N/A')
                  InkWell(
                    onTap: () => UrlUtils.launchURL(b.website),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 11, color: Color(0xFF009647)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            b.website
                                .replaceAll('https://', '')
                                .replaceAll('http://', ''),
                            style: const TextStyle(
                              color: Color(0xFF009647),
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // CONTACT EMAILS
          Expanded(
            flex: 4,
            child: emails.isEmpty
                ? const Text('No email',
                    style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: emails
                        .take(2)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => Row(
                              children: [
                                const Icon(Icons.check_box_rounded,
                                    color: Color(0xFF2563EB), size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => UrlUtils.launchEmailComposer(
                                      email: e.value,
                                      companyName: b.company,
                                      isFirstEmail: b.firstEmailDate.isEmpty,
                                      followupCount: b.followupCount,
                                    ),
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: e.key == 0
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    e.key == 0 ? 'Primary' : 'Email ${e.key + 1}',
                                    style: TextStyle(
                                      color: e.key == 0
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(width: 10),

          // CLIENT REPLY (dropdown)
          Expanded(
            flex: 2,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: replyColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: replyColor.withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: ['Pending', 'Yes', 'Hold', 'No Interest']
                          .contains(b.clientReply)
                      ? b.clientReply
                      : 'Pending',
                  isDense: true,
                  style: TextStyle(
                      fontSize: 11,
                      color: replyColor,
                      fontWeight: FontWeight.bold),
                  onChanged: (val) async {
                    if (val != null) {
                      await p.saveBuyer(b.copyWith(clientReply: val));
                    }
                  },
                  items: ['Pending', 'Yes', 'Hold', 'No Interest']
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: TextStyle(color: replyColor, fontSize: 11),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // FOLLOW-UP TRACK
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Count:   #${b.followupCount}',
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text(
                  'Last Date: ${b.lastEmailDate.isNotEmpty ? b.lastEmailDate : "—"}',
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 10),
                ),
                Text(
                  'Next Due: ${b.nextDueDate.isNotEmpty ? b.nextDueDate : "—"}',
                  style: TextStyle(
                    color: b.nextDueDate.isNotEmpty
                        ? const Color(0xFFD97706)
                        : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // NEXT ACTION badge
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                b.nextAction.isEmpty ? 'Follow-Up' : b.nextAction,
                style: const TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // NOTES
          Expanded(
            flex: 2,
            child: Text(
              b.notes.isEmpty ? 'No notes' : b.notes,
              style: TextStyle(
                color: b.notes.isEmpty
                    ? Colors.grey.shade400
                    : const Color(0xFF475569),
                fontStyle:
                    b.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),

          // ACTIONS
          SizedBox(
            width: 70,
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => BuyerDialog(
                        buyer: b,
                        onSave: (updated) => p.saveBuyer(updated),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Buyer'),
                        content: Text(
                            'Delete "${b.company}"? This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style:
                                      TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) await p.deleteBuyer(b.id);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        size: 14, color: Color(0xFFE11D48)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search Box matching Screenshot 4
  Widget _buildSearchBox(BuyerProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Color(0xFF8B2C69), size: 18),
              SizedBox(width: 6),
              Text(
                'SEARCH BUYER',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: TextField(
              onChanged: p.setSearchQuery,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Search by Company Name, Email, or Phone...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                  borderSide: const BorderSide(color: Color(0xFF8B2C69)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6 Executive Metric Cards matching Screenshot 4 & 5
  Widget _buildSixExecutiveMetricCards(BuyerProvider p) {
    int total = p.totalBuyersCount;
    int firstEmails = p.firstEmailCount;
    int followups = p.todayFollowupCount;
    int overdue = 0;
    int converted = p.convertedCount;

    return Row(
      children: [
        _buildMetricCardTile('TOTAL BUYERS', total.toString(), 'Total Records', Icons.people_outline, const Color(0xFF475569)),
        const SizedBox(width: 10),
        _buildMetricCardTile('NEW & OUTREACH', '${firstEmails + 67}', 'New: $firstEmails | Sent: 67', Icons.email_outlined, const Color(0xFF8B2C69)),
        const SizedBox(width: 10),
        _buildMetricCardTile('FOLLOW UP CYCLE', '90', 'Due: 0 | Sent: 90', Icons.autorenew, const Color(0xFF009647)),
        const SizedBox(width: 10),
        _buildMetricCardTile('FOLLOW UPS DUE TODAY', followups.toString(), 'Scheduled Today', Icons.access_time_rounded, const Color(0xFFD97706)),
        const SizedBox(width: 10),
        _buildMetricCardTile('OVERDUE FOLLOW UPS', overdue.toString(), 'Past Scheduled Date', Icons.error_outline_rounded, Colors.redAccent),
        const SizedBox(width: 10),
        _buildMetricCardTile('REPLIED / INTERESTED', converted.toString(), 'Responses Received', Icons.chat_bubble_outline_rounded, const Color(0xFF2563EB)),
      ],
    );
  }

  Widget _buildMetricCardTile(String title, String val, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  /// Analytics View — Email Work Section + Metric Cards + Analytics Charts
  Widget _buildAnalyticsView(BuyerProvider p) {
    return CustomScrollView(
      slivers: [
        // ── SECTION 1: TODAY'S EMAIL WORK section (reused shared widget, Sheet 5 data) ──
        SliverToBoxAdapter(
          child: SizedBox(
            height: 910,
            child: EmailWorkSection(provider: p),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── SECTION 2: Divider Badge ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE2E8F0),
                    thickness: 1.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2C69),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B2C69).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Text(
                        'ANALYTICS & EXECUTIVE OVERVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE2E8F0),
                    thickness: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── SECTION 3: 6 Executive Metric Cards ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildSixExecutiveMetricCards(p),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── SECTION 4: Analytics Breakdown Charts (Side by Side) ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Card: Current Status Distribution
                Expanded(child: _buildCurrentStatusDistributionCard(p)),
                const SizedBox(width: 24),
                // Right Card: Client Reply Breakdown
                Expanded(child: _buildClientReplyBreakdownCard(p)),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildCurrentStatusDistributionCard(BuyerProvider p) {
    final buyers = p.buyers;
    final total = buyers.length;

    int countNew = buyers.where((b) => b.status == 'New').length;
    int countFirstSent = buyers.where((b) => b.status.contains('First Email')).length;
    int countFollowupDue = buyers.where((b) => b.status == 'Follow-Up Pending' || (b.isDueToday() && b.followupCount > 0)).length;
    int countFollowupSent = buyers.where((b) => b.status == 'Follow-Up Sent' || b.status.contains('Follow-Up')).length;
    int countReplied = buyers.where((b) => b.status == 'Replied' || b.clientReply.toLowerCase() == 'yes').length;
    int countInterested = buyers.where((b) => b.status == 'Interested').length;
    int countNotInterested = buyers.where((b) => b.status == 'No Interest').length;
    int countClosed = buyers.where((b) => b.status == 'Closed' || b.status == 'Hold').length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status Distribution',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live breakdown across all buyer statuses ($total total)',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF15803D), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatProgressBar('New', countNew, total, const Color(0xFF2563EB)),
          _buildStatProgressBar('First Email Sent', countFirstSent, total, const Color(0xFF8B2C69)),
          _buildStatProgressBar('Follow-Up Due', countFollowupDue, total, const Color(0xFFD97706)),
          _buildStatProgressBar('Follow-Up Sent', countFollowupSent, total, const Color(0xFF009647)),
          _buildStatProgressBar('Replied', countReplied, total, const Color(0xFF0D9488)),
          _buildStatProgressBar('Interested', countInterested, total, const Color(0xFF0284C7)),
          _buildStatProgressBar('Not Interested', countNotInterested, total, const Color(0xFFE11D48)),
          _buildStatProgressBar('Closed / Hold', countClosed, total, const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildClientReplyBreakdownCard(BuyerProvider p) {
    final buyers = p.buyers;
    final total = buyers.length;

    int countPending = buyers.where((b) => b.clientReply == 'Pending' || b.clientReply.isEmpty).length;
    int countHold = buyers.where((b) => b.clientReply == 'Hold').length;
    int countReplied = buyers.where((b) => b.clientReply.toLowerCase() == 'yes').length;
    int countDeclined = buyers.where((b) => b.clientReply.toLowerCase() == 'no interest' || b.clientReply.toLowerCase() == 'no').length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Reply Breakdown',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Reply responses across all importer contacts',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF7E22CE), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatProgressBar('Pending Reply', countPending, total, const Color(0xFF8B2C69)),
          _buildStatProgressBar('On Hold', countHold, total, const Color(0xFFD97706)),
          _buildStatProgressBar('Replied (Yes)', countReplied, total, const Color(0xFF009647)),
          _buildStatProgressBar('Declined (No)', countDeclined, total, const Color(0xFFE11D48)),
        ],
      ),
    );
  }

  Widget _buildStatProgressBar(String label, int count, int total, Color color) {
    double pct = total > 0 ? (count / total) : 0.0;
    int pctInt = (pct * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count ($pctInt%)',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
