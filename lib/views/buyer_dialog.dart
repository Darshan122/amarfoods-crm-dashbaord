import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/buyer.dart';

class BuyerDialog extends StatefulWidget {
  final Buyer? buyer;
  final Function(Buyer buyer) onSave;

  const BuyerDialog({super.key, this.buyer, required this.onSave});

  @override
  State<BuyerDialog> createState() => _BuyerDialogState();
}

class _BuyerDialogState extends State<BuyerDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _followUpDateCtrl;
  late TextEditingController _notesCtrl;

  String _connectionType = 'Email';
  String _status = 'New';
  String _clientReply = 'Pending';

  final List<String> _connectionTypes = ['Email', 'WhatsApp', 'Viber', 'Web Form', 'Social Media'];
  final List<String> _statuses = ['New', 'Contacted', 'First Email Sent', 'Follow-Up Sent', 'Replied', 'Hold'];
  final List<String> _clientReplies = ['Pending', 'Hold', 'Yes', 'No'];

  @override
  void initState() {
    super.initState();
    final b = widget.buyer;
    final todayStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _companyCtrl = TextEditingController(text: b?.company ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');
    _websiteCtrl = TextEditingController(text: b?.website ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');

    String dateVal = b?.nextDueDate ?? '';
    if (dateVal.isNotEmpty) {
      try {
        DateTime parsed = DateFormat('yyyy-MM-dd').parse(dateVal);
        dateVal = DateFormat('dd-MM-yyyy').format(parsed);
      } catch (_) {}
    } else {
      dateVal = todayStr;
    }
    _followUpDateCtrl = TextEditingController(text: dateVal);
    _notesCtrl = TextEditingController(text: b?.notes ?? '');

    _connectionType = b?.connectionMethod.isNotEmpty == true ? b!.connectionMethod : 'Email';
    _status = b?.status.isNotEmpty == true ? b!.status : 'New';
    _clientReply = b?.clientReply.isNotEmpty == true ? b!.clientReply : 'Pending';
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _followUpDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      if (_followUpDateCtrl.text.isNotEmpty) {
        initial = DateFormat('dd-MM-yyyy').parse(_followUpDateCtrl.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009647),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked.weekday == DateTime.sunday) {
        // Skip Sunday -> Monday
        final monday = picked.add(const Duration(days: 1));
        _followUpDateCtrl.text = DateFormat('dd-MM-yyyy').format(monday);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF8B2C69),
              content: Text('Sunday selected. Automatically shifted to Monday for business delivery.'),
            ),
          );
        }
      } else {
        _followUpDateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.buyer != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SelectionArea(
        child: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Importer Lead Specs',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Form Body (Exact 2-column layout matching screenshots 2 & 3!)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ROW 1: Importer Company | Email Addresses
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Importer Company *',
                              child: TextFormField(
                                controller: _companyCtrl,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration('Company Name'),
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Company Name is required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Email Addresses (Primary, Email 2, Email 3...)',
                              subtext: 'Separate multiple email addresses using commas or spaces.',
                              child: TextFormField(
                                controller: _emailCtrl,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration('primary@company.com, email2@company.com'),
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Email is required' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ROW 2: Website URL | Phone / WhatsApp
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Website URL',
                              child: TextFormField(
                                controller: _websiteCtrl,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration('https://...'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Phone / WhatsApp',
                              child: TextFormField(
                                controller: _phoneCtrl,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration('+1 234 567 890'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ROW 3: Connection Type | Current Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Connection Type',
                              child: DropdownButtonFormField<String>(
                                initialValue: _connectionTypes.contains(_connectionType) ? _connectionType : _connectionTypes.first,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration(''),
                                items: _connectionTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _connectionType = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Current Status *',
                              child: DropdownButtonFormField<String>(
                                initialValue: _statuses.contains(_status) ? _status : _statuses.first,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration(''),
                                items: _statuses
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _status = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ROW 4: Client Reply | Next Follow-Up Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Client Reply',
                              child: DropdownButtonFormField<String>(
                                initialValue: _clientReplies.contains(_clientReply) ? _clientReply : _clientReplies.first,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration(''),
                                items: _clientReplies
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _clientReply = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLabeledField(
                              label: 'Next Follow-Up Date',
                              child: TextFormField(
                                controller: _followUpDateCtrl,
                                readOnly: true,
                                onTap: _selectDate,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: _inputDecoration('dd-MM-yyyy').copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B), size: 18),
                                    onPressed: _selectDate,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ROW 5: Buyer Notes & Specifications
                      _buildLabeledField(
                        label: 'Buyer Notes & Specifications',
                        child: TextFormField(
                          controller: _notesCtrl,
                          maxLines: 4,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          decoration: _inputDecoration('Note preferred onion/garlic mesh sizes, packaging requirements, target pricing...'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Bar matching Screenshot 3!
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009647),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String standardDate = _followUpDateCtrl.text.trim();
                        try {
                          DateTime parsed = DateFormat('dd-MM-yyyy').parse(standardDate);
                          standardDate = DateFormat('yyyy-MM-dd').format(parsed);
                        } catch (_) {}

                        final buyer = Buyer(
                          id: widget.buyer?.id ?? Buyer.formatBuyerId(DateTime.now().millisecondsSinceEpoch % 99999),
                          srNo: widget.buyer?.srNo ?? 1,
                          company: _companyCtrl.text.trim(),
                          website: _websiteCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          connectionMethod: _connectionType,
                          connectionDate: widget.buyer?.connectionDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          firstEmailDate: widget.buyer?.firstEmailDate ?? '',
                          nextDueDate: standardDate,
                          clientReply: _clientReply,
                          lastEmailDate: widget.buyer?.lastEmailDate ?? '',
                          followupCount: widget.buyer?.followupCount ?? 0,
                          status: _status,
                          nextAction: widget.buyer?.nextAction ?? 'Follow-Up',
                          notes: _notesCtrl.text.trim(),
                        );
                        widget.onSave(buyer);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      isEditing ? 'Save Importer' : 'Save Importer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
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

  Widget _buildLabeledField({required String label, String? subtext, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF009647), width: 1.5),
      ),
    );
  }
}
