import 'dart:convert';
import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';
import 'package:http/http.dart' as http;

class BackendRequester {

  static const String auth_v2_path = '/oauth/v2/token';

  static const String backendUrl = 'www.alexa-clean-the-kitchen.de';

  // '192.168.2.108:7000'; //'www.alexa-clean-the-kitchen.de';
  static final String apiBase = '/api/';

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  //User user = User.fromSession();

  static generateAuthHeaders(String accessToken) {
    int userIdNeedleIndex = accessToken.indexOf('ad');
    String urlAccessToken = accessToken.substring(userIdNeedleIndex + 2);

    if (true) {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + urlAccessToken
      };
      return headers;
    }
  }

  static registerPushClient(User user) async {
    await http
        .get(
        Uri.https(backendUrl, apiBase + 'push_subscriber',
            {'mobileId': user.mobileId}),
        headers: generateAuthHeaders(user.accessToken))
        .then((value) => {log(value.body.toString())});
  }

  static Future <bool> validateUserToken(User user) async {
    DateTime currentDate = DateTime.now();
    DateTime validUntil =
    DateTime.fromMillisecondsSinceEpoch(user.validUntil * 1000);

    log(validUntil.toString(), name: 'validUntil');
    log(currentDate.toString(), name: 'currentDate');

    if (currentDate.isAfter(validUntil)) {
      http.Response response = await _refreshUserToken(user);
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      user.refresh(jsonResponse);

      log(jsonResponse.toString(), name: 'validateUserToken');

      return jsonResponse['access_token'] != null;
    }
    return validateAccessToken(user);
  }

  static _refreshUserToken(User user) async {
    log(user.refreshToken, name: 'refreshToken');
    return await http.post(Uri.https(backendUrl, auth_v2_path),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
        }, body: {
          "grant_type": "refresh_token",
          "client_id": user.clientId,
          "client_secret": user.secret,
          "refresh_token": user.refreshToken,
        });
  }

  void sendPush() {
    // http.url
    //     .get(Uri.https(backendUrl, 'test'))
    //     .then((http.Response value) => {log(value.body.toString())});
  }

  static Future<bool> validateAccessToken(User user) async {
    assert(user.validate(), 'Tokens are not valid');

    http.Response response = await http
        .get(Uri.https(backendUrl, apiBase + 'validate'),
        headers: generateAuthHeaders(user.accessToken));

    Map<String, dynamic> jsonBody = jsonDecode(response.body.toString());

    log(jsonBody.toString());

    return jsonBody['success'] != null && jsonBody['success'] &&
        jsonBody['userId'] == user.userId && jsonBody['emailVerified'];
  }

  static Future<Map<String, dynamic>> authenticate(String currentAction,
      String email, String password) async {
    Map<String, String> body = {'email': email, 'password': password};

    String targetPath = currentAction == 'Register' ? 'register' : 'login';
    http.Response response = await http.post(Uri.https(backendUrl, targetPath),
        headers: headers,
        body: jsonEncode(body));
    return jsonDecode(response.body);
  }

  static Future<bool> isEmailVerified(int userId) async {
    String path = 'is_verified/' + userId.toString();

    http.Response response = await http.get(Uri.https(backendUrl, path),
        headers: headers);

    Map<String, dynamic> jsonBody = jsonDecode(response.body.toString());
    return jsonBody['success'];
  }

  static Future<Map<String, dynamic>> registerUser(User user) async {
    String path = '/app/authenticator';

    http.Response response = await http.post(Uri.https(backendUrl, path),
        headers: {
          'Accept': 'application/json'
        }, body: {
          'provider': user.provider,
          'providerId': user.providerId,
          'email': user.userEmail,
        });

    log(response.body.toString());

    Map<String, dynamic> jsonBody = jsonDecode(response.body.toString());
    return jsonBody;
  }

  static registerDevices(List<XiomiDevice> devices, User user) async {
    if (user.validate()) {
      http.Response response = await http
          .post(Uri.https(backendUrl, apiBase + 'addDevices'),
          body: {
            "devices": [devices.forEach((device) => device.asJson)]
          },
          headers: {
          ...generateAuthHeaders(user.accessToken)
          });
    }
  }

  static void logOnBackend(data) {
    http.get(Uri.https(backendUrl, 'logger', data));
  }
}
