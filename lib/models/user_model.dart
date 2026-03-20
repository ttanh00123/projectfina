// lib/models/user_model.dart
class UserModel {
  final int id;
  final String email;
  final String? passwordHash;
  final String? displayName;
  final String provider;
  final String? providerId;
  final String? otpCode;
  final DateTime? otpExpiresAt;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final int? gender;
  final DateTime? updatedAt;
  final String? address;
  final String? fcmToken;
  final String? avatar;
  final int? status;

  const UserModel({
    required this.id,
    required this.email,
    this.passwordHash,
    this.displayName,
    this.provider = 'local',
    this.providerId,
    this.otpCode,
    this.otpExpiresAt,
    this.birthDate,
    this.createdAt,
    this.gender,
    this.updatedAt,
    this.address,
    this.fcmToken,
    this.avatar,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:            json['id'] as int,
        email:         json['email'] as String,
        passwordHash:  json['password_hash'] as String?,
        displayName:   json['display_name'] as String?,
        provider:      json['provider'] as String? ?? 'local',
        providerId:    json['provider_id'] as String?,
        otpCode:       json['otp_code'] as String?,
        otpExpiresAt:  json['otp_expires_at'] == null
            ? null : DateTime.parse(json['otp_expires_at']),
        birthDate:     json['birth_date'] == null
            ? null : DateTime.parse(json['birth_date']),
        createdAt:     json['created_at'] == null
            ? null : DateTime.parse(json['created_at']),
        gender:        json['gender'] as int?,
        updatedAt:     json['updated_at'] == null
            ? null : DateTime.parse(json['updated_at']),
        address:       json['address'] as String?,
        fcmToken:      json['fcm_token'] as String?,
        avatar:        json['avatar'] as String?,
        status:        json['status'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id':              id,
        'email':           email,
        'password_hash':   passwordHash,
        'display_name':    displayName,
        'provider':        provider,
        'provider_id':     providerId,
        'otp_code':        otpCode,
        'otp_expires_at':  otpExpiresAt?.toIso8601String(),
        'birth_date':      birthDate?.toIso8601String().split('T').first,
        'created_at':      createdAt?.toIso8601String(),
        'gender':          gender,
        'updated_at':      updatedAt?.toIso8601String(),
        'address':         address,
        'fcm_token':       fcmToken,
        'avatar':          avatar,
        'status':          status,
      };

  UserModel copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? displayName,
    String? provider,
    String? providerId,
    String? otpCode,
    DateTime? otpExpiresAt,
    DateTime? birthDate,
    DateTime? createdAt,
    int? gender,
    DateTime? updatedAt,
    String? address,
    String? fcmToken,
    String? avatar,
    int? status,
  }) =>
      UserModel(
        id:           id           ?? this.id,
        email:        email        ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        displayName:  displayName  ?? this.displayName,
        provider:     provider     ?? this.provider,
        providerId:   providerId   ?? this.providerId,
        otpCode:      otpCode      ?? this.otpCode,
        otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
        birthDate:    birthDate    ?? this.birthDate,
        createdAt:    createdAt    ?? this.createdAt,
        gender:       gender       ?? this.gender,
        updatedAt:    updatedAt    ?? this.updatedAt,
        address:      address      ?? this.address,
        fcmToken:     fcmToken     ?? this.fcmToken,
        avatar:       avatar       ?? this.avatar,
        status:       status       ?? this.status,
      );

  @override
  String toString() => 'UserModel(id: $id, email: $email, displayName: $displayName)';
}