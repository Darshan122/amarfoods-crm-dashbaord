import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final EmailTemplate template = templateService.getTemplateForType(
      isFirstEmail ? 'first_email' : 'followup',
      followupCount,
    );
    final String subject = TemplateService.processPlaceholders(
      template.subject,
      company: companyName,
      followupCount: followupCount,
    );
    final String body = TemplateService.processPlaceholders(
      template.body,
      company: companyName,
      followupCount: followupCount,
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

    final List<String>? selectedEmails = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // Pre-select ALL emails by default
        final Set<String> checkedEmails = Set<String>.from(allEmails);

        return StatefulBuilder(
          builder: (context, setState) {
            final int selectedCount = checkedEmails.length;

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
                    'Select contacts to email (${allEmails.length} available):',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  // Checkbox list for each email contact
                  ...allEmails.asMap().entries.map((e) {
                    final emailStr = e.value;
                    final isChecked = checkedEmails.contains(emailStr);
                    final isPrimary = e.key == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              checkedEmails.remove(emailStr);
                            } else {
                              checkedEmails.add(emailStr);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? (isPrimary ? const Color(0xFFF0FDF4) : const Color(0xFFF0F9FF))
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isChecked
                                  ? (isPrimary ? const Color(0xFF86EFAC) : const Color(0xFFBAE6FD))
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: isChecked,
                                  activeColor: isPrimary ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        checkedEmails.add(emailStr);
                                      } else {
                                        checkedEmails.remove(emailStr);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emailStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isChecked
                                            ? (isPrimary ? const Color(0xFF15803D) : const Color(0xFF0369A1))
                                            : const Color(0xFF64748B),
                                        fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isPrimary)
                                      const Text(
                                        'Primary Contact',
                                        style: TextStyle(fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                            'Confidential: Each selected person gets a separate Outlook tab. '
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
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF64748B))),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx, [allEmails.first]);
                  },
                  icon: const Icon(Icons.star_rounded, size: 14),
                  label: const Text('Primary Only', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF15803D),
                    side: const BorderSide(color: Color(0xFF15803D)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          Navigator.pop(ctx, checkedEmails.toList());
                        },
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: Text('Open $selectedCount Selected in Outlook',
                      style: const TextStyle(fontSize: 12)),
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

    if (selectedEmails == null || selectedEmails.isEmpty) return; // User cancelled or none selected

    // Open a SEPARATE Outlook tab for each checked email synchronously
    for (final singleEmail in selectedEmails) {
      _openOutlookCompose(
        toEmail: singleEmail,
        subject: subject,
        body: body,
      );
    }
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
  }) async {
    // Keep a copy of the buyer before any mutation
    final previousBuyer = buyer;

    // 1. Launch Outlook compose window(s)
    if (buyer.email.isNotEmpty) {
      await launchEmailComposer(
        email: buyer.email,
        companyName: buyer.company,
        isFirstEmail: buyer.firstEmailDate.isEmpty,
        followupCount: buyer.followupCount,
        context: context,
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
    await provider.markEmailSent(buyer.id);

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
}
