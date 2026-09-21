import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_template.dart';

class TemplateService extends ChangeNotifier {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _storageKey = 'amar_crm_email_templates_v4';
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
      // 1. EMAIL OUTREACH TEMPLATES
      // ═══════════════════════════════════════════════════════════════════════
      EmailTemplate(
        id: 'tpl_expo_first_email',
        name: 'Expo First Email (Stall Visit Follow-up)',
        type: 'expo_first_email',
        channel: 'email',
        subject: 'Pleasure meeting you at {expo_name} | Amar Foods — Product Catalog & Collaboration',
        body: '''Dear {contact_person},

Greetings from Amar Foods!

I hope this message finds you well.

It was a real pleasure meeting you at {expo_name} on {expo_date}, and I would like to express my sincere gratitude for the engaging discussion we had regarding potential collaborations and business opportunities in the industry.

As we discussed regarding our premium quality Dehydrated Food Products — including Dehydrated Onion (Flakes, Minced, Chopped, Powder), Dehydrated Garlic (Granules, Powder), and Agro Spices — we are enthusiastic about exploring ways to work together and cater to {company}'s requirements.

As discussed at the event, I have attached our latest Product Catalog & Company Profile for your review.

Please let me know if you require any additional information, product specifications, or custom pricing (FOB / CIF). We would also be very glad to dispatch product samples for your quality evaluation. I look forward to your response and hope to continue our conversation soon.

Thank you once again for your valuable time and insights. We truly believe in exceptional product quality, consistency, and long-term customer assurance.

Thanks & Regards,

Darshan Zalavadiya
Export Sales Executive
Amar Foods | India
Mob / WhatsApp: +91 7284088737
Email: export@amarfoods.in
Website: https://amarfoods.in/''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_first_email',
        name: 'First Email (Initial Outreach)',
        type: 'first_email',
        channel: 'email',
        subject: 'Product Inquiry & Introduction - Amar Foods ({company})',
        body: '''Dear Purchasing Department / Trade Manager ({company}),

Greetings from Amar Foods!

We specialize in exporting high-quality Dehydrated Onion, Garlic, and Food Products. We would love to discuss potential supply and partnership opportunities with {company}.

Could you please share your current purchasing requirements or connect us with your procurement manager?

Warm regards,

Darshan Zalavadiya
Export Sales Executive
Amar Foods | India
📞 Phone / WhatsApp: +91 7284088737
📧 Email: export@amarfoods.in
🌐 Website: https://amarfoods.in/''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_followup_1',
        name: 'Follow-Up 1 (First Reminder)',
        type: 'followup_1',
        channel: 'email',
        subject: 'Following Up: Amar Foods Inquiry - {company} (Follow-Up #1)',
        body: '''Dear Purchasing Team ({company}),

I hope this email finds you well.

I am following up on our previous communication regarding Dehydrated Onion & Garlic supply from Amar Foods.

Please let us know if you have any questions or require updated product specifications, catalog, or pricing for {company}.

Warm regards,

Darshan Zalavadiya
Export Sales Executive
Amar Foods | India
📞 Phone / WhatsApp: +91 7284088737
📧 Email: export@amarfoods.in
🌐 Website: https://amarfoods.in/''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_followup_2',
        name: 'Follow-Up 2 (Catalog & Pricing)',
        type: 'followup_2',
        channel: 'email',
        subject: 'Catalog & Price Request: Amar Foods Export - {company} (Follow-Up #2)',
        body: '''Dear Purchasing Team ({company}),

I am reaching out once again regarding our high-grade Dehydrated Onion & Garlic products.

We would be happy to share our latest product catalog and custom FOB/CIF pricing tailored for {company}'s requirements.

Looking forward to your feedback.

Warm regards,

Darshan Zalavadiya
Export Sales Executive
Amar Foods | India
📞 Phone / WhatsApp: +91 7284088737
📧 Email: export@amarfoods.in
🌐 Website: https://amarfoods.in/''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_followup_3',
        name: 'Follow-Up 3+ (Re-engagement)',
        type: 'followup_3',
        channel: 'email',
        subject: 'Re-engagement: Dehydrated Spice Supply for {company} (Follow-Up #{followup_count})',
        body: '''Dear Trade & Purchasing Team ({company}),

Checking in to see if {company} has any upcoming requirements for Dehydrated Onion Flakes, Powder, or Garlic Granules.

We offer premium export quality with competitive bulk pricing. Please let us know if we can assist with a sample order.

Warm regards,

Darshan Zalavadiya
Export Sales Executive
Amar Foods | India
📞 Phone / WhatsApp: +91 7284088737
📧 Email: export@amarfoods.in
🌐 Website: https://amarfoods.in/''',
        isDefault: true,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 2. LINKEDIN OUTREACH TEMPLATES (100% Free Smart-Assisted Funnel)
      // ═══════════════════════════════════════════════════════════════════════
      EmailTemplate(
        id: 'tpl_linkedin_connect',
        name: 'LinkedIn: Connection Request Note (<300 chars)',
        type: 'linkedin_connect',
        channel: 'linkedin',
        subject: 'Connection Request Note (< 300 chars)',
        body: 'Hi {contact_person}, noticed your work in food sourcing at {company}. We manufacture & export optical-sorted dehydrated onion, garlic & spices from Mahuva, India. Would love to connect and follow your updates!',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_linkedin_welcome',
        name: 'LinkedIn: First Intro (Post-Acceptance)',
        type: 'linkedin_welcome',
        channel: 'linkedin',
        subject: 'Welcome & Factory Credentials',
        body: '''Hi {contact_person}, thanks for connecting!

Briefly introducing Amar Foods: we are a direct manufacturer & exporter of premium Dehydrated White, Red, Pink Onion & Garlic (Flakes, Minced, Chopped, Granules, Powder) as well as Spices & Vegetable Powders from Gujarat, India.

We supply global food processors and spice blenders with optical-sorted, low-micro quality (FSSC 22000, Kosher, Halal). Are you currently sourcing dehydrated alliums or spices for {company}? Happy to share our product catalog & spec sheets.''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_linkedin_followup_1',
        name: 'LinkedIn: Follow-Up 1 (Free Lab Samples)',
        type: 'linkedin_followup_1',
        channel: 'linkedin',
        subject: 'Complimentary Sample Offer (Day 4)',
        body: '''Hi {contact_person}, following up on my previous note. We are currently scheduling export dispatches and offering complimentary sample kits (Flakes, Minced, Granules, Powder) along with COA / lab specs for your QA evaluation.

Could we send a sample box to {company} to test our aroma and optical purity?''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_linkedin_followup_2',
        name: 'LinkedIn: Follow-Up 2 (Spot Rates & WhatsApp)',
        type: 'linkedin_followup_2',
        channel: 'linkedin',
        subject: 'Fresh Crop Spot Rates & WhatsApp (Day 10)',
        body: '''Hi {contact_person}, fresh crop spot rates in India are favorable this week. We have fresh batches of Optical Sorted Onion Flakes and Garlic Granules ready for export packaging.

If you're on WhatsApp for faster communication, feel free to reach me at +91 7284088737 or let me know yours. Wishing you a productive week ahead!''',
        isDefault: true,
      ),
      EmailTemplate(
        id: 'tpl_linkedin_followup_3',
        name: 'LinkedIn: Follow-Up 3 (47 Products & HSN Codes)',
        type: 'linkedin_followup_3',
        channel: 'linkedin',
        subject: 'Official Product Range & HSN Directory (Day 20)',
        body: '''Hi {contact_person}, wanted to share our full export product directory (47 items including Dehydrated White/Red/Pink Onions - HSN 07122000, Garlic - HSN 07129030/40, Pure Ginger, Turmeric, Cumin, and Vegetable Powders).

Let me know if {company} has any upcoming import inquiries or tenders we can quote on.''',
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
