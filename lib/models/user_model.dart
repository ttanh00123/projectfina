class UserModel {
  int? userId;
  String? fullName;
  String? mobile;
  String? password;
  String? email;
  String? birthDay;
  int? gender;
  String? otp;
  String? avatar;
  String? expiry;
  String? createdAt;
  String? updatedAt;
  String? pushNotiToken;
  String? address;

  UserModel(
      {this.userId,
      this.fullName,
      this.mobile,
      this.password,
      this.email,
      this.birthDay,
      this.gender,
      this.otp,
      this.avatar,
      this.expiry,
      this.createdAt,
      this.updatedAt,
      this.pushNotiToken,
      this.address});

  UserModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    fullName = json['fullName'];
    mobile = json['mobile'];
    password = json['password'];
    email = json['email'];
    birthDay = json['birthDay'];
    gender = json['gender'];
    otp = json['otp'];
    avatar = json['avatar'];
    expiry = json['expiry'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    pushNotiToken = json['pushNotiToken'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = userId;
    data['fullName'] = fullName;
    data['mobile'] = mobile;
    data['password'] = password;
    data['email'] = email;
    data['birthDay'] = birthDay;
    data['gender'] = gender;
    data['otp'] = otp;
    data['avatar'] = avatar;
    data['expiry'] = expiry;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['pushNotiToken'] = pushNotiToken;
    data['address'] = address;
    return data;
  }
}
