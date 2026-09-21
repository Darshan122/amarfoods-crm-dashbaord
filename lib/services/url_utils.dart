import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;

import 'template_service.dart';
import '../models/email_template.dart';
import '../models/buyer.dart';
import '../providers/buyer_provider.dart';

class UrlUtils {
  static Future<void> launchURL(String url) async {
    if (url.isEmpty || url == 'N/A') return;
    String target = url.trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://$target';
    }

    if (kIsWeb) {
      try {
        js.context.callMethod('open', [target, '_blank']);
      } catch (e) {
        debugPrint('UrlUtils: Web JS open failed, trying url_launcher: $e');
        final uri = Uri.parse(target);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } else {
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  static Future<void> launchEmail(String email) async {
    if (email.isEmpty) return;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email.trim(),
    );

    if (kIsWeb) {
      try {
        js.context.callMethod('open', [emailLaunchUri.toString(), '_blank']);
      } catch (e) {
        debugPrint('UrlUtils: Web JS mailto failed, trying url_launcher: $e');
        if (await canLaunchUrl(emailLaunchUri)) {
          await launchUrl(emailLaunchUri);
        }
      }
    } else {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    }
  }

  static Future<void> launchPhone(String phone) async {
    if (phone.isEmpty || phone == 'N/A') return;
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone.trim(),
    );

    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }

  // ─── Open a single Outlook Webmail compose window ──────────────────────────
  // Called synchronously to preserve user click stack and bypass browser popup blocking
  static void _openOutlookCompose({
    required String toEmail,
    required String subject,
    required String body,
  }) {
    final String url =
        'https://outlook.office.com/mail/deeplink/compose'
        '?to=${Uri.encodeComponent(toEmail)}'
        '&subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}';

    if (kIsWeb) {
      try {
        js.context.callMethod('open', [url, '_blank']);
      } catch (e) {
        launchURL(url);
      }
    } else {
      launchURL(url);
    }
  }

