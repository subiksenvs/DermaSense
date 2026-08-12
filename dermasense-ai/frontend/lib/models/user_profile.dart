class UserProfile {
  String fullName;
  String email;
  int? age;
  String? skinType;
  List<String> skinConcerns;
  double? budget;
  String? location;

  UserProfile({
    required this.fullName,
    required this.email,
    this.age,
    this.skinType,
    this.skinConcerns = const [],
    this.budget,
    this.location,
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
      'fullName': fullName,
      'email': email,
      'age': age,
      'skinType': skinType,
      'skinConcerns': skinConcerns,
      'budget': budget,
      'location': location,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      skinType: json['skinType'],
      skinConcerns: List<String>.from(json['skinConcerns'] ?? []),
      budget: json['budget']?.toDouble(),
      location: json['location'],
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    int? age,
    String? skinType,
    List<String>? skinConcerns,
    double? budget,
    String? location,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      skinType: skinType ?? this.skinType,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      budget: budget ?? this.budget,
      location: location ?? this.location,
    );
  }
}
