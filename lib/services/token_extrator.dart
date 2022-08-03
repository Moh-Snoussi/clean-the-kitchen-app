import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:alexa_clean_the_kitchen/services/firebase.push.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_logger/dio_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nonce/nonce.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:simple_rc4/simple_rc4.dart';
import 'package:randombytes/randombytes.dart';


enum XiomiServer {
  cn,
  de,
  us,
  ru,
  tw,
  sg,
  i2,
  emptyX,
  String
}

extension ParseToString on XiomiServer {
  String toShortString() {
    return this
        .toString()
        .split('.')
        .last;
  }
}

Map xiomiResToJson(Response response) {
  return json.decode(response.data.replaceAll("&&&START&&&", ""));
}

class XiomiDevice {

  XiomiDevice(
      {this.name, this.token, this.mac, this.did, this.model, this.localIp, this.asJson });

  String localIp;
  String token;
  String name;
  String mac;
  String did;
  String model;
  Map <String, dynamic> asJson;

  static List<XiomiDevice> fromXiomiResponseBody(String body) {
    List<XiomiDevice> results;
    Map<String, dynamic> responseBody = json.decode(body);
    if (responseBody.isNotEmpty && responseBody.containsKey("result") &&
        responseBody["result"].containsKey("list")) {
      List resultList = responseBody["result"]["list"];
      resultList.forEach((element) {
        results.add(
            XiomiDevice(
              name: responseBody["name"],
              localIp: responseBody["localip"],
              token: responseBody["token"],
              model: responseBody["model"],
              mac: responseBody["mac"],
              did: responseBody["did"],
              asJson: responseBody
            )
        );

      });
    }
    return results;
  }

  Map<String, String> toJson() {
    return {
      "did": this.did,
      "mac": this.mac,
    };
  }

}

class XiomiUser {
  String username;
  String password;
  XiomiServer server;
  Map cachedResults;

  XiomiUser({this.username, this.password, this.server});

  factory XiomiUser.empty() =>
      XiomiUser(username: "", password: "", server: XiomiServer.emptyX);
}

class XiomiSecurity {
  String ssecurity;
  String userId;
  String cUserId;
  String passToken;
  String location;
  String code;
  String notificationUrl;
  String serviceToken;

  XiomiSecurity({this.ssecurity,
    this.userId,
    this.cUserId,
    this.passToken,
    this.location,
    this.code,
    this.notificationUrl,
    this.serviceToken});

  factory XiomiSecurity.fromResponse(Response response) {
    Map jsonResponse = xiomiResToJson(response);

    return XiomiSecurity(
        ssecurity: jsonResponse["ssecurity"],
        userId: jsonResponse["userId"].toString(),
        cUserId: jsonResponse["cUserId"].toString(),
        passToken: jsonResponse["passToken"].toString(),
        location: jsonResponse["location"].toString(),
        code: jsonResponse["code"].toString(),
        notificationUrl: jsonResponse["notificationUrl"].toString());
  }

  bool isValid() {
    return userId != null &&
        cUserId != null &&
        ssecurity != null &&
        passToken != null &&
        code != null &&
        location != null;
  }

  bool doesRequireTwoFactors() =>
      notificationUrl != null && notificationUrl.isNotEmpty;
}

class TokenExtractor {
  String username;
  String password;
  XiomiServer server;
  Dio httpClient;
  String _agentId;
  String _sign;
  XiomiSecurity xiomiSecurity;
  String feedback;
  String serviceToken;
  CookieJar cookieJar;
  String deviceId;
  IOSink sink;
  bool cacheDevices;
  List<XiomiDevice> deviceResults;

  static final String loginStep1Url =
      "https://account.xiaomi.com/pass/serviceLogin?sid=xiaomiio&_json=true";
  static final String loginStep2Url =
      "https://account.xiaomi.com/pass/serviceLoginAuth2";

  Random _rnd = Random();

