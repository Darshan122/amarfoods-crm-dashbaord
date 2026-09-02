import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/buyer.dart';

class BuyerDialog extends StatefulWidget {
  final Buyer? buyer;
  final int nextSrNo;
  final List<Buyer> existingBuyers;
  final String? defaultMarket;
  final Function(Buyer buyer) onSave;

  const BuyerDialog({
    super.key,
    this.buyer,
    this.nextSrNo = 1,
    this.existingBuyers = const [],
    this.defaultMarket,
    required this.onSave,
  });

  @override
  State<BuyerDialog> createState() => _BuyerDialogState();
}

class _BuyerDialogState extends State<BuyerDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyCtrl;
  final List<TextEditingController> _emailCtrls = [];
  late TextEditingController _websiteCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _followUpDateCtrl;
  late TextEditingController _notesCtrl;

  String _connectionType = 'Email';
  String _status = 'New';
  String _clientReply = 'Pending';
  String _marketType = 'International';

  final List<String> _connectionTypes = ['Email', 'WhatsApp', 'Viber', 'Web Form', 'Social Media'];
  final List<String> _statuses = ['New', 'Contacted', 'First Email Sent', 'Follow-Up Sent', 'Replied', 'Hold'];
  final List<String> _clientReplies = ['Pending', 'Hold', 'Yes', 'No'];
  final List<String> _marketTypes = ['International', 'Domestic'];

  @override
  void initState() {
    super.initState();
    final b = widget.buyer;
    final todayStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _companyCtrl = TextEditingController(text: b?.company ?? '');
    
    final rawEmails = b?.email ?? '';
    final emailList = rawEmails
        .split(RegExp(r'[,;/]\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (emailList.isEmpty) {
      _emailCtrls.add(TextEditingController());
    } else {
      for (var em in emailList) {
        _emailCtrls.add(TextEditingController(text: em));
      }
    }

    _websiteCtrl = TextEditingController(text: b?.website ?? '');

    String rawPhone = b?.phone ?? '';
    if (rawPhone.startsWith("'")) rawPhone = rawPhone.substring(1).trim();
    final lowerPhone = rawPhone.toLowerCase();
    if (lowerPhone == '#error!' ||
        lowerPhone.contains('#error') ||
        lowerPhone == '#ref!' ||
        lowerPhone == '#value!' ||
        lowerPhone == '#n/a' ||
        lowerPhone == 'n/a' ||
        lowerPhone == '-' ||
        lowerPhone == 'null') {
      rawPhone = '';
    }
    _phoneCtrl = TextEditingController(text: rawPhone);

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

    final initialMarket = b?.marketType ?? widget.defaultMarket ?? 'International';
    _marketType = initialMarket.toLowerCase().contains('dom') ? 'Domestic' : 'International';

    _connectionType = b?.connectionMethod.isNotEmpty == true ? b!.connectionMethod : 'Email';
    _status = b?.status.isNotEmpty == true ? b!.status : 'New';
    _clientReply = b?.clientReply.isNotEmpty == true ? b!.clientReply : 'Pending';
  }

  void _addEmailField([String text = '']) {
    setState(() {
      _emailCtrls.add(TextEditingController(text: text));
    });
  }

  void _removeEmailField(int index) {
    if (_emailCtrls.length <= 1) return;
    setState(() {
      _emailCtrls[index].dispose();
      _emailCtrls.removeAt(index);
    });
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    for (var ctrl in _emailCtrls) {
      ctrl.dispose();
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: isMobile ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24) : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SelectionArea(
        child: SizedBox(
          width: isMobile ? screenWidth * 0.96 : 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Importer Lead Specs' : 'Add New Importer Lead',
                      style: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2C69).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF8B2C69).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Sr. No. #${isEditing ? widget.buyer!.srNo : widget.nextSrNo}',
                      style: const TextStyle(
                        color: Color(0xFF8B2C69),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ROW 1: Importer Company | Email Addresses
                      _buildFormPair(
                        isMobile,
                        _buildLabeledField(
                          label: 'Importer Company *',
                          child: TextFormField(
                            controller: _companyCtrl,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _inputDecoration('Company Name'),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Company Name is required' : null,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Addresses *',
                              style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text('Press Enter or click + Add Email to add another email.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            const SizedBox(height: 6),
                            ..._emailCtrls.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final ctrl = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: ctrl,
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => _addEmailField(),
                                        decoration: _inputDecoration(idx == 0 ? 'Primary Email (primary@company.com)' : 'Secondary Email ${idx + 1}'),
                                        validator: (val) {
                                          if (idx == 0 && (val == null || val.trim().isEmpty)) {
                                            return 'Primary email is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (idx > 0) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                        onPressed: () => _removeEmailField(idx),
                                        tooltip: 'Remove Email',
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () => _addEmailField(),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF009647).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF009647).withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, color: Color(0xFF009647), size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '+ Add Email Field',
                                      style: TextStyle(color: Color(0xFF009647), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ROW 2: Website URL | Phone / WhatsApp
                      _buildFormPair(
                        isMobile,
                        _buildLabeledField(
                          label: 'Website URL',
                          child: TextFormField(
                            controller: _websiteCtrl,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _inputDecoration('https://...'),
                          ),
                        ),
                        _buildLabeledField(
                          label: 'Phone / WhatsApp',
                          child: TextFormField(
                            controller: _phoneCtrl,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _inputDecoration('+1 234 567 890'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ROW 3: Market Segment | Connection Type
                      _buildFormPair(
                        isMobile,
                        _buildLabeledField(
                          label: 'Market Segment *',
                          child: DropdownButtonFormField<String>(
                            initialValue: _marketTypes.contains(_marketType) ? _marketType : 'International',
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _inputDecoration(''),
                            items: const [
                              DropdownMenuItem(value: 'International', child: Text('🌍 International (Export)')),
                              DropdownMenuItem(value: 'Domestic', child: Text('🇮🇳 Domestic (India)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _marketType = val);
                            },
                          ),
                        ),
                        _buildLabeledField(
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
                      const SizedBox(height: 18),

                      // ROW 4: Current Status | Client Reply
                      _buildFormPair(
                        isMobile,
                        _buildLabeledField(
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
                        _buildLabeledField(
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
                      const SizedBox(height: 18),

                      // ROW 5: Next Follow-Up Date
                      _buildLabeledField(
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
                      const SizedBox(height: 18),

                      // ROW 6: Buyer Notes & Specifications
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

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Action Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009647),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: _saveForm,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isEditing ? 'Save Changes' : 'Create Importer Lead',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    String standardDate = _followUpDateCtrl.text.trim();
    try {
      DateTime parsed = DateFormat('dd-MM-yyyy').parse(standardDate);
      standardDate = DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {}

    final companyName = _companyCtrl.text.trim();
    final emailStr = _emailCtrls
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');

    final srNoVal = widget.buyer?.srNo ?? widget.nextSrNo;
    final newBuyer = Buyer(
      id: widget.buyer?.id ?? Buyer.formatBuyerId(srNoVal),
      srNo: srNoVal,
      company: companyName,
      website: _websiteCtrl.text.trim(),
      email: emailStr,
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
      marketType: _marketType,
    );

    bool isEditing = widget.buyer != null;

    if (!isEditing) {
      Buyer? duplicate;
      for (var b in widget.existingBuyers) {
        bool isRealEmail = emailStr.isNotEmpty &&
            emailStr != '-' &&
            emailStr.toLowerCase() != 'n/a' &&
            emailStr.contains('@');
        bool isRealCompany = companyName.isNotEmpty &&
            companyName != '-' &&
            companyName.toLowerCase() != 'n/a' &&
            !companyName.toLowerCase().startsWith('importer #');

        bool companyMatch = isRealCompany && companyName.toLowerCase() == b.company.trim().toLowerCase();
        bool emailMatch = isRealEmail && b.email.toLowerCase().split(RegExp(r'[,;/]\s*')).where((e) => e.contains('@')).contains(emailStr.toLowerCase());

        if (companyMatch || emailMatch) {
          duplicate = b;
          break;
        }
      }

      if (duplicate != null) {
        _showDuplicateWarningDialog(context, duplicate, newBuyer);
        return;
      }
    }

    widget.onSave(newBuyer);
    Navigator.pop(context);
  }

  void _showDuplicateWarningDialog(BuildContext parentContext, Buyer existing, Buyer newBuyer) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 10),
            Text(
              'Duplicate Lead Detected',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: 'An importer named '),
                  TextSpan(
                    text: '"${existing.company}" ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const TextSpan(text: 'already exists in your CRM at '),
                  TextSpan(
                    text: 'Sr. No. #${existing.srNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B2C69)),
                  ),
                  if (existing.email.isNotEmpty) TextSpan(text: ' (${existing.email})'),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Would you like to merge contact details into the existing lead or save as a separate record?',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009647),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              String combinedEmail = existing.email;
              if (newBuyer.email.isNotEmpty && !combinedEmail.contains(newBuyer.email)) {
                combinedEmail = combinedEmail.isEmpty ? newBuyer.email : '$combinedEmail, ${newBuyer.email}';
              }
              String combinedNotes = existing.notes;
              if (newBuyer.notes.isNotEmpty && !combinedNotes.contains(newBuyer.notes)) {
                combinedNotes = combinedNotes.isEmpty ? newBuyer.notes : '$combinedNotes | ${newBuyer.notes}';
              }

              final mergedBuyer = existing.copyWith(
                email: combinedEmail,
                website: existing.website.isEmpty ? newBuyer.website : existing.website,
                phone: existing.phone.isEmpty ? newBuyer.phone : existing.phone,
                notes: combinedNotes,
              );

              Navigator.pop(dialogCtx);
              widget.onSave(mergedBuyer);
              Navigator.pop(parentContext);
            },
            child: const Text('Merge into Existing Lead'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onSave(newBuyer);
              Navigator.pop(parentContext);
            },
            child: const Text('Save as Separate Lead'),
          ),
        ],
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

  Widget _buildFormPair(bool isMobile, Widget child1, Widget child2) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 20),
        Expanded(child: child2),
      ],
    );
  }
}
