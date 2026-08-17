import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/buyer.dart';
import '../../providers/buyer_provider.dart';
import '../../services/url_utils.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EmailWorkSection
///
/// Self-contained, reusable widget for the "TODAY'S EMAIL WORK" dashboard.
/// Reads LIVE data from BuyerProvider (which fetches from Google Sheet).
///
/// Usage:
///   EmailWorkSection(provider: myBuyerProvider)
///
/// Can be dropped into any view that has access to a BuyerProvider instance.
/// ─────────────────────────────────────────────────────────────────────────────
class EmailWorkSection extends StatefulWidget {
  final BuyerProvider provider;

  const EmailWorkSection({super.key, required this.provider});

  @override
  State<EmailWorkSection> createState() => _EmailWorkSectionState();
}

class _EmailWorkSectionState extends State<EmailWorkSection> {
  String _activeSubTab = 'all'; // 'all' | 'overdue' | 'followups' | 'first_emails'

  /// Page-level scroll (outer CustomScrollView)
  late final ScrollController _pageScrollCtrl;

  /// Per-section scroll controllers — each section has its own inline scrollbar
  late final ScrollController _overdueScrollCtrl;
  late final ScrollController _followupScrollCtrl;
  late final ScrollController _firstEmailScrollCtrl;

  // ── Layout constants ────────────────────────────────────────────────────────
  static const int _rowsVisible = 5;
  static const double _rowHeight = 68.0;

  @override
  void initState() {
    super.initState();
    _pageScrollCtrl = ScrollController();
    _overdueScrollCtrl = ScrollController()
      ..addListener(() => _onSectionScroll('overdue', _overdueScrollCtrl));
    _followupScrollCtrl = ScrollController()
      ..addListener(() => _onSectionScroll('followups', _followupScrollCtrl));
    _firstEmailScrollCtrl = ScrollController()
      ..addListener(() => _onSectionScroll('first_emails', _firstEmailScrollCtrl));
  }

  @override
  void dispose() {
    _pageScrollCtrl.dispose();
    _overdueScrollCtrl.dispose();
    _followupScrollCtrl.dispose();
    _firstEmailScrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll helpers ──────────────────────────────────────────────────────────
  void _onSectionScroll(String category, ScrollController ctrl) {
    if (!ctrl.hasClients) return;
    if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 150) {
      widget.provider.loadMoreCategory(category);
    }
  }

