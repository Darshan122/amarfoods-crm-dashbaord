import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_template.dart';

class TemplateService extends ChangeNotifier {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _storageKey = 'amar_crm_email_templates';
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
        id: 'tpl_first_email',
        name: 'First Email (Initial Outreach)',
        type: 'first_email',
        subject: 'Product Inquiry & Introduction - Amar Foods ({company})',
        body: '''Dear Purchasing Department / Trade Manager ({company}),

Greetings from Amar Foods!

We specialize in exporting high-quality Dehydrated Onion, Garlic, and Food Products. We would love to discuss potential supply and partnership opportunities with {company}.

Could you please share your current purchasing requirements or connect us with your procurement manager?

Best regards,
Amar Foods Export Division
Dehydrated Onion & Garlic Specialist''',
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

Best regards,
Amar Foods Export Division''',
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

Best regards,
Amar Foods Export Division''',
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

Best regards,
Amar Foods Export Division''',
        isDefault: true,
      ),
    ];
  }

  EmailTemplate getTemplateForType(String type, int followupCount) {
    if (!_isInitialized || _templates.isEmpty) {
      _templates = getDefaultTemplates();
    }

    if (type == 'first_email') {
      return _templates.firstWhere(
        (t) => t.type == 'first_email',
        orElse: () => getDefaultTemplates()[0],
      );
    } else {
      if (followupCount == 1) {
        return _templates.firstWhere(
          (t) => t.type == 'followup_1',
          orElse: () => _templates.firstWhere(
            (t) => t.type == 'first_email',
            orElse: () => getDefaultTemplates()[1],
          ),
        );
      } else if (followupCount == 2) {
        return _templates.firstWhere(
          (t) => t.type == 'followup_2',
          orElse: () => getDefaultTemplates()[2],
        );
      } else {
        return _templates.firstWhere(
          (t) => t.type == 'followup_3',
          orElse: () => getDefaultTemplates()[3],
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
  }) {
    String cleanCompany = company.isNotEmpty ? company : 'Importer';
    return text
        .replaceAll(RegExp(r'\{\{?\s*company\s*\}?\}', caseSensitive: false), cleanCompany)
        .replaceAll(RegExp(r'\{\{?\s*followup_count\s*\}?\}', caseSensitive: false), followupCount > 0 ? followupCount.toString() : '1');
  }
}
