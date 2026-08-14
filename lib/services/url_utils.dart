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

    final String? choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
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
              'This company has ${allEmails.length} email contacts.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            // List each email with direct "Send Email" action button
            ...allEmails.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: e.key == 0 ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: e.key == 0 ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          e.key == 0
                              ? Icons.star_rounded
                              : Icons.person_outline_rounded,
                          size: 16,
                          color: e.key == 0
                              ? const Color(0xFF15803D)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: e.key == 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF334155),
                                  fontWeight: e.key == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (e.key == 0)
                                const Text(
                                  'Primary Contact',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx, 'email:${e.value}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send_rounded, size: 10, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text('Send Email', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
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
                      'Confidential: Each person gets a separate Outlook email. '
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
            onPressed: () => Navigator.pop(ctx, 'primary'),
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
            onPressed: () => Navigator.pop(ctx, 'all'),
            icon: const Icon(Icons.send_rounded, size: 14),
            label: Text('Send to All ${allEmails.length} Privately',
                style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2C69),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (choice == null) return; // User cancelled

    if (choice == 'primary') {
      _openOutlookCompose(
        toEmail: allEmails.first,
        subject: subject,
        body: body,
      );
    } else if (choice == 'all') {
      // Synchronously open a SEPARATE Outlook tab for each email.
      // Each window has exactly 1 recipient in TO — no CC, no BCC.
      for (final singleEmail in allEmails) {
        _openOutlookCompose(
          toEmail: singleEmail,
          subject: subject,
          body: body,
        );
      }
    } else if (choice.startsWith('email:')) {
      final targetEmail = choice.substring('email:'.length);
      _openOutlookCompose(
        toEmail: targetEmail,
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
