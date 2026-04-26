class UserModel {
  int? id;
  String? email;
  String? passwordHash;
  String? displayName;
  String? birthDate;
  String? gender;
  String? address;
  String? avatar;
  String? fcmToken;
  int? status;

  UserModel(
      {this.id,
      this.email,
      this.passwordHash,
      this.displayName,
      this.birthDate,
      this.gender,
      this.address,
      this.avatar,
      this.fcmToken,
      this.status});

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    passwordHash = json['password_hash'];
    displayName = json['display_name'];
    birthDate = json['birth_date'];
    gender = json['gender'];
    address = json['address'];
    avatar = json['avatar'];
    fcmToken = json['fcm_token'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['email'] = this.email;
    data['password_hash'] = this.passwordHash;
    data['display_name'] = this.displayName;
    data['birth_date'] = this.birthDate;
    data['gender'] = this.gender;
    data['address'] = this.address;
    data['avatar'] = this.avatar;
    data['fcm_token'] = this.fcmToken;
    data['status'] = this.status;
    return data;
  }
}
