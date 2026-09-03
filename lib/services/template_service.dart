import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_template.dart';

class TemplateService extends ChangeNotifier {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _storageKey = 'amar_crm_email_templates_v2';
  List<EmailTemplate> _templates = [];

  List<EmailTemplate> get templates => List.unmodifiable(_templates);

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
      EmailTemplate(
        id: 'tpl_expo_first_email',
        name: 'Expo First Email (Stall Visit Follow-up)',
        type: 'expo_first_email',
        subject: 'Great meeting you at {expo_name} | Amar Foods — Product Catalog & Collaboration',
        body: '''Dear {contact_person},

I hope this email finds you well.

It was a real pleasure visiting your stall {stall_number} at {expo_name} on {expo_date}. We truly appreciated the brief discussion regarding {company} and your current business activities.

By way of introduction, I represent Amar Foods (India). We are a premier manufacturer & exporter specializing in high-quality:
 • Dehydrated Onion (Flakes, Minced, Chopped, Powder)
 • Dehydrated Garlic (Flakes, Granules, Powder)
 • Spices & Agro Food Products

As discussed at the expo, I have attached our latest Product Catalog & Company Brochure for your review. 

We would be delighted to explore supply and partnership opportunities with {company}. Could you please let us know if you have any ongoing or upcoming requirements? We would be very happy to share customized pricing (FOB / CIF) and dispatch product samples for your quality evaluation.

Looking forward to hearing from you and building a long-term business relationship.

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
        id: 'tpl_first_email',
        name: 'First Email (Initial Outreach)',
        type: 'first_email',
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
    ];
  }

  EmailTemplate getTemplateForType(String type, int followupCount) {
    if (!_isInitialized || _templates.isEmpty) {
      _templates = getDefaultTemplates();
    }

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
      if (followupCount == 1) {
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
    String cleanExpoName = (expoName != null && expoName.trim().isNotEmpty) ? expoName.trim() : 'the exhibition';
    String cleanExpoDate = (expoDate != null && expoDate.trim().isNotEmpty) ? expoDate.trim() : 'recent event';
    String cleanStall = (stallNumber != null && stallNumber.trim().isNotEmpty) ? '(${stallNumber.trim()})' : '';
    String cleanPerson = (contactPerson != null && contactPerson.trim().isNotEmpty)
        ? contactPerson.trim()
        : 'Purchasing & Procurement Team ($cleanCompany)';

    return text
        .replaceAll(RegExp(r'\{\{?\s*company\s*\}?\}', caseSensitive: false), cleanCompany)
        .replaceAll(RegExp(r'\{\{?\s*followup_count\s*\}?\}', caseSensitive: false), followupCount > 0 ? followupCount.toString() : '1')
        .replaceAll(RegExp(r'\{\{?\s*expo_name\s*\}?\}', caseSensitive: false), cleanExpoName)
        .replaceAll(RegExp(r'\{\{?\s*expo_date\s*\}?\}', caseSensitive: false), cleanExpoDate)
        .replaceAll(RegExp(r'\{\{?\s*stall_number\s*\}?\}', caseSensitive: false), cleanStall)
        .replaceAll(RegExp(r'\{\{?\s*contact_person\s*\}?\}', caseSensitive: false), cleanPerson);
  }
}
