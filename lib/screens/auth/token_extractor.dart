import 'dart:convert';
import 'dart:math';


class XiaomiCloudConnector {
  String _userName;
  String _password;
  String _agent;
  String _deviceId;
  String _session;
  String _sign;
  String _ssecurity;
  String _userId;
  String cUserId;
  String _passToken;
  String _location;
  String _code;
  String _serviceToken;

  XiaomiCloudConnector(this._userName, this._password) {
    _agent = this._createAgent();
    _deviceId = this.createDeviceId();

  }

  String _createAgent() {
    var random = Random.secure();
    var values = List<int>.generate(6, (i) =>  random.nextInt(122));
    String randomId = base64UrlEncode(values);
    return 'Android-7.1.1-1.0.0-ONEPLUS A3010-136-$randomId APP/xiaomi.smarthome APPV/62830';
  }

  String createDeviceId() {

  }

}