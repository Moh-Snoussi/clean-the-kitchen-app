import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:miio/miio.dart';
import 'package:convert/convert.dart';

class Command {
  int randomId;
  String token;
  String deviceIp;
  Map<String, dynamic> command;

  Command({this.randomId, this.token, this.deviceIp, this.command});

  factory Command.fromMessage(RemoteMessage message) => Command(
    randomId: int.parse(message.data['randomId'].toString()),
      token: message.data['token'],
      deviceIp: message.data['deviceIp'],
      command: jsonDecode(message.data['commands']));
}

class DeviceRequester {

  static int lastCommandRandomId = 0;
  
  static void forwardCommands(Command command) {
    List<int> deviceToken = hex.decode(command.token);
    InternetAddress deviceIp = InternetAddress.tryParse(command.deviceIp);
    MiIoDevice device = new MiIoDevice(address: deviceIp, token: deviceToken);

    if (lastCommandRandomId != command.randomId) {
      command.command['commands'].forEach((element) async {
        log(element.toString());
        List<dynamic> response =
            await device.call(element['method'], jsonDecode(element['command']));

        await Future.delayed(Duration(milliseconds: 500));
      });
        lastCommandRandomId = command.randomId;
    }

  }
}
