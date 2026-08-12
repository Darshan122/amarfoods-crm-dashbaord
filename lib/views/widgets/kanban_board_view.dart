import 'package:flutter/material.dart';
import '../../models/buyer.dart';
import '../../providers/buyer_provider.dart';
import '../buyer_dialog.dart';
import 'buyer_card.dart';

class KanbanBoardView extends StatelessWidget {
  final BuyerProvider provider;

  const KanbanBoardView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKanbanColumn(
          context,
          title: 'First Email Pending',
          icon: Icons.outgoing_mail,
          color: const Color(0xFF96387D),
          buyers: provider.firstEmailBuyers,
        ),
        const SizedBox(width: 14),
        _buildKanbanColumn(
          context,
          title: 'Follow-up 1 Pending',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFD97706),
          buyers: provider.followup1Buyers,
        ),
        const SizedBox(width: 14),
        _buildKanbanColumn(
          context,
          title: 'Follow-up 2+ Active',
          icon: Icons.autorenew_rounded,
          color: const Color(0xFFEA580C),
          buyers: provider.followupMultiBuyers,
        ),
        const SizedBox(width: 14),
        _buildKanbanColumn(
          context,
          title: 'Converted Deals',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF009647),
          buyers: provider.convertedBuyers,
        ),
      ],
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Buyer> buyers,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    buyers.length.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: buyers.isEmpty
                  ? Center(
                      child: Text(
                        'No Buyers',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemExtent: 112, // Fixed height per item for fast O(1) scroll computation!
                      itemCount: buyers.length,
                      itemBuilder: (context, idx) {
                        final buyer = buyers[idx];
                        bool isSelected = provider.selectedBuyerIds.contains(buyer.id);

                        return BuyerCard(
                          key: ValueKey(buyer.id),
                          buyer: buyer,
                          isSelected: isSelected,
                          onSelect: () => provider.toggleSelectBuyer(buyer.id),
                          onAdvanceFollowup: () async {
                            provider.toggleSelectBuyer(buyer.id);
                            await provider.batchProcessSelected();
                          },
                          onEdit: () {
                            showDialog(
                              context: context,
                              builder: (_) => BuyerDialog(
                                buyer: buyer,
                                onSave: (b) => provider.saveBuyer(b),
                              ),
                            );
                          },
                          onDelete: () => provider.deleteBuyer(buyer.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
