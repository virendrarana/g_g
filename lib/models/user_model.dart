class UserModel {
  String uid;
  String fullName;
  String email;
  String phoneNumber;
  String role; // 'customer' or 'admin'
  String address;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.address,
  });

  // Convert a UserModel object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'address': address,
    };
  }

  // Convert a Map object into a UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullName: map['fullName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      role: map['role'],
      address: map['address'],
    );
  }
}
