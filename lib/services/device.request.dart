import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:miio/miio.dart';
import 'package:convert/convert.dart';

import '../models/user.dart';

class Command {
  int randomId;
  String token;
  String deviceIp;
  String mac;
  String actionLogId;
  List<dynamic> commands = [
    {"command": {}, "method": ""}
  ];
  bool success = false;
  String errors = "";

  Command(
      {this.randomId,
      this.token,
      this.deviceIp,
      this.commands,
      this.mac,
      this.actionLogId,
      this.errors});

  factory Command.fromMessage(RemoteMessage message) {
    Map data;
    if (message.data != null && message.data.keys.length > 0) {
      data = message.data;
    } else {
      data = jsonDecode(message.notification.body.toString());
    }

    return new Command(
        randomId: int.parse(data['randomId'].toString()),
        token: data['token'],
        deviceIp: data['deviceIp'],
        mac: data['mac'],
        commands: data['commands'] is List ? data["commands"] : jsonDecode(data["commands"]),
        actionLogId: data['actionLogId']) ?? 0;
  }

  Map toJson() {
    return {
      "randomId": randomId,
      "token": token,
      "deviceIp": deviceIp,
      "commands": commands,
      "mac": mac,
      "actionLogId": actionLogId,
      "success": success,
      "errors": errors
    };
  }
}

class DeviceRequester {
  static int lastCommandRandomId = 0;

  static Future<bool> forwardCommands(Command command) async {
    bool success = false;
    List<int> deviceToken = hex.decode(command.token);
    InternetAddress deviceIp = InternetAddress.tryParse(command.deviceIp);
    MiIoDevice device = new MiIoDevice(address: deviceIp, token: deviceToken);

    if (lastCommandRandomId != command.randomId) {
      for (final comm in command.commands) {
        try {
          success = await callDevice(comm, device, success);
        } catch (e) {
          try {
            success = await callDevice(comm, device, success);
          } catch (e) {}
        }
      }
      lastCommandRandomId = command.randomId;
    } else {
      return null;
    }
    return success;
  }

  static Future<bool> callDevice(comm, MiIoDevice device, bool success) async {
    log(comm.toString(), name: "before sending to device from forwardCommands");
    List<dynamic> response =
        await device.call(comm['method'], jsonDecode(comm['command']));

    log(response.toString(), name: "from forwarded command");
    if (!success && response[0]["did"] != null) {
      success = true;
    }
    await Future.delayed(Duration(milliseconds: 500));
    return success;
  }
}
