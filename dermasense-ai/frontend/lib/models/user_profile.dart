class UserProfile {
  final String? id;
  String fullName;
  String email;
  int? age;
  String? skinType;
  List<String> skinConcerns;
  String? location;
  final String? profileImageUrl;

  UserProfile({
    this.id,
    required this.fullName,
    required this.email,
    this.age,
    this.skinType,
    this.skinConcerns = const [],
    this.location,
    this.profileImageUrl,
  });

  factory UserProfile.empty() {
    return UserProfile(
      fullName: '',
      email: '',
      skinConcerns: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'age': age,
      'skinType': skinType,
      'skinConcerns': skinConcerns,
      'location': location,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      skinType: json['skinType'],
      skinConcerns: (json['skinConcerns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserProfile(
      id: docId,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      age: data['age'] ?? 0,
      skinType: data['skinType'] ?? 'Normal',
      skinConcerns: (data['skinConcerns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: data['location'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'age': age,
      'skinType': skinType,
      'skinConcerns': skinConcerns,
      'location': location,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    int? age,
    String? skinType,
    List<String>? skinConcerns,
    String? location,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      skinType: skinType ?? this.skinType,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
