import 'package:intl/intl.dart';

class Buyer {
  final String id; // Permanent ID e.g. AF-00001
  final int srNo; // Col 1: Sr. No.
  final String company; // Col 2: Importer Company
  String get name => company;
  final String website; // Col 3: Importer Website
  final String email; // Col 4: Email
  final String phone; // Col 5: Phone
  final String connectionMethod; // Col 6: Connection Method
  final String connectionDate; // Col 7: Connection Date
  final String firstEmailDate; // Col 8: First Email Date
  final String nextDueDate; // Col 9: Follow Up Date
  final String clientReply; // Col 10: Client Reply
  final String lastEmailDate; // Col 11: Last Email Date
  final int followupCount; // Col 12: Follow-Up Count
  final String status; // Col 13: Current Status
  final String nextAction; // Col 14: Next Action
  final String notes; // Col 15: Notes
  final String marketType; // 'International' or 'Domestic'

  Buyer({
    required this.id,
    this.srNo = 1,
    required this.company,
    this.website = '',
    required this.email,
    this.phone = '',
    this.connectionMethod = 'Email',
    required this.connectionDate,
    required this.firstEmailDate,
    required this.nextDueDate,
    this.clientReply = 'Pending',
    required this.lastEmailDate,
    this.followupCount = 0,
    required this.status,
    this.nextAction = 'Follow-Up',
    required this.notes,
    this.marketType = 'International',
  });

  static String formatBuyerId(int number) {
    return 'AF-${number.toString().padLeft(5, '0')}';
  }

  factory Buyer.fromJson(Map<String, dynamic> json, [int index = 1]) {
    final rawId = json['ID']?.toString() ?? json['BuyerID']?.toString() ?? '';
    final formattedId = rawId.startsWith('AF-') ? rawId : formatBuyerId(index);

    String rawWebsite = '';
    for (var k in ['Importer Website', 'Website', 'website', 'importer_website', 'importerWebsite', 'Url', 'url', 'Link', 'link']) {
      if (json[k] != null && json[k].toString().trim().isNotEmpty && json[k].toString().trim() != 'N/A') {
        rawWebsite = json[k].toString().trim();
        break;
      }
    }

    String connDate = '';
    for (var k in ['Connection Date', 'ConnectionDate', 'connection_date', 'Connection_Date', 'connectionDate', 'CONN_DATE', 'Date']) {
      if (json[k] != null && json[k].toString().trim().isNotEmpty) {
        connDate = json[k].toString().trim();
        break;
      }
    }

    String rawMarket = 'International';
    for (var k in ['Market Type', 'MarketType', 'market_type', 'Market', 'market', 'Region', 'region']) {
      if (json[k] != null && json[k].toString().trim().isNotEmpty) {
        final val = json[k].toString().trim();
        if (val.toLowerCase().contains('dom')) {
          rawMarket = 'Domestic';
        } else {
          rawMarket = 'International';
        }
        break;
      }
    }

    String rawPhone = json['Phone']?.toString() ?? json['phone']?.toString() ?? '';
    if (rawPhone.startsWith("'")) rawPhone = rawPhone.substring(1).trim();
    final lowerPhone = rawPhone.toLowerCase();
    if (lowerPhone == '#error!' ||
        lowerPhone.contains('#error') ||
        lowerPhone == '#ref!' ||
        lowerPhone == '#value!' ||
        lowerPhone == '#n/a' ||
        lowerPhone == 'n/a' ||
        lowerPhone == '-' ||
        lowerPhone == 'null') {
      rawPhone = '';
    }

    return Buyer(
      id: formattedId,
      srNo: int.tryParse(json['SR_NO']?.toString() ?? '') ?? index,
      company: json['Company']?.toString() ?? json['Importer Company']?.toString() ?? 'Importer #$index',
      website: rawWebsite,
      email: json['Email']?.toString() ?? '',
      phone: rawPhone,
      connectionMethod: json['ConnectionMethod']?.toString() ?? json['Connection Method']?.toString() ?? 'Email',
      connectionDate: connDate,
      firstEmailDate: json['FirstEmailDate']?.toString() ?? json['First Email Date']?.toString() ?? '',
      nextDueDate: json['FollowUpDate']?.toString() ?? json['Follow Up Date']?.toString() ?? '',
      clientReply: json['ClientReply']?.toString() ?? json['Client Reply']?.toString() ?? 'Pending',
      lastEmailDate: json['LastEmailDate']?.toString() ?? json['Last Email Date']?.toString() ?? '',
      followupCount: int.tryParse(json['FollowupCount']?.toString() ?? json['Follow-Up Count']?.toString() ?? '0') ?? 0,
      status: json['CurrentStatus']?.toString() ?? json['Current Status']?.toString() ?? json['Status']?.toString() ?? 'New',
      nextAction: json['NextAction']?.toString() ?? json['Next Action']?.toString() ?? 'Follow-Up',
      notes: json['Notes']?.toString() ?? '',
      marketType: rawMarket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'SR_NO': srNo.toString(),
      'Importer Company': company,
      'Importer Website': website,
      'Email': email,
      'Phone': phone,
      'Connection Method': connectionMethod,
      'Connection Date': connectionDate,
      'First Email Date': firstEmailDate,
      'Follow Up Date': nextDueDate,
      'Client Reply': clientReply,
      'Last Email Date': lastEmailDate,
      'Follow-Up Count': followupCount.toString(),
      'Current Status': status,
      'Next Action': nextAction,
      'Notes': notes,
      'Market Type': marketType,
    };
  }

