import 'dart:io';
import 'package:alexa_clean_the_kitchen/models/backend_response.dart';
import 'package:convert/convert.dart';

import 'miio/src/device.dart';

///
class Reactor {
  BackendResponse backendResponse;

  Reactor(BackendResponse backendResponse) {
    this.backendResponse = backendResponse;
  }

  /// checks
  bool needToReact() {
    return this.backendResponse.isNew;
  }

  Future <List<dynamic>> syncDevice() {
    MiIoDevice device = new MiIoDevice(
        address: this.backendResponse.ipAddress,
        token: this.backendResponse.token);

    return device.call(this.backendResponse.method, this.backendResponse.params);
  }
}


const String token = '4430697959726663763978736a464b65';
const String ipAddress = "192.168.2.107";

List<int> deviceToken = hex.decode(token);
InternetAddress deviceIp = InternetAddress.tryParse(ipAddress);
MiIoDevice device = new MiIoDevice(address: deviceIp, token: deviceToken);
