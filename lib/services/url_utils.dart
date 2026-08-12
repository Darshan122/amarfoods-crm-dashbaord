import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;

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

  /// Launch pre-filled email draft in Gmail Web or Default Email Client (100% Free)
  static Future<void> launchEmailComposer({
    required String email,
    required String companyName,
    required bool isFirstEmail,
    int followupCount = 0,
  }) async {
    final List<String> allEmails = email
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (allEmails.isEmpty) return;

    final String recipientList = allEmails.join(';');

    final String company = companyName.isNotEmpty ? companyName : 'Importer';

    final String subject = isFirstEmail
        ? 'Product Inquiry & Introduction - Amar Foods ($company)'
        : 'Following Up: Amar Foods Inquiry - $company (Follow-Up #${followupCount > 0 ? followupCount : 1})';

    final String body = isFirstEmail
        ? '''Dear Purchasing Department / Trade Manager ($company),

Greetings from Amar Foods!

We specialize in exporting high-quality Dehydrated Onion, Garlic, and Food Products. We would love to discuss potential supply and partnership opportunities with $company.

Could you please share your current purchasing requirements or connect us with your procurement manager?

Best regards,
Amar Foods Export Division
Dehydrated Onion & Garlic Specialist'''
        : '''Dear Purchasing Team ($company),

I hope this email finds you well.

I am following up on our previous communication regarding Dehydrated Onion & Garlic supply from Amar Foods.

Please let us know if you have any questions or require updated product specifications, catalog, or pricing for $company.

Best regards,
Amar Foods Export Division''';

    // 1. Official Microsoft 365 Outlook Webmail Deeplink Compose URL (Works for amar@amarfoods.in / cloud.microsoft)
    final String outlookOfficeUrl =
        'https://outlook.office.com/mail/deeplink/compose?to=${Uri.encodeComponent(recipientList)}&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    // 2. Office 365 Secondary Deeplink Compose URL
    final String office365Url =
        'https://outlook.office365.com/mail/deeplink/compose?to=${Uri.encodeComponent(recipientList)}&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    // 3. Outlook Personal Live Webmail fallback
    final String outlookLiveUrl =
        'https://outlook.live.com/mail/0/deeplink/compose?to=${Uri.encodeComponent(recipientList)}&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    // 4. Gmail Web Compose fallback
    final String gmailUrl =
        'https://mail.google.com/mail/?view=cm&fs=1&to=${Uri.encodeComponent(recipientList)}&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    try {
      // Primary: outlook.office.com (Official Microsoft 365 Webmail Deeplink)
      await launchURL(outlookOfficeUrl);
    } catch (e) {
      debugPrint('UrlUtils: Outlook Office launch failed, trying Office 365: $e');
      try {
        await launchURL(office365Url);
      } catch (e2) {
        debugPrint('UrlUtils: Office 365 launch failed, trying Outlook Live: $e2');
        try {
          await launchURL(outlookLiveUrl);
        } catch (e3) {
          try {
            await launchURL(gmailUrl);
          } catch (e4) {
            final Uri mailtoUri = Uri(
              scheme: 'mailto',
              path: recipientList,
              queryParameters: {
                'subject': subject,
                'body': body,
              },
            );
            if (await canLaunchUrl(mailtoUri)) {
              await launchUrl(mailtoUri);
            }
          }
        }
      }
    }
  }
}
