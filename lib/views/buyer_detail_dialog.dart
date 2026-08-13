import 'package:flutter/material.dart';
import '../models/buyer.dart';
import '../services/url_utils.dart';

class BuyerDetailDialog extends StatelessWidget {
  final Buyer buyer;
  final VoidCallback onEdit;
  final VoidCallback onSendFollowup;

  const BuyerDetailDialog({
    super.key,
    required this.buyer,
    required this.onEdit,
    required this.onSendFollowup,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SelectionArea(
        child: SizedBox(
          width: 650,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B2C69), Color(0xFF96387D)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      buyer.id,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyer.company,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Sr. No: ${buyer.srNo} • Connection Method: ${buyer.connectionMethod}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.language, 'Importer Website', buyer.website.isEmpty ? 'N/A' : buyer.website),
                        const Divider(height: 16),
                        _buildDetailRow(Icons.email_outlined, 'Contact Email(s)', buyer.email),
                        const Divider(height: 16),
                        _buildDetailRow(Icons.phone_outlined, 'Phone / WhatsApp', buyer.phone.isEmpty ? 'N/A' : buyer.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates & Status Matrix
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B2C69).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.history_toggle_off_rounded, color: Color(0xFF8B2C69), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Google Sheet Date & Status Matrix',
                              style: TextStyle(color: Color(0xFF8B2C69), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoColumn('Connection Date', buyer.connectionDate.isEmpty ? 'N/A' : buyer.connectionDate)),
                            Expanded(child: _buildInfoColumn('First Email Date', buyer.firstEmailDate.isEmpty ? 'Not Sent' : buyer.firstEmailDate)),
                            Expanded(child: _buildInfoColumn('Follow Up Date', buyer.nextDueDate.isEmpty ? 'N/A' : buyer.nextDueDate)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoColumn('Client Reply', buyer.clientReply)),
                            Expanded(child: _buildInfoColumn('Current Status', buyer.status)),
                            Expanded(child: _buildInfoColumn('Next Action', buyer.nextAction)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoColumn('Last Email Date', buyer.lastEmailDate.isEmpty ? 'N/A' : buyer.lastEmailDate)),
                            Expanded(child: _buildInfoColumn('Follow-Up Count', '${buyer.followupCount} Sent')),
                            Expanded(child: _buildInfoColumn('Next Suggested', buyer.suggestNextEmailType())),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  const Text('Notes & Product Requirements:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      buyer.notes.isEmpty ? 'No notes added yet.' : buyer.notes,
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            // Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B2C69),
                      side: const BorderSide(color: Color(0xFF8B2C69)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Edit Full 15 Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009647),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onSendFollowup();
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text('Send ${buyer.suggestNextEmailType()} (+7 Days)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    bool isClickable = false;
    VoidCallback? onTap;
    Color valueColor = const Color(0xFF0F172A);

    if (label.contains('Website') && value != 'N/A') {
      isClickable = true;
      onTap = () => UrlUtils.launchURL(value);
      valueColor = const Color(0xFF009647);
    } else if (label.contains('Email') && value.isNotEmpty) {
      isClickable = true;
      onTap = () {
        final emails = value.split(',').map((e) => e.trim()).toList();
        if (emails.isNotEmpty) UrlUtils.launchEmail(emails.first);
      };
      valueColor = const Color(0xFF2563EB);
    } else if (label.contains('Phone') && value != 'N/A') {
      isClickable = true;
      onTap = () => UrlUtils.launchPhone(value);
      valueColor = const Color(0xFF2563EB);
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B2C69)),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(
          child: isClickable
              ? InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(value, style: TextStyle(color: valueColor, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
