class EmailLog {
  final String id;
  final String buyerId;
  final String company;
  final String emailAddress;
  final String sentDate;
  final String emailType;
  final String notes;

  EmailLog({
    required this.id,
    required this.buyerId,
    required this.company,
    required this.emailAddress,
    required this.sentDate,
    required this.emailType,
    required this.notes,
  });

  factory EmailLog.fromJson(Map<String, dynamic> json) {
    return EmailLog(
      id: json['ID']?.toString() ?? '',
      buyerId: json['BuyerID']?.toString() ?? '',
      company: json['Company']?.toString() ?? '',
      emailAddress: json['EmailAddress']?.toString() ?? '',
      sentDate: json['SentDate']?.toString() ?? '',
      emailType: json['EmailType']?.toString() ?? 'First Email',
      notes: json['Notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'BuyerID': buyerId,
      'Company': company,
      'EmailAddress': emailAddress,
      'SentDate': sentDate,
      'EmailType': emailType,
      'Notes': notes,
    };
  }
}
