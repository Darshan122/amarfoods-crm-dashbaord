class EmailTemplate {
  final String id;
  final String name;
  final String type; // 'first_email', 'followup_1', 'followup_2', 'followup_3', 'custom'
  final String subject;
  final String body;
  final bool isDefault;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.subject,
    required this.body,
    this.isDefault = false,
  });

  EmailTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? subject,
    String? body,
    bool? isDefault,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
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
      'subject': subject,
      'body': body,
      'isDefault': isDefault,
    };
  }

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'custom',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}
