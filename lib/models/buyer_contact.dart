import 'dart:convert';

/// Represents an individual decision-maker or contact person within an importer company
class BuyerContact {
  final String name;
  final String role; // 'Procurement', 'Purchasing', 'Sourcing', 'R&D / Formulator', 'Executive', 'General'
  final String linkedInUrl;
  final String email;
  final String phone;
  final String status; // 'Not Contacted', 'Connect Sent', 'Connected', 'Replied'

  const BuyerContact({
    required this.name,
    this.role = 'Procurement',
    this.linkedInUrl = '',
    this.email = '',
    this.phone = '',
    this.status = 'Not Contacted',
  });

  BuyerContact copyWith({
    String? name,
    String? role,
    String? linkedInUrl,
    String? email,
    String? phone,
    String? status,
  }) {
    return BuyerContact(
      name: name ?? this.name,
      role: role ?? this.role,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'linkedInUrl': linkedInUrl,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }

  factory BuyerContact.fromMap(Map<String, dynamic> map) {
    return BuyerContact(
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Procurement',
      linkedInUrl: map['linkedInUrl']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Not Contacted',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory BuyerContact.fromJson(String source) => BuyerContact.fromMap(jsonDecode(source));

  /// Formatted single-line representation for human reading & compact sheet storage
  String toCompactString() {
    final parts = <String>[name];
    if (role.isNotEmpty && role != 'General') parts.add('[$role]');
    if (linkedInUrl.isNotEmpty) parts.add('($linkedInUrl)');
    if (email.isNotEmpty) parts.add('email:$email');
    if (phone.isNotEmpty) parts.add('phone:$phone');
    if (status != 'Not Contacted') parts.add('status:$status');
    return parts.join(' ');
  }

  /// Parses a compact string representation like:
  /// "David Clark [Procurement] (https://linkedin.com/in/david) email:david@co.com"
  static BuyerContact parseCompact(String text) {
    String trimmed = text.trim();
    if (trimmed.isEmpty) return const BuyerContact(name: '');

    String role = 'Procurement';
    final roleMatch = RegExp(r'\[(.*?)\]').firstMatch(trimmed);
    if (roleMatch != null) {
      role = roleMatch.group(1)?.trim() ?? 'Procurement';
      trimmed = trimmed.replaceFirst(roleMatch.group(0)!, '').trim();
    }

    String linkedIn = '';
    final urlMatch = RegExp(r'\((https?://[^\s\)]+)\)').firstMatch(trimmed);
    if (urlMatch != null) {
      linkedIn = urlMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(urlMatch.group(0)!, '').trim();
    }

    String email = '';
    final emailMatch = RegExp(r'email:([^\s]+)').firstMatch(trimmed);
    if (emailMatch != null) {
      email = emailMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(emailMatch.group(0)!, '').trim();
    }

    String phone = '';
    final phoneMatch = RegExp(r'phone:([^\s]+)').firstMatch(trimmed);
    if (phoneMatch != null) {
      phone = phoneMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(phoneMatch.group(0)!, '').trim();
    }

    String status = 'Not Contacted';
    final statusMatch = RegExp(r'status:([^\s]+)').firstMatch(trimmed);
    if (statusMatch != null) {
      status = statusMatch.group(1)?.trim() ?? 'Not Contacted';
      trimmed = trimmed.replaceFirst(statusMatch.group(0)!, '').trim();
    }

    final name = trimmed.replaceAll(RegExp(r'\s+'), ' ').trim();
    return BuyerContact(
      name: name,
      role: role,
      linkedInUrl: linkedIn,
      email: email,
      phone: phone,
      status: status,
    );
  }

  static const List<String> standardRoles = [
    'Procurement',
    'Purchasing',
    'Sourcing',
    'R&D / Formulator',
    'Quality Assurance (QA)',
    'Supply Chain',
    'Executive / Owner',
    'General',
  ];
}
