import 'package:flutter/material.dart';

import '../../services/backend.requester.dart';
import '../../services/token_extrator.dart';
import '../../styles/style.dart';
import '../auth/login.dart';
import 'AppWidget.dart';

Widget getDeviceConnectorPage(AppWidgetState parent) {
  if (parent.devices == null || parent.devices.length == 0) {
    BackendRequester.getDevices(parent.user).then((value) {
      parent.setLoading(false);
      parent.setDevices(value);
      parent.setLoading(false);
    });
  }
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            child: Center(child: Text("refresh devices")),
            onPressed: () {
              parent.setLoading(true);
              BackendRequester.getDevices(parent.user).then((value) {
                parent.setDevices(value);
                parent.setLoading(false);
              }).onError((error, stackTrace) {
                parent.setLoading(false);
              });
            },
          ),
          ElevatedButton(
              onPressed: () {
                parent.toggleXiomiCloud();
              },
              child: Text(parent.xiomiCloudButtonText)),
          if (parent.xiomiCloudLogin) ...[
            Text(
              'Get your Device credentials',
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.font),
            ),
            TextField(
              controller: parent.usernameController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Xiomi user",
                  helperText: "the email or username",
                  helperStyle: TextStyle()),
            ),
            TextField(
              controller: parent.userpassController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: "Password", border: OutlineInputBorder()),
            ),
            DropdownButton<String>(
              hint: Text("Choose a server"),
              value: parent.dropDownVal,
              itemHeight: 70,
              style: const TextStyle(color: Colors.deepPurple),
              isExpanded: true,
              underline: Container(
                height: 1,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String newValue) {
                parent.setDropDown(newValue);
              }
              ,
              items: XiomiServer.values
                  .map<DropdownMenuItem<String>>((dynamic value) {
                return DropdownMenuItem<String>(
                  value: value.toString(),
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
            TextButton(
              onPressed: () async {
                parent.setLoading(true);
                try {
                  parent.extractor = TokenExtractor(
                      XiomiUser(
                          username: parent.usernameController.value.text,
                          password: parent.userpassController.value.text,
                          server: XiomiServer.values.firstWhere((element) => element.toString() == parent.dropDownVal)),
                      cacheDevices: true);
                  bool loginSuccess = await parent.extractor.login();
                  if (loginSuccess) {
                    List<XiomiDevice> xiomidevices =
                        await parent.extractor.geDevices();
                    if (xiomidevices.length > 0) {
                      Map body = await BackendRequester.registerDevices(
                          xiomidevices, parent.user);
                      if (body["success"]) {
                        List<XiomiDevice> backendDevices =
                            await BackendRequester.getDevices(parent.user);
                        parent.setDevices(backendDevices);
                      }
                    }
                  }
                } catch (e) {
                  print(e.toString());
                } finally {
                  parent.setLoading(false);
                }
              },
              child: const Text('Submit'),
            )
          ],
          if (parent.selectedDevice != null) ...[
            Card(
              child: DropdownButton<String>(
                isExpanded: true,
                value: parent.selectedDevice.name,
                items: parent.devices
                    .map((device) => DropdownMenuItem(
                          child: Text(device.name),
                          value: device.name,
                        ))
                    .toList(),
                onChanged: (newValue) {
                  parent.setSelectedDevice(newValue);
                },
              ),
            ),
            if (parent.selectedDevice != null) ...[
              Container(
                height: 50,
                child: TextField(
                  onSubmitted: (val) {
                    parent.setLoading(true);
                    BackendRequester.changeDeviceName(
                            parent.user, parent.selectedDevice, val)
                        .then((value) async {
                      if (value["success"]) {
                        List<XiomiDevice> xiomidevices =
                            await BackendRequester.getDevices(parent.user);
                        parent.setDevices(xiomidevices);
                      }
                      parent.setLoading(false);
                    }).onError((error, stackTrace) {
                      parent.setLoading(false);
                    });
                  },
                  decoration: InputDecoration(
                    helperText: "click to rename",
                  ),
                ),
              ),
              Container(
                height: 50,
                color: Colors.blue[600],
                child: Center(
                    child: Text(parent.selectedDevice.model.toString(),
                        style: TextStyle(color: Colors.white))),
              ),
              Container(
                height: 50,
                color: Colors.blue[500],
                child: Center(
                    child: Text(parent.selectedDevice.token.toString(),
                        style: TextStyle(color: Colors.white))),
              ),
              Container(
                height: 50,
                color: Colors.blue[400],
                child: Center(
                    child: Text(parent.selectedDevice.localIp,
                        style: TextStyle(color: Colors.white))),
              ),
              if (parent.selectedDevice.did != null &&
                  parent.selectedDevice.did != "")
                Container(
                  height: 50,
                  color: Colors.blue[300],
                  child: Center(
                      child: Text(parent.selectedDevice.did,
                          style: TextStyle(color: Colors.white))),
                ),
              if (parent.selectedDevice.relativeEmails != null &&
                  parent.selectedDevice.relativeEmails.length > 0) ...[
                Container(
                  height: 50,
                  color: Colors.blue[200],
                  child: Center(
                      child: Text("Registered emails:",
                          style: TextStyle(color: Colors.white))),
                ),
                ...parent.getAssociateAccounts(
                    parent.selectedDevice.relativeEmails,
                    parent.user,
                    parent.selectedDevice),
              ]
            ],
            Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                child: Icon(parent.addAccountIcon),
                onPressed: () {
                  parent.addAccount();
                },
              ),
            )),
            if (!parent.showAddAccount)
              TextField(
                decoration: InputDecoration(
                    errorText: parent.relativeEmailText,
                    helperText:
                        "the email need to have the app installed and registered",
                    labelText:
                        "Enter the email that will share with you the vacuum",
                    border: OutlineInputBorder()),
                onSubmitted: (email) async {
                  if (LoginScreen.validateEmail(email)) {
                    try {
                      parent.setLoading(true);
                      Map response = await BackendRequester.addRelative(
                          parent.user, parent.selectedDevice.mac, email);
                      if (response is Map && response["message"] != null) {
                        parent.setRelativeEmailText(response["message"]);
                      }
                      if (response["success"]) {
                        parent.setRelativeEmailText("User added Successfully");
                        List<XiomiDevice> responseDevices =
                            await BackendRequester.getDevices(parent.user);
                        parent.setDevices(responseDevices);
                      }
                    } finally {
                      parent.setLoading(false);
                    }
                  }
                },
              )
          ],
        ],
      ),
    ),
  );
}