  /// Launch Outlook Webmail composer with multi-contact support.
  ///
  /// • 1 email   → opens Outlook directly, no dialog.
  /// • 2+ emails → shows dialog listing each contact with direct action buttons:
  ///                 - Click any contact's "Send Email" button to send to that person.
  ///                 - Click "Primary Only" to send to the first email.
  ///                 - Click "Send to All Privately" to open Outlook tabs for ALL contacts.
  static Future<void> launchEmailComposer({
    required String email,
    required String companyName,
    required bool isFirstEmail,
    int followupCount = 0,
    BuildContext? context,
    bool isExpoEmail = false,
    String? expoName,
    String? expoDate,
    String? stallNumber,
    String? contactPerson,
  }) async {
    // Parse all email addresses stored for this company
    final List<String> allEmails = email
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();

    if (allEmails.isEmpty) return;

    // Build subject & body from active template
    final templateService = TemplateService();
    if (!templateService.isInitialized) {
      await templateService.init();
    }
    final String templateType = isExpoEmail
        ? 'expo_first_email'
        : (isFirstEmail ? 'first_email' : 'followup');

    final EmailTemplate template = templateService.getTemplateForType(
      templateType,
      followupCount,
    );
    final String subject = TemplateService.processPlaceholders(
      template.subject,
      company: companyName,
      followupCount: followupCount,
      expoName: expoName,
      expoDate: expoDate,
      stallNumber: stallNumber,
      contactPerson: contactPerson,
    );
    final String body = TemplateService.processPlaceholders(
      template.body,
      company: companyName,
      followupCount: followupCount,
      expoName: expoName,
      expoDate: expoDate,
      stallNumber: stallNumber,
      contactPerson: contactPerson,
    );

    // ── SINGLE EMAIL: open Outlook directly, no dialog needed ──────────────
    if (allEmails.length == 1) {
      _openOutlookCompose(
        toEmail: allEmails.first,
        subject: subject,
        body: body,
      );
      return;
    }

    // ── MULTIPLE EMAILS: show confidential outreach dialog ─────────────────
    if (context == null || !(context.mounted)) {
      _openOutlookCompose(
        toEmail: allEmails.first,
        subject: subject,
        body: body,
      );
      return;
    }

    final bool? proceedToConfirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // Keep track of contacts whose Outlook tabs have been opened
        final Set<String> openedEmails = <String>{};

        return StatefulBuilder(
          builder: (context, setState) {
            final int openedCount = openedEmails.length;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.mark_email_unread_rounded,
                      color: Color(0xFF8B2C69), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Click "Send Email" for each contact to open Outlook in a new tab:',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  // List each email with direct "Send Email" action button
                  ...allEmails.asMap().entries.map((e) {
                    final emailStr = e.value;
                    final isOpened = openedEmails.contains(emailStr);
                    final isPrimary = e.key == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOpened ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOpened ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOpened
                                  ? Icons.check_circle_rounded
                                  : (isPrimary ? Icons.star_rounded : Icons.person_outline_rounded),
                              size: 16,
                              color: isOpened
                                  ? const Color(0xFF15803D)
                                  : (isPrimary ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emailStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOpened
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF334155),
                                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isOpened
                                        ? 'Tab Opened in Outlook ✅'
                                        : (isPrimary ? 'Primary Contact' : 'Secondary Contact'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isOpened ? const Color(0xFF15803D) : (isPrimary ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _openOutlookCompose(
                                  toEmail: emailStr,
                                  subject: subject,
                                  body: body,
                                );
                                setState(() {
                                  openedEmails.add(emailStr);
                                });
                              },
                              icon: Icon(
                                isOpened ? Icons.open_in_new_rounded : Icons.send_rounded,
                                size: 12,
                              ),
                              label: Text(
                                isOpened ? 'Open Again' : 'Send Email',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOpened ? const Color(0xFF15803D) : const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Confidential notice
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 13, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Confidential: Each email opens in its own Outlook tab with 1 recipient only. '
                            'Nobody knows others were contacted.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (openedCount == 0) {
                      _openOutlookCompose(
                        toEmail: allEmails.first,
                        subject: subject,
                        body: body,
                      );
                    }
                    Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: Text(
                    openedCount == 0
                        ? 'Open Primary & Proceed'
                        : 'Done ($openedCount Opened) → Proceed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2C69),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceedToConfirmation != true) return;
  }

  /// Option 1 + Option 2 Combined Double Safety Email Handler:
  ///
  /// 1. Opens Outlook Webmail composer.
  /// 2. Shows Option 1 Dialog: "Did you actually send the email?"
  ///    If user clicks "No, Keep in List", nothing changes.
  /// 3. If user clicks "Yes, Mark as Sent ✅", updates buyer status AND
  ///    shows Option 2 Undo Toast (SnackBar) with 10-second timer to undo.
  static Future<void> handleSendEmailWithConfirmation({
    required BuildContext context,
    required Buyer buyer,
    required BuyerProvider provider,
    bool? isExpoEmail,
    String? expoName,
    String? expoDate,
    String? stallNumber,
    String? contactPerson,
  }) async {
    // Keep a copy of the buyer before any mutation
    final previousBuyer = buyer;

    final isInitialEmail = buyer.firstEmailDate.trim().isEmpty;
    final bool useExpoTemplate = isExpoEmail ?? (buyer.connectionMethod.toLowerCase().contains('expo') && isInitialEmail);

    String? derivedExpoName = (expoName != null && expoName.trim().isNotEmpty) ? expoName.trim() : null;
    if (derivedExpoName == null && buyer.connectionMethod.toLowerCase().contains('expo')) {
      derivedExpoName = buyer.connectionMethod.replaceAll(RegExp(r'^Expo\s*[-–:]\s*', caseSensitive: false), '').trim();
    }

    String? derivedPerson = contactPerson;
    String? derivedStall = stallNumber;
    if (buyer.notes.isNotEmpty) {
      if (derivedPerson == null && buyer.notes.contains('Met:')) {
        final match = RegExp(r'Met:\s*([^|\]]+)').firstMatch(buyer.notes);
        if (match != null) derivedPerson = match.group(1)?.trim();
      }
      if (derivedStall == null && buyer.notes.contains('Booth:')) {
        final match = RegExp(r'Booth:\s*([^|\]]+)').firstMatch(buyer.notes);
        if (match != null) derivedStall = match.group(1)?.trim();
      }
    }

    // 1. Launch Outlook compose window(s)
    if (buyer.email.isNotEmpty) {
      await launchEmailComposer(
        email: buyer.email,
        companyName: buyer.company,
        isFirstEmail: isInitialEmail,
        followupCount: buyer.nextFollowupStep,
        context: context,
        isExpoEmail: useExpoTemplate,
        expoName: derivedExpoName,
        expoDate: expoDate ?? buyer.connectionDate,
        stallNumber: derivedStall,
        contactPerson: derivedPerson,
      );
    }

    if (!context.mounted) return;

    // 2. Option 1: Confirmation Dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Color(0xFF8B2C69), size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Did you send the email?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company: ${buyer.company}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Email: ${buyer.email}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Click "Yes, Mark as Sent" only if you completed sending the email in Outlook.\n\n'
                'If you clicked by mistake or did not send it, click "No, Keep in List".',
                style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.close_rounded, size: 15),
            label: const Text('No, Keep in List', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_rounded, size: 15),
            label: const Text('Yes, Mark as Sent ✅', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    // If user selected "No, Keep in List" or closed dialog -> DO NOT MARK AS SENT
    if (confirmed != true) return;

    // 3. Perform Mark as Sent
    await provider.markEmailSent(buyer.id, targetBuyer: buyer);

    if (!context.mounted) return;

    // 4. Option 2: Show Undo Toast (SnackBar) with 10s duration
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Marked "${buyer.company}" as Email Sent',
                style: const TextStyle(fontSize: 13, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO ↩',
          textColor: const Color(0xFFFACC15),
          onPressed: () async {
            await provider.revertBuyer(previousBuyer);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 4),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.undo_rounded, color: Color(0xFFFACC15), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Restored "${buyer.company}" back to list',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LINKEDIN OUTREACH & SMART-ASSISTED FOLLOW-UP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens LinkedIn profile or company search
  static void launchLinkedInProfile(Buyer buyer) {
    String url = buyer.website.trim();
    if (url.toLowerCase().contains('linkedin.com')) {
      launchURL(url);
      return;
    }

    // If website is not a direct LinkedIn link, open company search on LinkedIn
    final cleanComp = buyer.company.trim();
    final searchUrl = 'https://www.linkedin.com/search/results/all/?keywords=${Uri.encodeComponent(cleanComp)}';
    launchURL(searchUrl);
  }

  /// Interactive LinkedIn Outreach Dialog:
  /// 1. Pre-fills the stage-appropriate message (Connect Note, First Intro, Follow-up 1, 2, 3)
  /// 2. Displays live character count (< 300 chars limit for connection notes)
  /// 3. 1-Click Copy to clipboard
  /// 4. 1-Click Open LinkedIn Profile / Chat
  /// 5. 1-Click Mark as Contacted & auto-schedule next reminder (+4 to +7 days)
  static Future<void> handleLinkedInOutreachDialog({
    required BuildContext context,
    required Buyer buyer,
    required BuyerProvider provider,
  }) async {
    final templateService = TemplateService();
    if (!templateService.isInitialized) {
      await templateService.init();
    }

    EmailTemplate currentTemplate = templateService.getLinkedInTemplateForFollowup(buyer.followupCount);
    final textCtrl = TextEditingController();

    void updateText(EmailTemplate tpl) {
      textCtrl.text = TemplateService.processPlaceholders(
        tpl.body,
        company: buyer.company,
        followupCount: buyer.followupCount,
      );
    }

    updateText(currentTemplate);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final int charCount = textCtrl.text.length;
            final bool isConnectNote = currentTemplate.type == 'linkedin_connect';
            final bool isOverLimit = isConnectNote && charCount > 300;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 680,
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
                              color: const Color(0xFF0A66C2).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.business_center_rounded, color: Color(0xFF0A66C2), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      buyer.company,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A66C2).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF0A66C2).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'LinkedIn Follow-up #${buyer.followupCount}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0A66C2)),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Smart LinkedIn outreach — copy message, open chat, and log reminder.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Stage Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF475569)),
                            const SizedBox(width: 10),
                            const Text('Select Stage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentTemplate.type,
                                  isDense: true,
                                  items: templateService.linkedInTemplates.map((t) {
                                    return DropdownMenuItem<String>(
                                      value: t.type,
                                      child: Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (newType) {
                                    if (newType != null) {
                                      setDialogState(() {
                                        currentTemplate = templateService.getTemplateForType(newType, buyer.followupCount);
                                        updateText(currentTemplate);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Character count banner (especially crucial for 300 char connection note limit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isConnectNote ? 'CONNECTION NOTE (< 300 CHARS):' : 'LINKEDIN MESSAGE:',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverLimit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isOverLimit ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
                            ),
                            child: Text(
                              isConnectNote ? '$charCount / 300 chars' : '$charCount chars',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOverLimit ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Message Body Field
                      TextField(
                        controller: textCtrl,
                        maxLines: 7,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type your message text here...',
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons: Copy, Open Profile, Mark Sent
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.end,
                        children: [
                          // 1. Copy Message Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: textCtrl.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                                      SizedBox(width: 8),
                                      Text('Copied LinkedIn message to clipboard!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF0F172A),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  width: 320,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),

                          // 2. Open LinkedIn Profile / Search
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A66C2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => launchLinkedInProfile(buyer),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open LinkedIn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),

                          // 3. Mark Follow-Up Sent & Auto-Schedule Next Reminder
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009647),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await provider.markEmailSent(buyer.id, targetBuyer: buyer);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '✅ Logged LinkedIn outreach for "${buyer.company}" & scheduled next follow-up!',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF0F172A),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    width: 440,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.task_alt_rounded, size: 16),
                            label: const Text('Mark Sent & Set Follow-Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
}