  Buyer copyWith({
    String? id,
    int? srNo,
    String? company,
    String? website,
    String? email,
    String? phone,
    String? connectionMethod,
    String? connectionDate,
    String? firstEmailDate,
    String? nextDueDate,
    String? clientReply,
    String? lastEmailDate,
    int? followupCount,
    String? status,
    String? nextAction,
    String? notes,
    String? marketType,
  }) {
    return Buyer(
      id: id ?? this.id,
      srNo: srNo ?? this.srNo,
      company: company ?? this.company,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      connectionDate: connectionDate ?? this.connectionDate,
      firstEmailDate: firstEmailDate ?? this.firstEmailDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      clientReply: clientReply ?? this.clientReply,
      lastEmailDate: lastEmailDate ?? this.lastEmailDate,
      followupCount: followupCount ?? this.followupCount,
      status: status ?? this.status,
      nextAction: nextAction ?? this.nextAction,
      notes: notes ?? this.notes,
      marketType: marketType ?? this.marketType,
    );
  }

  static DateTime? parseDate(String? raw) {
    if (raw == null) return null;
    final str = raw.trim();
    if (str.isEmpty || str == 'N/A' || str == '-') return null;

    // Try standard ISO 8601 (yyyy-MM-dd)
    final iso = DateTime.tryParse(str);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    // Try parsing dd-MM-yyyy or dd/MM/yyyy or yyyy/MM/dd
    final parts = str.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      final p1 = int.tryParse(parts[0]);
      final p2 = int.tryParse(parts[1]);
      final p3 = int.tryParse(parts[2]);

      if (p1 != null && p2 != null && p3 != null) {
        if (p3 > 1000) {
          return DateTime(p3, p2, p1);
        } else if (p1 > 1000) {
          return DateTime(p1, p2, p3);
        }
      }
    }

    for (var fmt in ['dd-MM-yyyy', 'dd/MM/yyyy', 'dd-MMM-yyyy', 'yyyy-MM-dd']) {
      try {
        final d = DateFormat(fmt).parseStrict(str);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }

    return null;
  }

  bool isDueToday() {
    final reply = clientReply.toLowerCase();
    if (reply == 'yes' || reply == 'converted') return false;
    if (nextDueDate.trim().isEmpty) return false;

    final dueDate = parseDate(nextDueDate);
    if (dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !dueDate.isAfter(today);
  }

  bool isOverdue() {
    final reply = clientReply.toLowerCase();
    if (reply == 'yes' || reply == 'converted') return false;
    if (nextDueDate.isEmpty) return false;

    final dueDate = parseDate(nextDueDate);
    if (dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.isBefore(today);
  }

  int get nextFollowupStep {
    if (firstEmailDate.trim().isEmpty) return 0;

    int manualStep = followupCount > 0 ? followupCount + 1 : 0;

    // Calculate dynamic step based on scheduled date timeline from Connection Date
    int dateStep = 1;
    final targetDate = parseDate(nextDueDate);
    final conn = parseDate(connectionDate);
    final firstMail = parseDate(firstEmailDate);

    if (targetDate != null && conn != null) {
      final diffDays = targetDate.difference(conn).inDays;
      if (diffDays > 10) {
        dateStep = (diffDays / 7).round();
      } else {
        dateStep = 1;
      }
    } else if (targetDate != null && firstMail != null) {
      final diffDays = targetDate.difference(firstMail).inDays;
      if (diffDays > 10) {
        dateStep = ((diffDays + 7) / 7).round();
      } else {
        dateStep = 1;
      }
    }

    if (manualStep > dateStep) return manualStep;
    return dateStep >= 1 ? dateStep : 1;
  }

  String suggestNextEmailType() {
    if (firstEmailDate.trim().isEmpty) return 'First Email';
    return 'Follow-Up $nextFollowupStep';
  }

  String get actionButtonLabel {
    if (clientReply.toLowerCase() == 'yes' || status.toLowerCase() == 'converted') {
      return 'Converted';
    }
    if (firstEmailDate.trim().isEmpty) {
      return 'Send First Email';
    }
    return 'Send Follow-Up $nextFollowupStep';
  }

  static String calculateNextDueDate([DateTime? fromDate]) {
    DateTime base = fromDate ?? DateTime.now();
    DateTime next = base.add(const Duration(days: 7));
    if (next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1)); // Sunday -> Monday
    }
    return DateFormat('yyyy-MM-dd').format(next);
  }

