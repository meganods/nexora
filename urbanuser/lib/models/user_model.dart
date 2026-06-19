class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profileImage;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final DateTime createdDate;
  final DateTime lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profileImage,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    required this.createdDate,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'profileImage': profileImage,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'createdDate': createdDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      profileImage: json['profileImage'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdDate: DateTime.parse(json['createdDate']),
      lastLogin: DateTime.parse(json['lastLogin']),
    );
  }
}
