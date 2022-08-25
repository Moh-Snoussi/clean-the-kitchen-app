import 'dart:convert';
import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/device.request.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';
import 'package:http/http.dart' as http;

class BackendRequester {
  static const String auth_v2_path = '/oauth/v2/token';

  static const String backendUrl = '192.168.2.34:8000';

  // '192.168.2.108:7000'; //'www.alexa-clean-the-kitchen.de';
  static final String apiBase = '/api/';

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  //User user = User.fromSession();

  static generateAuthHeaders(String accessToken) {
    if (accessToken != null) {
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
    return {};
  }

  static registerPushClient(User user) async {
    if (user.accessToken != null) {
      await http
          .get(
              Uri.http(backendUrl, apiBase + 'push_subscriber',
                  {'mobileId': user.mobileId}),
              headers: generateAuthHeaders(user.accessToken))
          .then((value) => {log(value.body.toString())});
    }
  }

  static Future<bool> validateUserRefreshToken(User user) async {
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
    return await http.post(Uri.http(backendUrl, auth_v2_path), headers: {
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
    //     .get(Uri.http(backendUrl, 'test'))
    //     .then((http.Response value) => {log(value.body.toString())});
  }

  static Future<bool> validateAccessToken(User user) async {
    assert(user.validate(), 'Tokens are not valid');

    http.Response response = await http.get(
        Uri.http(backendUrl, apiBase + 'validate'),
        headers: generateAuthHeaders(user.accessToken));

    Map<String, dynamic> jsonBody = jsonDecode(response.body.toString());

    log(jsonBody.toString());

    return jsonBody['success'] != null &&
        jsonBody['success'] &&
        jsonBody['userId'] == user.userId &&
        jsonBody['emailVerified'];
  }

  static Future<Map<String, dynamic>> authenticate(
      String currentAction, String email, String password) async {
    Map<String, String> body = {'email': email, 'password': password};

    String targetPath = currentAction == 'Register' ? 'register' : 'login';
    http.Response response = await http.post(Uri.http(backendUrl, targetPath),
        headers: headers, body: jsonEncode(body));
    return jsonDecode(response.body);
  }

  static Future<bool> isEmailVerified(int userId) async {
    String path = 'is_verified/' + userId.toString();

    http.Response response =
        await http.get(Uri.http(backendUrl, path), headers: headers);

    Map<String, dynamic> jsonBody = jsonDecode(response.body.toString());
    return jsonBody['success'];
  }

  static Future<Map<String, dynamic>> registerUser(User user) async {
    String path = '/app/authenticator';

    http.Response response =
        await http.post(Uri.http(backendUrl, path), headers: {
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

  static Future<Map> registerDevices(
      List<XiomiDevice> devices, User user) async {
    if (user.validate()) {
      http.Response response =
          await http.post(Uri.http(backendUrl, apiBase + 'sync/device'),
              body: jsonEncode({
                "devices": [...devices.map((element) => element.asJson)]
              }),
              headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return null;
  }

  static Future<Map> logOnBackend(Command command, User user) async {
    try {
      http.Response response = await http.post(
          Uri.http(backendUrl, apiBase + 'device/action_process'),
          body: jsonEncode({"device":command.toJson()}),
          headers: generateAuthHeaders(user.accessToken));
      return json.decode(response.body);
    } catch (e) {
      return {"success": e.toString()};
    }
  }

  static Future<Map> changeDeviceName(
      User user, XiomiDevice selectedDevice, String newName) async {
    if (user.validate()) {
      http.Response response = await http.post(
          Uri.http(backendUrl, apiBase + 'device/rename'),
          body: jsonEncode(
              {"device": selectedDevice.toJson(), "newName": newName}),
          headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return null;
  }

  static Future<List<XiomiDevice>> getDevices(User user) async {
    List<XiomiDevice> results;
    if (user.validate()) {
      http.Response response = await http.get(
          Uri.http(backendUrl, apiBase + 'devices'),
          headers: {...generateAuthHeaders(user.accessToken)});

      Map jsonBody = jsonDecode(response.body);

      if (jsonBody["success"] &&
          jsonBody.containsKey("devices") &&
          jsonBody["devices"] is Map &&
          jsonBody["devices"].keys.toList().length > 0) {
        results = XiomiDevice.fromAssociativeMap(jsonBody["devices"]);
      }
    }
    return results;
  }

  static Future<Map> addRelative(
      User user, String deviceMac, String relatedUserEmail) async {
    if (user.validate()) {
      http.Response response = await http.post(
          Uri.http(backendUrl, apiBase + 'relatives'),
          body: jsonEncode({"email": relatedUserEmail, "deviceMac": deviceMac}),
          headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return null;
  }

  static Future<Map> removeRelative(
      User user, String deviceMac, String relatedUserEmail) async {
    if (user.validate()) {
      http.Response response = await http.post(
          Uri.http(backendUrl, apiBase + 'remove_relatives'),
          body: jsonEncode({"email": relatedUserEmail, "deviceMac": deviceMac}),
          headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return null;
  }

  static Future<Map> securePost(User user, Map params, String apiPath) async {
    if (user.validate()) {
      http.Response response = await http.post(
          Uri.http(backendUrl, apiBase + apiPath),
          body: jsonEncode(params),
          headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return {"success": "false"};
  }

  static Future<Map> secureGet(User user, String apiPath) async {
    if (user.validate()) {
      http.Response response = await http.get(
          Uri.http(backendUrl, apiBase + apiPath),
          headers: {...generateAuthHeaders(user.accessToken)});
      return json.decode(response.body);
    }
    return {"success": "false"};
  }

  static Future<Map> requestUserDeviceLogs(User user) async {
    return secureGet(user, "userLogs");
  }
}