  // ---------------------------------------------------------------------------
  // DUPLICATE DETECTION & NORMALIZATION HELPERS
  // ---------------------------------------------------------------------------

  /// Normalizes company name by stripping legal suffixes, punctuation, and extra whitespace.
  static String normalizeCompany(String name) {
    String s = name.trim().toLowerCase();
    if (s.isEmpty || s == 'n/a' || s == '-' || s.startsWith('importer #')) {
      return '';
    }
    // Remove punctuation
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Remove legal corporate suffixes (inc, ltd, llc, pvt, corp, co, etc.)
    s = s.replaceAll(
      RegExp(r'\b(sole member co ltd|company limited|company ltd|pvt ltd|private limited|corp|corporation|inc|incorporated|ltd|limited|llc|pvt|co)\b'),
      ' ',
    );
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Extracts root host/domain from a website URL.
  static String normalizeDomain(String url) {
    String s = url.trim().toLowerCase();
    if (s.isEmpty || s == 'n/a' || s == '-' || s.contains('@')) return '';
    s = s.replaceAll('https://', '').replaceAll('http://', '').replaceAll('www.', '');
    // Strip trailing paths, queries, fragments
    s = s.split('/')[0].split('?')[0].split('#')[0].trim();
    if (s.length < 4 || !s.contains('.')) return '';
    return s;
  }

  /// Extracts a list of clean email addresses from a comma/semicolon/slash string.
  static List<String> extractEmails(String emailField) {
    if (emailField.trim().isEmpty) return [];
    final split = emailField.split(RegExp(r'[,;/\s]+'));
    final List<String> results = [];
    for (var raw in split) {
      final clean = raw.replaceAll('"', '').replaceAll("'", '').trim().toLowerCase();
      if (clean.contains('@') &&
          !clean.startsWith('n/a') &&
          !clean.startsWith('-') &&
          !results.contains(clean)) {
        results.add(clean);
      }
    }
    return results;
  }

  /// Strips all non-digit characters from phone number.
  static String cleanPhoneDigits(String phoneField) {
    String s = phoneField.replaceAll(RegExp(r'\D'), '');
    // Remove leading zeros if any
    return s.replaceFirst(RegExp(r'^0+'), '');
  }

  /// Checks if this buyer represents the same business entity as [other]
  /// based on normalized company name, shared email, matching website domain, or phone.
  bool matchesDuplicate(Buyer other) {
    if (identical(this, other)) return false;

    // 1. Normalized company name match (min 3 chars)
    final normA = normalizeCompany(company);
    final normB = normalizeCompany(other.company);
    if (normA.isNotEmpty && normB.isNotEmpty && normA.length >= 3 && normB.length >= 3) {
      if (normA == normB) return true;
    }

    // 2. Email match (any shared email address)
    final emailsA = extractEmails(email);
    final emailsB = extractEmails(other.email);
    for (final emA in emailsA) {
      if (emailsB.contains(emA)) return true;
    }

    // 3. Website domain match (min 4 chars)
    final domA = normalizeDomain(website);
    final domB = normalizeDomain(other.website);
    if (domA.isNotEmpty && domB.isNotEmpty && domA.length >= 4 && domB.length >= 4) {
      if (domA == domB) return true;
    }

    // 4. Phone digits match (min 8 digits)
    final phA = cleanPhoneDigits(phone);
    final phB = cleanPhoneDigits(other.phone);
    if (phA.isNotEmpty && phB.isNotEmpty && phA.length >= 8 && phB.length >= 8) {
      if (phA == phB || phA.endsWith(phB) || phB.endsWith(phA)) return true;
    }

    return false;
  }

  /// Returns a human-friendly string describing why [other] is considered a duplicate.
  String getDuplicateReason(Buyer other) {
    final normA = normalizeCompany(company);
    final normB = normalizeCompany(other.company);
    if (normA.isNotEmpty && normB.isNotEmpty && normA == normB) {
      return 'Matching Company Name ("$company")';
    }

    final emailsA = extractEmails(email);
    final emailsB = extractEmails(other.email);
    for (final emA in emailsA) {
      if (emailsB.contains(emA)) {
        return 'Matching Email Address ($emA)';
      }
    }

    final domA = normalizeDomain(website);
    final domB = normalizeDomain(other.website);
    if (domA.isNotEmpty && domB.isNotEmpty && domA == domB) {
      return 'Matching Website Domain ($domA)';
    }

    final phA = cleanPhoneDigits(phone);
    final phB = cleanPhoneDigits(other.phone);
    if (phA.isNotEmpty && phB.isNotEmpty && (phA == phB || phA.endsWith(phB) || phB.endsWith(phA))) {
      return 'Matching Phone Number (${other.phone})';
    }

    return 'Duplicate lead data';
  }
}
