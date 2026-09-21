class EmailTemplate {
  final String id;
  final String name;
  final String type; // 'first_email', 'followup_1', 'followup_2', 'followup_3', 'custom', 'linkedin_connect', 'linkedin_welcome', 'linkedin_followup_1', 'linkedin_followup_2', 'linkedin_followup_3'
  final String channel; // 'email' | 'linkedin'
  final String subject;
  final String body;
  final bool isDefault;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.channel = 'email',
    required this.subject,
    required this.body,
    this.isDefault = false,
  });

  bool get isLinkedIn => channel == 'linkedin' || type.startsWith('linkedin');

  EmailTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? channel,
    String? subject,
    String? body,
    bool? isDefault,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'channel': channel,
      'subject': subject,
      'body': body,
      'isDefault': isDefault,
    };
  }

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    final tType = json['type']?.toString() ?? 'custom';
    final tId = json['id']?.toString() ?? '';
    final defaultChannel = (tType.startsWith('linkedin') || tId.contains('linkedin')) ? 'linkedin' : 'email';

    return EmailTemplate(
      id: tId,
      name: json['name'] ?? '',
      type: tType,
      channel: json['channel'] ?? defaultChannel,
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}
