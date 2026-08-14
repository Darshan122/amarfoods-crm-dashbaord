import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;

import 'template_service.dart';
import '../models/email_template.dart';

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
  // Each call opens ONE window with ONE recipient (confidential outreach).
  static Future<void> _openOutlookCompose({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    // Microsoft 365 / Work Outlook deeplink
    final String url =
        'https://outlook.office.com/mail/deeplink/compose'
        '?to=${Uri.encodeComponent(toEmail)}'
        '&subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}';
    await launchURL(url);
  }

  /// Launch Outlook Webmail composer with confidential multi-contact support.
  ///
  /// • 1 email  → opens Outlook directly, no dialog.
  /// • 2+ emails → shows dialog:
  ///     [Primary Only]       Opens 1 Outlook window for the first/primary email.
  ///     [Send to All Privately]  Opens a SEPARATE Outlook window per email,
  ///                          each with exactly 1 TO address — no CC, no BCC.
  ///                          Recipients never know others were contacted.
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
      await _openOutlookCompose(
        toEmail: allEmails.first,
        subject: subject,
        body: body,
      );
      return;
    }

    // ── MULTIPLE EMAILS: show confidential outreach dialog ─────────────────
    if (context == null || !(context.mounted)) {
      // No context available — fall back to primary email only
      await _openOutlookCompose(
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
            // List all emails for reference
            ...allEmails.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        e.key == 0
                            ? Icons.star_rounded
                            : Icons.person_outline_rounded,
                        size: 14,
                        color: e.key == 0
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
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
                      ),
                      if (e.key == 0)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Primary',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
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
      // Send to primary (first) email only — 1 Outlook window
      await _openOutlookCompose(
        toEmail: allEmails.first,
        subject: subject,
        body: body,
      );
    } else if (choice == 'all') {
      // Open a SEPARATE Outlook window for each email, one by one.
      // Each window has exactly 1 recipient in TO — no CC, no BCC.
      // Each person thinks they are the only one contacted.
      for (final singleEmail in allEmails) {
        await _openOutlookCompose(
          toEmail: singleEmail,
          subject: subject,
          body: body,
        );
        // Small delay so browser doesn't block multiple popup windows
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }
  }
}
