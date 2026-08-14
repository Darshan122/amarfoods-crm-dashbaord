import 'package:flutter/material.dart';
import '../../models/email_template.dart';
import '../../services/template_service.dart';

class EmailTemplatesView extends StatefulWidget {
  const EmailTemplatesView({super.key});

  @override
  State<EmailTemplatesView> createState() => _EmailTemplatesViewState();
}

class _EmailTemplatesViewState extends State<EmailTemplatesView> {
  final TemplateService _templateService = TemplateService();

  @override
  void initState() {
    super.initState();
    _templateService.init();
    _templateService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _templateService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _showEditTemplateDialog([EmailTemplate? template]) {
    final bool isEditing = template != null;
    final nameCtrl = TextEditingController(text: template?.name ?? '');
    final subjectCtrl = TextEditingController(text: template?.subject ?? '');
    final bodyCtrl = TextEditingController(text: template?.body ?? '');
    String selectedType = template?.type ?? 'custom';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sampleSubject = TemplateService.processPlaceholders(
              subjectCtrl.text,
              company: 'Pacific Spice Co.',
              followupCount: 1,
            );
            final sampleBody = TemplateService.processPlaceholders(
              bodyCtrl.text,
              company: 'Pacific Spice Co.',
              followupCount: 1,
            );

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 780,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Edit Template: ${template.name}' : 'Create Custom Template',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const Text(
                                  'Customize your pre-filled email subject and body text.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      // Name & Type
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TEMPLATE NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., First Email (Initial Outreach)',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('STAGE TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedType,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'first_email', child: Text('First Email')),
                                        DropdownMenuItem(value: 'followup_1', child: Text('Follow-Up 1')),
                                        DropdownMenuItem(value: 'followup_2', child: Text('Follow-Up 2')),
                                        DropdownMenuItem(value: 'followup_3', child: Text('Follow-Up 3+')),
                                        DropdownMenuItem(value: 'custom', child: Text('Custom')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => selectedType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Tag Insertion Chips
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Text('Insert Variable Tag:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(width: 10),
                            ActionChip(
                              label: const Text('+ {company}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              backgroundColor: const Color(0xFFEFF6FF),
                              onPressed: () {
                                setDialogState(() {
                                  bodyCtrl.text = '${bodyCtrl.text} {company}';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('+ {followup_count}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              backgroundColor: const Color(0xFFFEF3C7),
                              onPressed: () {
                                setDialogState(() {
                                  bodyCtrl.text = '${bodyCtrl.text} {followup_count}';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Subject Line
                      const Text('SUBJECT LINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: subjectCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'e.g., Product Inquiry & Introduction - Amar Foods ({company})',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Body Text Area
                      const Text('EMAIL BODY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: bodyCtrl,
                        maxLines: 8,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type your email text here. Use {company} for company name.',
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Preview Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF475569)),
                                SizedBox(width: 6),
                                Text('LIVE SAMPLE PREVIEW (Sample Buyer: Pacific Spice Co.)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Subject: $sampleSubject', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const Divider(height: 16, color: Color(0xFFCBD5E1)),
                            Text(sampleBody, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter template name and subject.')),
                                );
                                return;
                              }

                              final updated = EmailTemplate(
                                id: template?.id ?? 'tpl_${DateTime.now().millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                                type: selectedType,
                                subject: subjectCtrl.text.trim(),
                                body: bodyCtrl.text,
                                isDefault: template?.isDefault ?? false,
                              );

                              await _templateService.saveTemplate(updated);
                              if (mounted && ctx.mounted) Navigator.of(ctx).pop();
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Save Template', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _templateService.templates;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Email Template Manager',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and edit pre-filled email subjects & bodies. Edits persist instantly without code changes.',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF818CF8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await _templateService.resetToDefaults();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restored all email templates to default!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showEditTemplateDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Template', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Template Cards Grid
          Expanded(
            child: templates.isEmpty
                ? const Center(child: Text('No email templates found.'))
                : ListView.separated(
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final t = templates[index];
                      Color badgeColor = const Color(0xFF2563EB);
                      Color badgeBg = const Color(0xFFEFF6FF);

                      if (t.type == 'first_email') {
                        badgeColor = const Color(0xFF8B2C69);
                        badgeBg = const Color(0xFFFDF4FF);
                      } else if (t.type == 'followup_1') {
                        badgeColor = const Color(0xFFD97706);
                        badgeBg = const Color(0xFFFEF3C7);
                      } else if (t.type == 'followup_2') {
                        badgeColor = const Color(0xFF2563EB);
                        badgeBg = const Color(0xFFEFF6FF);
                      } else if (t.type == 'followup_3') {
                        badgeColor = const Color(0xFF059669);
                        badgeBg = const Color(0xFFD1FAE5);
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.type.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  t.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Edit Template',
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                                  onPressed: () => _showEditTemplateDialog(t),
                                ),
                                if (!t.isDefault)
                                  IconButton(
                                    tooltip: 'Delete Template',
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Delete Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          content: Text('Are you sure you want to delete "${t.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _templateService.deleteTemplate(t.id);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(text: 'Subject: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                                  TextSpan(text: t.subject, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Text(
                                t.body,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
