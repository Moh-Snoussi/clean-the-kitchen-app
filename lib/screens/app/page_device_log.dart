import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/backend.requester.dart';
import '../../services/token_extrator.dart';
import '../../styles/style.dart';
import '../auth/login.dart';
import 'AppWidget.dart';

Widget getDeviceLogPage(AppWidgetState parent) {
  if (parent.logs == null || parent.logs.length == 0) {
    getLogs(parent.user).then((value) => parent.setLogs(value));
  }
  return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
              child: Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                'Device Log',
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.font),
              ),
              ...parent.logs.map((element) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          color: element.success != null && element.success
              ? Colors.green
              : Colors.red,
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Flex(
                direction: Axis.vertical,
                children: [
                  Flex(
                    direction: Axis.horizontal,
                    children: [
                      Text('Date: '),
                      Text(element.date.toLocal().toString())
                    ],
                  ),
                  Flex(
                    direction: Axis.horizontal,
                    children: [
                      Text("last requested: "),
                      Text(element.emailSuccess)
                    ],
                  ),
                ],
              )

          )
      )
  ))])
  )
  )
  );
}

Future<List<BackendLogs>> getLogs(User user) async {
  Map response = await BackendRequester.requestUserDeviceLogs(user);

  return BackendLogs.fromResponse(response);
}

class BackendLogs {
  int id;
  DateTime date;
  DateTime successDate;
  bool success;
  String emailSuccess;
  String deviceName;

  BackendLogs({this.id,
    this.date,
    this.success,
    this.successDate,
    this.emailSuccess,
    this.deviceName});

  static List<BackendLogs> fromResponse(Map responseBody) {
    List<BackendLogs> results = [];
    if (responseBody.containsKey("logs")) {
      List<dynamic> logs = responseBody["logs"];
      logs.forEach((element) {
        results.add(new BackendLogs(
            id: int.parse(element["id"].toString()),
            date: DateTime.parse(element["time"]),
            successDate: element["successDate"] != null ? DateTime.parse(element["successDate"]): null,
            success: element["success"],
            emailSuccess: element["user"]));
      });
    }
    return results;
  }
}
