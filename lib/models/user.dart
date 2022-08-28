import 'dart:developer';

import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:flutter_lwa/lwa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_lwa_platform_interface/flutter_lwa_platform_interface.dart';

class User {
  String provider;

  String userEmail;

  bool emailVerified;

  String providerId;

  int userId;

  String accessToken;

  String clientId;

  String secret;

  String mobileId;

  String refreshToken;

  int expiresAt;

  int validUntil = 0;

  bool notificationRegistered = false;

  static FlutterSecureStorage _storage;

  User(
      {this.userEmail,
      this.provider,
      this.providerId,
      this.emailVerified = false,
      this.userId = 0});

  factory User.empty() {
    return User(userEmail: '', provider: '', providerId: '');
  }

  factory User.fromAmazon(LwaUser lwaUser) {
    return User(
        userEmail: lwaUser.userEmail,
        provider: 'Amazon',
        providerId: lwaUser.userId);
  }

  factory User.fromGoogle(GoogleSignInAccount googleUser) {
    return User(
        userEmail: googleUser.email,
        provider: 'Google',
        providerId: googleUser.id,
        emailVerified: true);
  }

  factory User.fromApp(int userId, userEmail, [emailVerified = false]) {
    return User(
        userEmail: userEmail,
        provider: 'App',
        providerId: userId.toString(),
        emailVerified: emailVerified,
        userId: userId);
  }

  static Future<User> fromSecureStorage() async {
    if (_storage == null) {
      _storage = FlutterSecureStorage();
    }
    Map<String, String> data = await _storage.readAll();

    User user = User.fromSession(data);
    bool success = await BackendRequester.validateUserRefreshToken(user);
    if (!success) {
      user = User.empty();
    }
    return user;
  }

  static Future<void> clearFromSession() async {
    if (_storage == null) {
      _storage = FlutterSecureStorage();
    }

    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'provider');
    await _storage.delete(key: 'providerId');
    await _storage.delete(key: 'emailVerified');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'validUntil');
    await _storage.delete(key: 'providerId');
    await _storage.delete(key: 'mobileId');
    await _storage.delete(key: 'clientId');
    await _storage.delete(key: 'secret');
    await _storage.delete(key: 'notificationRegistered');
  }

  writeInSession(FlutterSecureStorage session) async {
    session.write(key: 'userId', value: userId.toString() ?? '');
    session.write(key: 'accessToken', value: accessToken ?? '');
    session.write(key: 'refreshToken', value: refreshToken ?? '');
    session.write(key: 'validUntil', value: validUntil.toString() ?? '');
    session.write(key: 'userEmail', value: userEmail ?? '');
    session.write(key: 'provider', value: provider ?? '');
    session.write(key: 'providerId', value: providerId ?? '');
    session.write(key: 'mobileId', value: mobileId ?? '');
    session.write(key: 'secret', value: secret ?? '');
    session.write(key: 'clientId', value: clientId ?? '');
    session.write(
        key: 'notificationRegistered',
        value: notificationRegistered.toString());
  }

  factory User.fromSession(Map<String, dynamic> session) {
    User user = User.empty();
    if (session['userId'] != null) {
      user.userEmail = session['userEmail'] ?? '';
      user.provider = session['provider'] ?? '';
      user.providerId = session['providerId'] ?? '';
      user.emailVerified = session['emailVerified'] != null &&
          session['emailVerified'] == 'true';
      user.userId = int.parse(session['userId']) ?? 0;
      user.accessToken = session['accessToken'] ?? '';
      user.refreshToken = session['refreshToken'] ?? '';
      user.validUntil = int.parse(session['validUntil']);
      user.providerId = session['providerId'] ?? '';
      user.mobileId = session['mobileId'] ?? '';
      user.clientId = session['clientId'] ?? '';
      user.secret = session['secret'] ?? '';
      user.notificationRegistered = session['notificationRegistered'] == 'true';
    }

    return user;
  }

  Future<bool> isFullyAuthenticated() async {
    bool returns = userId != null &&
        userId > 0 &&
        accessToken.isNotEmpty &&
        refreshToken.isNotEmpty &&
        clientId.isNotEmpty &&
        secret != null &&
        secret.isNotEmpty &&
        validUntil != null &&
        userEmail.isNotEmpty;

    if (returns) {
      returns = await BackendRequester.validateAccessToken(this);
    }

    return returns;
  }

  bool providerGranted() {
    return provider.isNotEmpty && providerId.isNotEmpty;
  }

  bool hasTokenExpired() {
    return false;
  }

  generateToken() {}

  Future<bool> isEmailVerification() async {
    return BackendRequester.isEmailVerified(this.userId);
  }

  Map<String, dynamic> getUserProps() {
    return {
      'userEmail': userEmail ?? '',
      'userId': userId ?? '',
      'provider': provider ?? '',
      'providerId': providerId ?? '',
      'accessToken': accessToken ?? '',
      'refreshToken': refreshToken ?? '',
      'clientId': clientId ?? '',
      'secret': secret ?? '',
      'validUntil': validUntil ?? '',
      'emailVerified': emailVerified ?? ''
    };
  }

  void refresh(Map<String, dynamic> tokenResponse) {
    refreshToken = tokenResponse["refresh_token"];
    accessToken = tokenResponse["access_token"];
    validUntil = int.parse((tokenResponse["expires_in"] ?? 0).toString());
    DateTime expires = DateTime.now().add(Duration(seconds: validUntil));
    validUntil = (expires.millisecondsSinceEpoch / 1000).round();
  }

  bool validate() {
    return this.accessToken != null &&
        this.accessToken.isNotEmpty &&
        this.refreshToken != null &&
        this.refreshToken.isNotEmpty &&
        this.validUntil != null;
  }
}