  TokenExtractor(XiomiUser user, {Dio httpClient, bool cacheDevices}) {
    this.username = user.username;
    this.password = user.password;
    this.server = user.server;
    httpClient ??= Dio(
        BaseOptions(headers: getRequestHeaders("userId=" + username + ";")));
    this.httpClient = httpClient;
    String appDocPath;
    getApplicationDocumentsDirectory().then((value) async {
      appDocPath = value.path.toString();
      cookieJar = PersistCookieJar(
          ignoreExpires: true, storage: FileStorage(appDocPath + "/.cookies/"));
      this.httpClient.interceptors.add(CookieManager(cookieJar));
      var file = File(appDocPath + "/http_log.txt");
      print("path: " + appDocPath);
      sink = file.openWrite();
      httpClient.interceptors.add(LogInterceptor(logPrint: sink.writeln));
    });

    @override
    dispose() {
      sink.close();
      _agentId = null;
    }

    httpClient.interceptors.add(dioLoggerInterceptor);
    this.httpClient.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          response.data =
              response.data.toString().replaceAll("&&&START&&&", "");
          handler.next(response);
        },
        onError: (DioError e, handler) {
          // Do something with response error
          return handler.next(e); //continue
          // If you want to resolve the request with some custom data，
          // you can resolve a `Response` object eg: `handler.resolve(response)`.
        }
    ));
  }

  String stringifyCookies(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  Future<Response> login1Request() async {
    return await httpClient.get(
        loginStep1Url, options: Options(
        headers: getRequestHeaders(), responseType: ResponseType.plain));
  }

  Future<bool> loginStep1() async {
    bool result = false;
    Response response = await login1Request();
    if (validateStep1Response(response) && setSignFromResponse(response)) {
      result = true;
    }
    return result;
  }

  bool validateStep1Response(Response response) {
    return response.statusCode == 200 && response.data.contains("_sign");
  }

  bool setSignFromResponse(Response response) {
    bool success = false;
    Map jsonResponse = xiomiResToJson(response);
    if (jsonResponse.containsKey("_sign")) {
      _sign = jsonResponse["_sign"];
      success = true;
    }
    return success;
  }

  String hashPass(String pass) =>
      md5.convert(utf8.encode(pass)).toString().toUpperCase();

  Future<Response> login2Response() async {
    Map<String, String> postBody = {
      "sid": "xiaomiio",
      "hash": hashPass(password),
      "callback": "https://sts.api.io.mi.com/sts",
      "qs": "%3Fsid%3Dxiaomiio%26_json%3Dtrue",
      "user": username,
      "_sign": _sign,
      "_json": "true"
    };
    return await httpClient.post(loginStep2Url, data: postBody,
        options: Options(responseType: ResponseType.plain));
  }

  bool validateLogin2(Response response) {
    return response.statusCode == 200;
  }

  Future<bool> loginStep2() async {
    bool result = false;
    Response response = await login2Response();
    if (validateLogin2(response) && setSecurityFromResponse(response)) {
      result = true;
    } else if (xiomiSecurity != null && xiomiSecurity.doesRequireTwoFactors()) {
      feedback =
          'Two factor authentication required, use following url and restart extractor: \n' +
              xiomiSecurity.notificationUrl;
    }
    return result;
  }

  Future<Response> login3Response() {
    return httpClient.get(
        xiomiSecurity.location, options: Options(
        headers: getRequestHeaders(), responseType: ResponseType.plain));
  }

  bool validateLogin3(Response response) => response.statusCode == 200;

  Future<bool> loginStep3() async {
    bool result = false;
    Response response = await login3Response();
    if (validateLogin3(response)) {
      setServiceTokenFromResponse(response);
      result = true;
    }
    return result;
  }

  setServiceTokenFromResponse(Response response) {
    bool success = false;
    String serviceTokenNeedle = "serviceToken=";
    response.headers["set-cookie"].forEach((element) {
      if (element.toString().startsWith(serviceTokenNeedle)) {
        xiomiSecurity.serviceToken =
            element.toString().substring(
                element.indexOf("=") + 1, element.indexOf(";"));
        success = true;
      }
    });
    return success;
  }


  bool setSecurityFromResponse(Response response) {
    xiomiSecurity = XiomiSecurity.fromResponse(response);
    return xiomiSecurity.isValid();
  }

  /// Generates device id
  String generateDeviceId({length = 6}) {
    if (deviceId == null) {
      deviceId = String.fromCharCodes(Iterable.generate(
          length, (_) => 97 + _rnd.nextInt(122 - 97)));
    }
    return deviceId;
  }

  String getAgent() {
    if (_agentId == null) {
      _agentId = generateAgentId();
    }
    return 'Android-7.1.1-1.0.0-ONEPLUS A3010-136-$_agentId APP/xiaomi.smarthome APPV/62830';
  }

  /// Generates device id
  String generateAgentId({min = 65, max = 69, length = 13}) {
    return Iterable.generate(
        length, (_) => (min + _rnd.nextInt(max - min)).toString()).join("");
  }

  Map<String, String> getRequestHeaders([String addedCookies]) {
    return {
      "User-Agent": getAgent(),
      "Content-Type": "application/x-www-form-urlencoded",
      "Cookie": generateSessionCookies(addedCookies)
    };
  }

  String generateSessionCookies([String addedCookies]) {
    addedCookies ??= "";
    Cookie sdkMi = Cookie("sdkVersion", "accountsdk-18.8.15");
    sdkMi.domain = "mi.com";

    Cookie sdkXioMi = Cookie("sdkVersion", "accountsdk-18.8.15");
    sdkXioMi.domain = "mi.com";

    Cookie deviceMi = Cookie("sdkVersion", "accountsdk-18.8.15");
    deviceMi.domain = "mi.com";

    Cookie deviceXioMi = Cookie("sdkVersion", "accountsdk-18.8.15");
    deviceXioMi.domain = "mi.com";

    return ([deviceMi, deviceXioMi, sdkXioMi, sdkMi].fold(
        "", (value, element) => element.toString() + ";" + value) + ";" +
        addedCookies).replaceAll(";;", ";");
  }


  login() async {
    if (deviceResults != null && deviceResults.isNotEmpty && cacheDevices) {
      return true;
    }

    bool success = false;

    if (await loginStep1() && await loginStep2() && await loginStep3()) {
      success = true;
    } else {
      feedback = feedback + "\n Invalid login or password.";
    }
    return success;
  }

  Future<List<XiomiDevice>> geDevices() {
    if (deviceResults != null && deviceResults.isNotEmpty && cacheDevices) {
      return Future(() => deviceResults);
    }

    String apiUrl = getApiUrl(server) + "/home/device_list";
    Map<String, String> params = new Map<String, String>.from({
      "data": '{"getVirtualModel":true,"getHuamiDevices":1,"get_split_device":false,"support_smart_home":true}'
    });

    return callEncrypted(apiUrl, params);
  }

  String getApiUrl(XiomiServer serverLocation) {
    return "https://" +
        (serverLocation == XiomiServer.cn ? "" : serverLocation.name
            .toString() + ".") + "api.io.mi.com/app";
  }

  Future<List<XiomiDevice>> callEncrypted(String apiUrl,
      Map<String, dynamic> params) async {
    Map headers = new Map<String, dynamic>.from({
      "Accept-Encoding": "identity",
      "User-Agent": getAgent(),
      "Content-Type": "application/x-www-form-urlencoded",
      "x-xiaomi-protocal-flag-cli": "PROTOCAL-HTTP2",
      "MIOT-ENCRYPT-ALGORITHM": "ENCRYPT-RC4",
    });

    //xiomiSecurity.serviceToken = "NDXOlYt6xKj8uB9vOZymp2391CNz6aJUNzi2uC+14Qz2k4kwUThYMVKplQi5vZaQAO6KnE8PsfxslC7HInlfyXbRtf3EqyWaJXoK/nLPOlW+Hr4j9hj0E4AMbdY7eciH/cVZXrsLr5WNgByLqM6Qhwtf2mOqnRqbO3IfgBLz7LQ=";
    //xiomiSecurity.ssecurity = "iKmmoY9j2YLo6QYIMsNIKA==";

    List <Cookie> cookies = [
      Cookie("userId", xiomiSecurity.userId),
      Cookie("yetAnotherServiceToken", xiomiSecurity.serviceToken),
      Cookie("serviceToken", xiomiSecurity.serviceToken),
      Cookie("locale", "en_GB"),
      Cookie("timezone", "GMT+02:00"),
      Cookie("is_daylight", "1"),
      Cookie("dst_offset", "3600000"),
      Cookie("channel", "MI_APP_STORE"),
      Cookie("sdkVersion", "accountsdk-18.8.15"),
      Cookie("deviceId", generateDeviceId()),
    ];
    cookieJar.saveFromResponse(Uri.parse(apiUrl), cookies);

    String nonce = generateNonce(DateTime
        .now()
        .millisecondsSinceEpoch
        .floor() * 1000);

    String signedNonce = signNonce(nonce, xiomiSecurity.ssecurity);
    Map<String, dynamic> fields = generateEncParams(
        apiUrl, 'POST', signedNonce, nonce, params, xiomiSecurity.ssecurity);
    Response response = await httpClient.post(apiUrl,
        options: Options(
          headers: headers,
        ),
        data: FormData.fromMap(fields));

    if (response.statusCode == 200) {
      String decodedBody = decryptRc4(
          signNonce(fields["_nonce"], xiomiSecurity.ssecurity),
          response.data.toString());
      deviceResults = XiomiDevice.fromXiomiResponseBody(decodedBody);
      return deviceResults;
    }
  }

  String signNonce(String nonce, String secret) {
    List<int> appSecret = base64.decode(secret) + base64.decode(nonce);
    Digest sh = sha256.convert(appSecret);
    return base64Encode(sh.bytes);
  }

  String generateSignParams(String apiUrl, String signedNonce, String nonce,

      Map<dynamic, dynamic> params) {
    List<String> signatureParams = [apiUrl
        .split("com")
        .last, signedNonce, nonce];
    params.forEach((key, value) =>
        signatureParams.add(key + '=' + value.toString()));
    String signatureString = signatureParams.join("&");

    Hmac hash = Hmac(sha256, base64Decode(signedNonce));
    Digest results = hash.convert(
        utf8.encode(signatureString)
    );
    return base64Encode(results.bytes);
  }

  String generateNonce(int millis) {
    List bytes = randomBytes(8) + (Uint8List(4)
      ..buffer.asByteData().setInt32(0, (millis / 60000).floor(), Endian.big));
    return Uri.encodeComponent(base64Encode(bytes));
  }


  String generateEncSign(String apiUrl, String method, String signedNonce,
      Map<dynamic, dynamic> params) {
    List signatureParams = [method.toUpperCase(), apiUrl
        .split("com")
        .last
        .replaceAll("/app/", "/")
    ];
    params.forEach((key, value) =>
        signatureParams.add(key + '=' + value));
    signatureParams.add(signedNonce);

    String signatureString = signatureParams.join("&");

    Digest results = sha1.convert(
        utf8.encode(signatureString)
    );
    return base64Encode(results.bytes);
  }

  Map generateEncParams(String url, String method, String signedNonce,
      String nonce, Map<String, dynamic> params, String securityToken) {
    params["rc4_hash__"] = generateEncSign(url, method, signedNonce, params);

    params
        .forEach((key, value) => params[key] = encryptRc4(signedNonce, value));

    params["signature"] = generateEncSign(url, method, signedNonce, params);
    params["ssecurity"] = securityToken;
    params["_nonce"] = nonce;

    return params;
  }

  encryptRc4(String secretKey, String value) {
    List<int> baseNonce = base64Decode(secretKey);
    RC4 encrypter = RC4.fromBytes(baseNonce);
    encrypter.decodeBytes(List.generate(1024, (index) => 0), true);
    return
      base64Encode(encrypter.encodeBytes(utf8.encode(value)));
  }

  String decryptRc4(String secretKey, String payload) {
    List<int> baseNonce = base64Decode(secretKey);
    RC4 encrypter = RC4.fromBytes(baseNonce);
    encrypter.decodeBytes(List.generate(1024, (index) => 0), true);
    return encrypter.decodeBytes(base64Decode(payload), true);
  }
}
