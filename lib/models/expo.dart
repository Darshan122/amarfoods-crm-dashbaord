class ExpoContact {
  final String id;
  final String companyName;
  final String companyDetails;
  final List<String> emails;
  final List<String> phoneNumbers;
  final String companyWebsite;
  final String personName;
  final String personPosition;
  final String address;
  final String city;
  final String country;
  final String venueAddress;

  ExpoContact({
    required this.id,
    required this.companyName,
    this.companyDetails = '',
    required this.emails,
    required this.phoneNumbers,
    this.companyWebsite = '',
    this.personName = '',
    this.personPosition = '',
    this.address = '',
    this.city = '',
    this.country = '',
    this.venueAddress = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'companyDetails': companyDetails,
      'emails': emails,
      'phoneNumbers': phoneNumbers,
      'companyWebsite': companyWebsite,
      'personName': personName,
      'personPosition': personPosition,
      'address': address,
      'city': city,
      'country': country,
      'venueAddress': venueAddress,
    };
  }

  factory ExpoContact.fromJson(Map<String, dynamic> json) {
    return ExpoContact(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      companyDetails: json['companyDetails']?.toString() ?? '',
      emails: json['emails'] != null
          ? List<String>.from(json['emails'].map((x) => x.toString()))
          : [],
      phoneNumbers: json['phoneNumbers'] != null
          ? List<String>.from(json['phoneNumbers'].map((x) => x.toString()))
          : [],
      companyWebsite: json['companyWebsite']?.toString() ?? '',
      personName: json['personName']?.toString() ?? '',
      personPosition: json['personPosition']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      venueAddress: json['venueAddress']?.toString() ?? '',
    );
  }
}

class ExpoItem {
  final String id;
  final String name;
  final String place;
  final String venue;
  final String expoDate;
  final String country;
  final List<ExpoContact> contacts;

  ExpoItem({
    required this.id,
    required this.name,
    this.place = '',
    this.venue = '',
    this.expoDate = '',
    this.country = '',
    List<ExpoContact>? contacts,
  }) : contacts = contacts ?? [];

  ExpoItem copyWith({
    String? id,
    String? name,
    String? place,
    String? venue,
    String? expoDate,
    String? country,
    List<ExpoContact>? contacts,
  }) {
    return ExpoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      place: place ?? this.place,
      venue: venue ?? this.venue,
      expoDate: expoDate ?? this.expoDate,
      country: country ?? this.country,
      contacts: contacts ?? this.contacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'place': place,
      'venue': venue,
      'expoDate': expoDate,
      'country': country,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    };
  }

  factory ExpoItem.fromJson(Map<String, dynamic> json) {
    return ExpoItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      place: json['place']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      expoDate: json['expoDate']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      contacts: json['contacts'] != null
          ? List<ExpoContact>.from(
              (json['contacts'] as List).map(
                (c) => ExpoContact.fromJson(Map<String, dynamic>.from(c as Map)),
              ),
            )
          : [],
    );
  }
}