  // ── Date formatter ──────────────────────────────────────────────────────────
  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty || rawDate == 'N/A' || rawDate == '-') {
      return 'N/A';
    }
    final parsed = Buyer.parseDate(rawDate);
    if (parsed != null) {
      return DateFormat('dd-MMM-yyyy').format(parsed);
    }
    return rawDate;
  }

  // ── URL / email launchers ───────────────────────────────────────────────────
  void _launchURL(String url) => UrlUtils.launchURL(url);
  void _launchEmail(String email) => UrlUtils.launchEmail(email);

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    // Full lists from provider (Google Sheet live data via BuyerProvider)
    final overdueBuyers = p.overdueBuyers;
    final followupBuyers = p.followupTodayBuyers;
    final firstEmailBuyers = p.firstEmailBuyers;

    // Paginated views for the inline scroll lists
    final paginatedOverdue = p.paginatedOverdueBuyers;
    final paginatedFollowup = p.paginatedFollowupTodayBuyers;
    final paginatedFirstEmail = p.paginatedFirstEmailBuyers;

    final totalTodayWork =
        overdueBuyers.length + followupBuyers.length + firstEmailBuyers.length;

    return SelectionArea(
      child: CustomScrollView(
        controller: _pageScrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Banner + Filter bar ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMorningBanner(
                  overdueCount: overdueBuyers.length,
                  followupCount: followupBuyers.length,
                  firstEmailCount: firstEmailBuyers.length,
                ),
                const SizedBox(height: 16),
                _buildFilterBar(
                  total: totalTodayWork,
                  overdue: overdueBuyers.length,
                  followups: followupBuyers.length,
                  firstEmails: firstEmailBuyers.length,
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── SECTION 1: OVERDUE ──────────────────────────────────────────────
          if (_activeSubTab == 'all' || _activeSubTab == 'overdue')
            _buildSection(
              title: 'OVERDUE',
              count: overdueBuyers.length,
              icon: Icons.error_outline_rounded,
              themeColor: const Color(0xFFE11D48),
              bgColor: const Color(0xFFFFF1F2),
              borderColor: const Color(0xFFFECDD3),
              description:
                  '— Buyers past follow-up date, not yet marked as contacted (sorted oldest to newest)',
              allBuyers: overdueBuyers,
              paginatedBuyers: paginatedOverdue,
              sectionScrollCtrl: _overdueScrollCtrl,
              p: p,
              buttonText: 'Send Follow-Up',
              isFollowup: true,
            ),

          if (_activeSubTab == 'all' || _activeSubTab == 'overdue')
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── SECTION 2: FOLLOW-UPS TODAY ─────────────────────────────────────
          if (_activeSubTab == 'all' || _activeSubTab == 'followups')
            _buildSection(
              title: 'FOLLOW-UPS TODAY',
              count: followupBuyers.length,
              icon: Icons.access_time_rounded,
              themeColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              description:
                  '— Buyers whose Follow-Up Date is scheduled for today',
              allBuyers: followupBuyers,
              paginatedBuyers: paginatedFollowup,
              sectionScrollCtrl: _followupScrollCtrl,
              p: p,
              buttonText: 'Send Follow-Up',
              isFollowup: true,
              showBatchButton: true,
              batchAction: () async {
                final targetBuyers = followupBuyers.toList();
                for (var b in targetBuyers) {
                  if (b.email.isNotEmpty) {
                    await UrlUtils.launchEmailComposer(
                      email: b.email,
                      companyName: b.company,
                      isFirstEmail: false,
                      followupCount: b.followupCount,
                      context: context,
                    );
                  }
                }
                if (!context.mounted) return;
                final bool? ok = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Confirm Batch Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Text('Did you complete sending emails for all ${targetBuyers.length} follow-up companies in Outlook?'),
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No, Keep in List', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
                        child: const Text('Yes, Mark All as Sent ✅'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final ids = targetBuyers.map((b) => b.id).toList();
                  await p.batchProcessSelectedCustom(ids);
                }
              },
              batchLabel: 'Send All Follow-Ups Today',
            ),

          if (_activeSubTab == 'all' || _activeSubTab == 'followups')
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── SECTION 3: FIRST EMAILS TODAY ──────────────────────────────────
          if (_activeSubTab == 'all' || _activeSubTab == 'first_emails')
            _buildSection(
              title: 'FIRST EMAILS TODAY',
              count: firstEmailBuyers.length,
              icon: Icons.email_outlined,
              themeColor: const Color(0xFF8B2C69),
              bgColor: const Color(0xFFFDF4FF),
              borderColor: const Color(0xFFF5D0FE),
              description: '— Buyers who need their initial email outreach',
              allBuyers: firstEmailBuyers,
              paginatedBuyers: paginatedFirstEmail,
              sectionScrollCtrl: _firstEmailScrollCtrl,
              p: p,
              buttonText: 'Send First Email',
              isFollowup: false,
              showBatchButton: true,
              batchAction: () async {
                final targetBuyers = firstEmailBuyers.toList();
                for (var b in targetBuyers) {
                  if (b.email.isNotEmpty) {
                    await UrlUtils.launchEmailComposer(
                      email: b.email,
                      companyName: b.company,
                      isFirstEmail: true,
                      context: context,
                    );
                  }
                }
                if (!context.mounted) return;
                final bool? ok = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Confirm Batch Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Text('Did you complete sending first emails for all ${targetBuyers.length} companies in Outlook?'),
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No, Keep in List', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
                        child: const Text('Yes, Mark All as Sent ✅'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final ids = targetBuyers.map((b) => b.id).toList();
                  await p.batchProcessSelectedCustom(ids);
                }
              },
              batchLabel: 'Send All First Emails',
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MORNING BANNER  (dark purple gradient, matches screenshot exactly)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMorningBanner({
    required int overdueCount,
    required int followupCount,
    required int firstEmailCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF230735), Color(0xFF531149), Color(0xFF8B2C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF230735).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "TODAY'S EMAIL WORK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009647),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'MORNING ACTION AREA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open every morning to immediately see: "These are the buyers I need to email today."',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                _buildStatBox('FIRST EMAILS', firstEmailCount.toString(),
                    'FIRST EMAIL', const Color(0xFFC084FC)),
                const SizedBox(width: 10),
                _buildStatBox('FOLLOW-UPS', followupCount.toString(),
                    'FOLLOW-UP', const Color(0xFFFBBF24)),
                const SizedBox(width: 10),
                _buildStatBox('OVERDUE', overdueCount.toString(), 'OVERDUE',
                    const Color(0xFFF87171)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      String label, String value, String tag, Color color) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(tag,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterBar({
    required int total,
    required int overdue,
    required int followups,
    required int firstEmails,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab("All Today's Work ($total)", 'all',
              Colors.grey.shade900),
          const SizedBox(width: 8),
          _buildFilterTab('OVERDUE $overdue', 'overdue',
              const Color(0xFFE11D48)),
          const SizedBox(width: 8),
          _buildFilterTab('FOLLOW-UPS TODAY $followups', 'followups',
              const Color(0xFFD97706)),
          const SizedBox(width: 8),
          _buildFilterTab('FIRST EMAILS TODAY $firstEmails', 'first_emails',
              const Color(0xFF8B2C69)),
          const Spacer(),
          const Icon(Icons.bolt, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          const Text(
            'Action buttons automatically log email date & sync to Google Sheet',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String key, Color color) {
    final isActive = _activeSubTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE2E8F0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : const Color(0xFF475569),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIXED-HEIGHT SECTION  (header + column labels + inline scrollable rows)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSection({
    required String title,
    required int count,
    required IconData icon,
    required Color themeColor,
    required Color bgColor,
    required Color borderColor,
    required String description,
    required List<Buyer> allBuyers,
    required List<Buyer> paginatedBuyers,
    required ScrollController sectionScrollCtrl,
    required BuyerProvider p,
    required String buttonText,
    required bool isFollowup,
    bool showBatchButton = false,
    VoidCallback? batchAction,
    String? batchLabel,
  }) {
    final double listHeight = count == 0
        ? 80.0
        : (_rowHeight * count.clamp(1, _rowsVisible))
            .clamp(0.0, _rowHeight * _rowsVisible);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Section header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: themeColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$title ($count)',
                      style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                            color: themeColor.withValues(alpha: 0.75),
                            fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showBatchButton && count > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: batchAction,
                        icon: const Icon(Icons.send_rounded, size: 13),
                        label: Text(
                          '$batchLabel ($count)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // ── Column labels ───────────────────────────────────────────
              // ── Column labels ───────────────────────────────────────────
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 120,
                        child: Text('STATUS BADGE',
                            style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 11))),
                    const SizedBox(width: 8),
                    const Expanded(
                        flex: 3,
                        child: Text('BUYER COMPANY',
                            style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 11))),
                    const SizedBox(width: 8),
                    const Expanded(
                        flex: 4,
                        child: Text('EMAIL ADDRESSES',
                            style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 11))),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 2,
                        child: Text(
                            isFollowup ? 'FOLLOW-UP DATE' : 'CONNECTION DATE',
                            style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 11))),
                    if (isFollowup) const SizedBox(width: 8),
                    if (isFollowup)
                      const SizedBox(
                          width: 80,
                          child: Text('FOLLOW-UP COUNT',
                              style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11))),
                    const SizedBox(width: 8),
                    const SizedBox(
                        width: 140,
                        child: Text('ACTION',
                            style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 11))),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // ── Rows ────────────────────────────────────────────────────
              if (count == 0)
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(13)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF009647), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'No $title buyers — all clear!',
                        style: const TextStyle(
                            color: Color(0xFF009647),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: listHeight,
                  child: Scrollbar(
                    controller: sectionScrollCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: sectionScrollCtrl,
                      physics: const ClampingScrollPhysics(),
                      itemCount: paginatedBuyers.length,
                      itemExtent: _rowHeight,
                      itemBuilder: (context, idx) => _buildRow(
                        buyer: paginatedBuyers[idx],
                        isLast: idx == paginatedBuyers.length - 1,
                        isFollowup: isFollowup,
                        themeColor: themeColor,
                        borderColor: borderColor,
                        buttonText: buttonText,
                        p: p,
                      ),
                    ),
                  ),
                ),

              // ── "Showing X of Y" footer ─────────────────────────────────
              if (count > _rowsVisible)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13)),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.expand_more_rounded,
                          color: themeColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Showing ${paginatedBuyers.length} of $count — scroll inside list for more',
                        style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLE TABLE ROW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRow({
    required Buyer buyer,
    required bool isLast,
    required bool isFollowup,
    required Color themeColor,
    required Color borderColor,
    required String buttonText,
    required BuyerProvider p,
  }) {
    final emails = buyer.email
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
              color: isLast ? borderColor : const Color(0xFFE2E8F0)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(13))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status badge
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowup
                        ? Icons.access_time_rounded
                        : Icons.email_outlined,
                    size: 12,
                    color: themeColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isFollowup ? 'FOLLOW-UP' : 'FIRST EMAIL',
                      style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Buyer company + website
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buyer.company,
                  style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (buyer.website.isNotEmpty && buyer.website != 'N/A')
                  InkWell(
                    onTap: () => _launchURL(buyer.website),
                    child: Text(
                      buyer.website,
                      style: const TextStyle(
                        color: Color(0xFF009647),
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Email addresses
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: emails
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box_rounded,
                                      color: Color(0xFF2563EB), size: 13),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: InkWell(
                                      onTap: () => _launchEmail(e.value),
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Tooltip(
                                    message: 'Copy email',
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: e.value));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Copied ${e.value} to clipboard!'),
                                            backgroundColor: const Color(0xFF009647),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            width: 300,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                        child: Icon(Icons.content_copy_rounded,
                                            size: 13, color: Color(0xFF64748B)),
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
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      e.key == 0
                                          ? 'Primary'
                                          : 'Email ${e.key + 1}',
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
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(width: 8),

          // Date column
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(isFollowup
                  ? (buyer.nextDueDate.isNotEmpty
                      ? buyer.nextDueDate
                      : buyer.connectionDate)
                  : buyer.connectionDate),
              style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (isFollowup) const SizedBox(width: 8),

          // Follow-up count (only for follow-up rows)
          if (isFollowup)
            SizedBox(
              width: 80,
              child: Text(
                '#${buyer.followupCount}',
                style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          const SizedBox(width: 8),

          // Action button
          SizedBox(
            width: 145,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 1,
              ),
              onPressed: () async {
                await UrlUtils.handleSendEmailWithConfirmation(
                  context: context,
                  buyer: buyer,
                  provider: p,
                );
              },
              icon: const Icon(Icons.send_rounded, size: 13),
              label: Text(
                buyer.actionButtonLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
