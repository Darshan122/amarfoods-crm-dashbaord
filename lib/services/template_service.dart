import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_template.dart';

class TemplateService extends ChangeNotifier {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _storageKey = 'amar_crm_email_templates_v5';
  List<EmailTemplate> _templates = [];

  List<EmailTemplate> get templates => List.unmodifiable(_templates);
  List<EmailTemplate> get emailTemplates => _templates.where((t) => !t.isLinkedIn).toList();
  List<EmailTemplate> get linkedInTemplates => _templates.where((t) => t.isLinkedIn).toList();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _templates = decoded.map((e) => EmailTemplate.fromJson(e)).toList();

        // Ensure all default templates (including LinkedIn) exist
        final defaultTemplates = getDefaultTemplates();
        bool addedNew = false;
        for (final defTpl in defaultTemplates) {
          if (!_templates.any((t) => t.id == defTpl.id)) {
            _templates.add(defTpl);
            addedNew = true;
          }
        }
        if (addedNew) {
          await _saveToStorage();
        }
      } else {
        _templates = getDefaultTemplates();
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('TemplateService: Error loading templates: $e');
      _templates = getDefaultTemplates();
    }
    _isInitialized = true;
    notifyListeners();
  }

  static List<EmailTemplate> getDefaultTemplates() {
    return [
      // ═══════════════════════════════════════════════════════════════════════
      // 1. EMAIL OUTREACH TEMPLATES — Relationship-first, research-backed
      //    Rule: Build the relationship → then naturally mention products.
      //    Keep under 120 words. No attachments. One clear question at end.
      // ═══════════════════════════════════════════════════════════════════════

      // ── EXPO FOLLOW-UP ──────────────────────────────────────────────────────
      EmailTemplate(
        id: 'tpl_expo_first_email',
        name: 'Expo First Email (Stall Visit Follow-up)',
        type: 'expo_first_email',
        channel: 'email',
        subject: 'Great meeting you at {expo_name} — Amar Foods',
        body: '''Dear {contact_person},

It was a genuine pleasure speaking with you at {expo_name}. I came away from our conversation with a much better sense of what {company} looks for in its ingredient suppliers.

As promised, I am following up. Our range covers dehydrated onion (white, red & pink), garlic, Indian spices like cumin and turmeric, crispy fried onion, ginger, moringa, sesame seeds, and more — all manufactured and exported directly from our facility in Mahuva, Gujarat.

There is absolutely no rush. Whenever you are ready — whether for a specific inquiry, pricing, or lab samples — just reach out and I will arrange everything promptly.

Looking forward to staying in touch.

Warm regards,
Darshan Zalavadiya
Export Sales | Amar Foods, Mahuva — India
📞 WhatsApp: +91 7284088737
✉ export@amarfoods.in
🌐 https://amarfoods.in''',
        isDefault: true,
      ),

      // ── FIRST COLD EMAIL ────────────────────────────────────────────────────
      EmailTemplate(
        id: 'tpl_first_email',
        name: 'First Email (Cold Introduction)',
        type: 'first_email',
        channel: 'email',
        subject: 'A question about ingredient sourcing at {company}',
        body: '''Dear {contact_person},

I hope you are having a good week.

I came across {company} while researching importers in your region and was genuinely impressed by your work. That is what prompted me to reach out.

We are Amar Foods — a direct manufacturer and exporter based in Mahuva, Gujarat, India. We produce a wide range of dehydrated vegetables, Indian spices, crispy fried onion, sesame seeds, and herbal powders. Our facility is FSSAI, APEDA & ISO 22000 certified, and we supply food processors and spice blenders across Europe, the Middle East, and Southeast Asia.

I would love to understand {company}'s sourcing priorities — even if it is just to be on your list for the future.

Would you be open to a brief introduction?

Warm regards,
Darshan Zalavadiya
Export Sales | Amar Foods, Mahuva — India
📞 WhatsApp: +91 7284088737
✉ export@amarfoods.in
🌐 https://amarfoods.in''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 1 — Soft Check-In (Day 4–5) ───────────────────────────────
      EmailTemplate(
        id: 'tpl_followup_1',
        name: 'Follow-Up 1 (Soft Check-In, Day 4–5)',
        type: 'followup_1',
        channel: 'email',
        subject: 'Re: Ingredient sourcing at {company}',
        body: '''Hi {contact_person},

I know how quickly inboxes fill up — just wanted to make sure my previous note did not get buried.

No pressure at all. If the timing is not right for {company} right now, I completely understand and am happy to reconnect whenever suits you better.

That said, if there is anything from our range — dehydrated vegetables, Indian spices, or specialty items — where a quick spec sheet or current pricing would be helpful, just let me know.

Hope you have a great week ahead.

Best regards,
Darshan Zalavadiya
Amar Foods | +91 7284088737
https://amarfoods.in''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 2 — Free Sample Offer (Day 9) ─────────────────────────────
      EmailTemplate(
        id: 'tpl_followup_2',
        name: 'Follow-Up 2 (Free Sample Offer, Day 9)',
        type: 'followup_2',
        channel: 'email',
        subject: 'Complimentary sample kit for {company}\'s quality team?',
        body: '''Hi {contact_person},

I wanted to reach out with something that may be genuinely useful.

We regularly send complimentary sample kits to new trade partners — a curated selection from our range (dehydrated onion, garlic, Indian spices such as cumin or turmeric, sesame seeds, or any specific item of interest), along with full COA lab reports and specification sheets for your quality team's evaluation.

It is a completely no-obligation way to experience the quality we stand behind — before any conversation about pricing or volumes.

Would a sample kit be useful for {company}? If yes, simply share your preferred delivery address and I will arrange the shipment right away.

Best regards,
Darshan Zalavadiya
Amar Foods, Mahuva — India
📞 +91 7284088737 (WhatsApp)
🌐 https://amarfoods.in | Products: https://amarfoods.in/#/products''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 3+ — Graceful Exit (Day 18+) ──────────────────────────────
      EmailTemplate(
        id: 'tpl_followup_3',
        name: 'Follow-Up 3+ (Graceful Exit, Day 18+)',
        type: 'followup_3',
        channel: 'email',
        subject: 'Keeping in touch — Amar Foods',
        body: '''Hi {contact_person},

I understand that sourcing timelines and priorities differ for every company, and I respect that completely.

I will not keep filling your inbox — but I did want to leave you with our full product catalog (https://amarfoods.in/#/products) in case anything is relevant down the line. Our range includes dehydrated alliums, Indian spices, crispy fried onion, pure ginger, moringa, sesame seeds, and much more — all exported directly from our manufacturing facility in Mahuva, India.

Whenever {company} has a new buying cycle or a specific ingredient need, please do not hesitate to reach out. I am always available on WhatsApp (+91 7284088737) for a quick conversation.

Wishing you the very best.

Warm regards,
Darshan Zalavadiya
Export Sales | Amar Foods
🌐 https://amarfoods.in''',
        isDefault: true,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 2. LINKEDIN OUTREACH TEMPLATES
      //    Rule: Open the door, don't close a sale.
      //    No product pitch in connection request.
      //    Research: Personalized notes = 3x higher acceptance rate.
      // ═══════════════════════════════════════════════════════════════════════

      // ── CONNECTION REQUEST (<300 chars) ──────────────────────────────────────
      EmailTemplate(
        id: 'tpl_linkedin_connect',
        name: 'LinkedIn: Connection Request Note (< 300 chars)',
        type: 'linkedin_connect',
        channel: 'linkedin',
        subject: 'Connection Request Note (< 300 chars)',
        body: 'Hi {contact_person}, I follow {company}\'s work in the food space with interest. We are a dehydrated vegetable & Indian spice manufacturer based in Mahuva, India. Would love to connect and follow your updates!',
        isDefault: true,
      ),

      // ── WELCOME (POST-ACCEPTANCE) ────────────────────────────────────────────
      EmailTemplate(
        id: 'tpl_linkedin_welcome',
        name: 'LinkedIn: Welcome Message (Post-Acceptance)',
        type: 'linkedin_welcome',
        channel: 'linkedin',
        subject: 'Welcome & Brief Introduction',
        body: '''Hi {contact_person}, thanks for connecting!

A brief intro: Amar Foods is a direct manufacturer and exporter based in Mahuva, Gujarat. We produce dehydrated onion (white, red & pink), garlic, Indian spices (cumin, turmeric, coriander), crispy fried onion, sesame seeds, ginger, moringa, and more — supplying food processors and spice blenders globally.

All products are FSSAI, APEDA & ISO 22000 certified, with COA documentation per batch.

Is {company} currently sourcing any of these ingredients? Happy to share our catalog or arrange sample kits — no pressure at all.''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 1 — Free Sample (Day 4) ───────────────────────────────────
      EmailTemplate(
        id: 'tpl_linkedin_followup_1',
        name: 'LinkedIn: Follow-Up 1 (Free Sample Offer, Day 4)',
        type: 'linkedin_followup_1',
        channel: 'linkedin',
        subject: 'Complimentary Sample Offer (Day 4)',
        body: '''Hi {contact_person}, following up on my previous note.

We are currently scheduling international sample dispatches. Would your quality team at {company} find it useful to receive a complimentary evaluation pack of our dehydrated vegetables or Indian spices — along with COA lab reports?

Happy to arrange it if there is any interest.''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 2 — Market Update & WhatsApp (Day 10) ─────────────────────
      EmailTemplate(
        id: 'tpl_linkedin_followup_2',
        name: 'LinkedIn: Follow-Up 2 (Market Update + WhatsApp, Day 10)',
        type: 'linkedin_followup_2',
        channel: 'linkedin',
        subject: 'Fresh Crop Update & WhatsApp (Day 10)',
        body: '''Hi {contact_person}, our new crop processing cycle is currently active in Mahuva, and spot rates for dehydrated onion and garlic are particularly competitive this season.

If you prefer quick communication over WhatsApp for pricing or availability updates, feel free to reach me at +91 7284088737. Wishing you a productive week!''',
        isDefault: true,
      ),

      // ── FOLLOW-UP 3 — Full Catalog & Graceful Close (Day 20) ────────────────
      EmailTemplate(
        id: 'tpl_linkedin_followup_3',
        name: 'LinkedIn: Follow-Up 3 (Full Catalog + Graceful Close, Day 20)',
        type: 'linkedin_followup_3',
        channel: 'linkedin',
        subject: 'Full Product Catalog & Staying in Touch (Day 20)',
        body: '''Hi {contact_person}, sharing our full export product catalog (https://amarfoods.in/#/products) for your reference — 47+ items including dehydrated alliums, Indian spices, crispy fried onion, sesame seeds, pure ginger, and herbal powders.

Do reach out whenever {company} has a new ingredient requirement or buying cycle. Always happy to assist!''',
        isDefault: true,
      ),
    ];
  }

  EmailTemplate getTemplateForType(String type, int followupCount) {
    if (!_isInitialized || _templates.isEmpty) {
      _templates = getDefaultTemplates();
    }

    // LinkedIn templates
    if (type.startsWith('linkedin')) {
      final match = _templates.firstWhere(
        (t) => t.type == type,
        orElse: () => getDefaultTemplates().firstWhere((t) => t.type == type, orElse: () => getDefaultTemplates()[5]),
      );
      return match;
    }

    // Email templates
    if (type == 'expo_first_email') {
      return _templates.firstWhere(
        (t) => t.type == 'expo_first_email',
        orElse: () => getDefaultTemplates().firstWhere((t) => t.type == 'expo_first_email'),
      );
    } else if (type == 'first_email') {
      return _templates.firstWhere(
        (t) => t.type == 'first_email',
        orElse: () => getDefaultTemplates().firstWhere((t) => t.type == 'first_email'),
      );
    } else {
      if (followupCount <= 1) {
        return _templates.firstWhere(
          (t) => t.type == 'followup_1',
          orElse: () => _templates.firstWhere(
            (t) => t.type == 'first_email',
            orElse: () => getDefaultTemplates()[2],
          ),
        );
      } else if (followupCount == 2) {
        return _templates.firstWhere(
          (t) => t.type == 'followup_2',
          orElse: () => getDefaultTemplates()[3],
        );
      } else {
        return _templates.firstWhere(
          (t) => t.type == 'followup_3',
          orElse: () => getDefaultTemplates()[4],
        );
      }
    }
  }

  /// Selects the ideal LinkedIn message based on buyer's follow-up count
  EmailTemplate getLinkedInTemplateForFollowup(int followupCount) {
    if (!_isInitialized || _templates.isEmpty) {
      _templates = getDefaultTemplates();
    }

    if (followupCount == 0) {
      return _templates.firstWhere((t) => t.type == 'linkedin_connect', orElse: () => getDefaultTemplates()[5]);
    } else if (followupCount == 1) {
      return _templates.firstWhere((t) => t.type == 'linkedin_welcome', orElse: () => getDefaultTemplates()[6]);
    } else if (followupCount == 2) {
      return _templates.firstWhere((t) => t.type == 'linkedin_followup_1', orElse: () => getDefaultTemplates()[7]);
    } else if (followupCount == 3) {
      return _templates.firstWhere((t) => t.type == 'linkedin_followup_2', orElse: () => getDefaultTemplates()[8]);
    } else {
      return _templates.firstWhere((t) => t.type == 'linkedin_followup_3', orElse: () => getDefaultTemplates()[9]);
    }
  }

  Future<void> saveTemplate(EmailTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      _templates[index] = template;
    } else {
      final stageIndex = _templates.indexWhere((t) => t.type == template.type && template.type != 'custom');
      if (stageIndex >= 0) {
        _templates[stageIndex] = template;
      } else {
        _templates.add(template);
      }
    }
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _templates = getDefaultTemplates();
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(_templates.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('TemplateService: Error saving templates: $e');
    }
  }

  /// Process subject and body string with dynamic buyer tags
  static String processPlaceholders(String text, {
    required String company,
    required int followupCount,
    String? expoName,
    String? expoDate,
    String? stallNumber,
    String? contactPerson,
  }) {
    String cleanCompany = company.isNotEmpty ? company : 'Valued Partner';
    String cleanExpoName = (expoName != null && expoName.trim().isNotEmpty) ? expoName.trim() : 'FI India 2026';
    String cleanExpoDate = (expoDate != null && expoDate.trim().isNotEmpty) ? expoDate.trim() : '';
    String cleanStall = (stallNumber != null && stallNumber.trim().isNotEmpty) ? '(${stallNumber.trim()})' : '';
    String cleanPerson = (contactPerson != null && contactPerson.trim().isNotEmpty)
        ? contactPerson.trim()
        : '';

    // If contact person is missing, give a natural greeting
    if (cleanPerson.isEmpty) {
      cleanPerson = cleanCompany.isNotEmpty ? cleanCompany : 'Trade Partner';
    }

    String processed = text
        .replaceAll(RegExp(r'\{\{?\s*(company|Company)\s*\}?\}'), cleanCompany)
        .replaceAll(RegExp(r'\{\{?\s*followup_count\s*\}?\}', caseSensitive: false), followupCount > 0 ? followupCount.toString() : '1')
        .replaceAll(RegExp(r'\{\{?\s*expo_name\s*\}?\}', caseSensitive: false), cleanExpoName)
        .replaceAll(RegExp(r'\{\{?\s*stall_number\s*\}?\}', caseSensitive: false), cleanStall)
        .replaceAll(RegExp(r'\{\{?\s*(contact_person|name|Name)\s*\}?\}'), cleanPerson);

    if (cleanExpoDate.isNotEmpty) {
      processed = processed.replaceAll(RegExp(r'\{\{?\s*expo_date\s*\}?\}', caseSensitive: false), cleanExpoDate);
      processed = processed.replaceAll(RegExp(r'on\s+recent\s+event', caseSensitive: false), 'on $cleanExpoDate');
    } else {
      processed = processed
          .replaceAll(RegExp(r'\s*on\s*\{\{?\s*expo_date\s*\}?\}', caseSensitive: false), '')
          .replaceAll(RegExp(r'\{\{?\s*expo_date\s*\}?\}', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*on\s+recent\s+event', caseSensitive: false), '');
    }

    return processed;
  }
}
