import 'package:flutter/material.dart';

class ConfigDialog extends StatefulWidget {
  final String? currentUrl;
  final Function(String url) onSaveUrl;

  const ConfigDialog({super.key, this.currentUrl, required this.onSaveUrl});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.table_chart_rounded, color: Color(0xFF009647)),
          SizedBox(width: 10),
          Text(
            'Google Sheets Connection',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Apps Script Web App URL for live 2-way sync with Google Sheet:',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Apps Script Web App URL',
                hintText: 'https://script.google.com/macros/s/.../exec',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF009647)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF009647).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF009647), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live 2-way sync enabled. Adding, editing, and follow-up updates write directly to Google Sheets.',
                      style: TextStyle(color: Color(0xFF166534), fontSize: 12),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009647),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onSaveUrl(_urlCtrl.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
