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

    return Buyer(
      id: formattedId,
      srNo: int.tryParse(json['SR_NO']?.toString() ?? '') ?? index,
      company: json['Company']?.toString() ?? json['Importer Company']?.toString() ?? 'Importer #$index',
      website: rawWebsite,
      email: json['Email']?.toString() ?? '',
      phone: json['Phone']?.toString() ?? '',
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
    if (reply == 'yes' || reply == 'hold' || reply == 'converted') return false;
    if (nextDueDate.isEmpty) return true;

    final dueDate = parseDate(nextDueDate);
    if (dueDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !dueDate.isAfter(today);
  }

  bool isOverdue() {
    final reply = clientReply.toLowerCase();
    if (reply == 'yes' || reply == 'hold' || reply == 'converted') return false;
    if (nextDueDate.isEmpty) return false;

    final dueDate = parseDate(nextDueDate);
    if (dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.isBefore(today);
  }

  String suggestNextEmailType() {
    if (followupCount == 0 || firstEmailDate.isEmpty) return 'First Email';
    return 'Follow-Up $followupCount';
  }

  String get actionButtonLabel {
    if (clientReply.toLowerCase() == 'yes' || status.toLowerCase() == 'converted') {
      return 'Converted';
    }
    if (clientReply.toLowerCase() == 'hold') {
      return 'On Hold';
    }
    if (followupCount == 0 || firstEmailDate.isEmpty) {
      return 'Send First Email';
    }
    return 'Send Follow-Up $followupCount';
  }

  static String calculateNextDueDate([DateTime? fromDate]) {
    DateTime base = fromDate ?? DateTime.now();
    DateTime next = base.add(const Duration(days: 7));
    if (next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1)); // Sunday -> Monday
    }
    return DateFormat('yyyy-MM-dd').format(next);
  }
}
