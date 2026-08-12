import 'package:flutter/material.dart';

class BulkActionBar extends StatefulWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAllDueToday;
  final Function(bool sendGmail) onBatchProcess;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onSelectAllDueToday,
    required this.onBatchProcess,
  });

  @override
  State<BulkActionBar> createState() => _BulkActionBarState();
}

class _BulkActionBarState extends State<BulkActionBar> {
  bool _sendGmail = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF96387D),
            Color(0xFF7A2B64),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF96387D).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 10),
          Text(
            '${widget.selectedCount} Buyer(s) Selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: widget.onSelectAllDueToday,
            icon: const Icon(Icons.select_all, color: Colors.white70, size: 16),
            label: const Text(
              'Select All Due Today',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Switch(
                value: _sendGmail,
                activeThumbColor: Colors.amberAccent,
                onChanged: (val) => setState(() => _sendGmail = val),
              ),
              Text(
                'Send Gmail Follow-up',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009647),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: () => widget.onBatchProcess(_sendGmail),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'Process & Advance +7 Days (${widget.selectedCount})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear Selection',
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: widget.onClearSelection,
          ),
        ],
      ),
    );
  }
}
