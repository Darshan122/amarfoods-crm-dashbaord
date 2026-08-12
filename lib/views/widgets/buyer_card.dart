import 'package:flutter/material.dart';
import '../../models/buyer.dart';

class BuyerCard extends StatelessWidget {
  final Buyer buyer;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onAdvanceFollowup;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BuyerCard({
    super.key,
    required this.buyer,
    required this.isSelected,
    required this.onSelect,
    required this.onAdvanceFollowup,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDue = buyer.isDueToday() && buyer.status != 'Converted' && buyer.status != 'Not Interested';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFDF2FA)
            : (isDue ? const Color(0xFFFEF2F2) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF96387D)
              : (isDue ? Colors.redAccent : const Color(0xFFE2E8F0)),
          width: isSelected || isDue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFF96387D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) => onSelect(),
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: _getAvatarColor(buyer.name),
                child: Text(
                  buyer.name.isNotEmpty ? buyer.name[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      buyer.email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusPill(buyer.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDueDateChip(buyer.nextDueDate, isDue),
              const Spacer(),
              InkWell(
                onTap: onAdvanceFollowup,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009647).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF009647).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.send_rounded, color: Color(0xFF009647), size: 12),
                      SizedBox(width: 4),
                      Text('+7 Days', style: TextStyle(color: Color(0xFF009647), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 16),
                onPressed: onEdit,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFFDF2FA);
    Color text = const Color(0xFF96387D);

    if (status == 'First Email Pending') {
      bg = const Color(0xFFFDF2FA);
      text = const Color(0xFF96387D);
    } else if (status.contains('Follow-up')) {
      bg = const Color(0xFFFFFEF0);
      text = const Color(0xFFD97706);
    } else if (status == 'Converted') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF009647);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildDueDateChip(String dateStr, bool isDue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDue ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDue ? Colors.redAccent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDue ? Icons.alarm_on : Icons.calendar_today,
            color: isDue ? Colors.redAccent : const Color(0xFF64748B),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isDue ? 'DUE TODAY: $dateStr' : dateStr,
            style: TextStyle(
              color: isDue ? Colors.redAccent : const Color(0xFF334155),
              fontSize: 10,
              fontWeight: isDue ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    int hash = name.hashCode;
    final colors = [
      const Color(0xFF96387D),
      const Color(0xFF009647),
      const Color(0xFF4F46E5),
      const Color(0xFFD97706),
    ];
    return colors[hash.abs() % colors.length];
  }
}
