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

  /// Formatted single-line storage representation with pipe delimiters:
  /// "Name: David Clark | Role: Procurement | LinkedIn: https://linkedin.com/in/david | Email: david@co.com"
  String toStorageLine() {
    final parts = <String>[
      'Name: ${name.trim()}',
      'Role: ${role.trim().isNotEmpty ? role.trim() : "Procurement"}',
    ];
    if (linkedInUrl.trim().isNotEmpty) {
      parts.add('LinkedIn: ${linkedInUrl.trim()}');
    }
    if (email.trim().isNotEmpty) {
      parts.add('Email: ${email.trim()}');
    }
    if (phone.trim().isNotEmpty) {
      parts.add('Phone: ${phone.trim()}');
    }
    if (status.trim().isNotEmpty && status != 'Not Contacted') {
      parts.add('Status: ${status.trim()}');
    }
    return parts.join(' | ');
  }

  /// Parses a storage line into BuyerContact
  static BuyerContact fromStorageLine(String line) {
    String trimmed = line.trim();
    if (trimmed.startsWith('- ')) trimmed = trimmed.substring(2).trim();
    if (trimmed.isEmpty) return const BuyerContact(name: '');

    if (trimmed.contains('|') || trimmed.contains('Name:')) {
      final segments = trimmed.split('|');
      String name = '';
      String role = 'Procurement';
      String linkedIn = '';
      String email = '';
      String phone = '';
      String status = 'Not Contacted';

      for (var seg in segments) {
        final colonIdx = seg.indexOf(':');
        if (colonIdx != -1) {
          final key = seg.substring(0, colonIdx).trim().toLowerCase();
          final val = seg.substring(colonIdx + 1).trim();
          if (key == 'name') {
            name = val;
          } else if (key == 'role') {
            role = val;
          } else if (key == 'linkedin' || key == 'url') {
            linkedIn = val;
          } else if (key == 'email') {
            email = val;
          } else if (key == 'phone') {
            phone = val;
          } else if (key == 'status') {
            status = val;
          }
        }
      }

      if (name.isNotEmpty || linkedIn.isNotEmpty) {
        return BuyerContact(
          name: name,
          role: role.isNotEmpty ? role : 'Procurement',
          linkedInUrl: linkedIn,
          email: email,
          phone: phone,
          status: status,
        );
      }
    }

    return parseCompact(trimmed);
  }

  /// Formatted single-line representation for human reading & compact sheet storage
  String toCompactString() => toStorageLine();

  /// Parses a compact or legacy string representation like:
  /// "David Clark [Procurement] (https://linkedin.com/in/david) email:david@co.com"
  static BuyerContact parseCompact(String text) {
    String trimmed = text.trim();
    if (trimmed.isEmpty) return const BuyerContact(name: '');

    String role = 'Procurement';
    final roleMatch = RegExp(r'\[(.*?)\]').firstMatch(trimmed);
    if (roleMatch != null) {
      role = roleMatch.group(1)?.trim() ?? 'Procurement';
      trimmed = trimmed.replaceFirst(roleMatch.group(0)!, ' ').trim();
    } else {
      // Check for unclosed role bracket: e.g. "Jameka Pope [Purchasing"
      final unclosedMatch = RegExp(r'\[([^\]]+)$').firstMatch(trimmed);
      if (unclosedMatch != null) {
        role = unclosedMatch.group(1)?.trim() ?? 'Procurement';
        trimmed = trimmed.substring(0, unclosedMatch.start).trim();
      }
    }

    String linkedIn = '';
    final urlMatch = RegExp(r'\((https?://[^\s\)]+)\)').firstMatch(trimmed);
    if (urlMatch != null) {
      linkedIn = urlMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(urlMatch.group(0)!, ' ').trim();
    } else {
      final rawUrlMatch = RegExp(r'(https?://[^\s\)]+)').firstMatch(trimmed);
      if (rawUrlMatch != null) {
        linkedIn = rawUrlMatch.group(1)?.trim() ?? '';
        trimmed = trimmed.replaceFirst(rawUrlMatch.group(0)!, ' ').trim();
      }
    }

    String email = '';
    final emailMatch = RegExp(r'email:([^\s]+)').firstMatch(trimmed);
    if (emailMatch != null) {
      email = emailMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(emailMatch.group(0)!, ' ').trim();
    }

    String phone = '';
    final phoneMatch = RegExp(r'phone:([^\s]+)').firstMatch(trimmed);
    if (phoneMatch != null) {
      phone = phoneMatch.group(1)?.trim() ?? '';
      trimmed = trimmed.replaceFirst(phoneMatch.group(0)!, ' ').trim();
    }

    String status = 'Not Contacted';
    final statusMatch = RegExp(r'status:([^\s]+)').firstMatch(trimmed);
    if (statusMatch != null) {
      status = statusMatch.group(1)?.trim() ?? 'Not Contacted';
      trimmed = trimmed.replaceFirst(statusMatch.group(0)!, ' ').trim();
    }

    final name = trimmed
        .replaceAll(RegExp(r'[\(\)\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

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
    'Founder / CEO / Owner',
    'Managing Director / VP',
    'R&D / Formulator',
    'Quality Assurance (QA)',
    'Supply Chain',
    'Executive / Owner',
    'General',
  ];
}
