import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';
import 'package:alexa_clean_the_kitchen/styles/style.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;

import '../auth/login.dart';

class AppWidget extends StatefulWidget {
  final User user;
  MyHomePageState parent;

  AppWidget({Key key, @required this.parent, @required this.user})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      AppWidgetState(parent: parent, user: user);
}

class AppWidgetState extends State<AppWidget> {
  User user;
  MyHomePageState parent;
  int _page = 0;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController userpassController = TextEditingController();
  String dropDownVal;
  TokenExtractor extractor;
  List<XiomiDevice> devices;
  XiomiDevice selectedDevice;
  bool _isLoading = false;
  bool xiomiCloudLogin = false;

  String xiomiCloudButtonText = "Xiomi Cloud login";

  IconData addAccountIcon = Icons.add;

  bool showAddAccount = true;

  AppWidgetState({@required this.parent, @required this.user});

  String relativeEmailText = "";

  @override
  void dispose() {
    usernameController.dispose();
    userpassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          actions: <Widget>[
            Expanded(
              child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.web),
                        color: AppColors.background,
                        onPressed: () async {
                          BackendRequester.validateUserToken(parent.user)
                              .then((value) => parent.setState(() {
                                    parent.setUser(user);
                                  }));
                        }),
                    IconButton(
                        icon: Icon(Icons.logout),
                        color: AppColors.background,
                        onPressed: () => _logoutUser()),
                  ]),
            )
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          animationDuration: Duration(milliseconds: 200),
          backgroundColor: AppColors.background,
          color: AppColors.primary,
          items: <Widget>[
            Icon(Icons.list, color: AppColors.background, size: 30),
            Icon(Icons.cleaning_services_sharp,
                color: AppColors.background, size: 30),
            Icon(Icons.adjust_sharp, color: AppColors.background, size: 30),
          ],
          onTap: (index) {
            setState(() {
              _page = index;
            });
          },
        ),
        body: _getBody());
  }

  Widget _getBody() {
    return Container(
        color: AppColors.background,
        child: Center(
          child: SingleChildScrollView(
              child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                if (_isLoading)
                  Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [LinearProgressIndicator(color: Colors.blue)]),
                ...getPage(_page)
              ])),
        ));
  }

  _logoutUser() {
    parent.logoutUser();
  }

  List<Widget> getPage(int page) {
    List<Widget> results;
    switch (page) {
      case 0:
        results = [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hello ' + _page.toString(),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.font),
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      children: [Text('props:'), Text('value')],
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      children: [Text('props:'), Text('value')],
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      textDirection: TextDirection.rtl,
                      children: [Icon(Icons.edit)],
                    )
                  ]),
            ),
          ),
        ];
        break;
      case 1:
        results = [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hello ' + _page.toString(),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.font),
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      children: [Text('props:'), Text('value')],
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      children: [Text('props:'), Text('value')],
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      textDirection: TextDirection.rtl,
                      children: [Icon(Icons.edit)],
                    )
                  ]),
            ),
          ),
        ];
        break;
      case 2:
        results = [
          Card(
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
                      setState(() {
                        _isLoading = true;
                      });
                      BackendRequester.getDevices(user).then((value) {
                        this.setState(() {
                          devices = value;
                          selectedDevice = devices.first;
                          _isLoading = false;
                        });
                      }).onError((error, stackTrace) {
                        this.setState(() {
                          _isLoading = false;
                        });
                      });
                    },
                  ),
                  ElevatedButton(
                      onPressed: () {
                        toggleXiomiCloud();
                      },
                      child: Text(xiomiCloudButtonText)),
                  if (xiomiCloudLogin) ...[
                    Text(
                      'Get your Device credentials',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.font),
                    ),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Xiomi user",
                          helperText: "the email or username",
                          helperStyle: TextStyle()),
                    ),
                    TextField(
                      controller: userpassController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Password", border: OutlineInputBorder()),
                    ),
                    DropdownButton<String>(
                      hint: Text("Choose a server"),
                      itemHeight: 70,
                      style: const TextStyle(color: Colors.deepPurple),
                      isExpanded: true,
                      underline: Container(
                        height: 1,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String newValue) {
                        setState(() {
                          dropDownVal = XiomiServer.us.toString();
                        });
                      },
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
                        this.setLoading(false);
                        extractor = TokenExtractor(
                            XiomiUser(
                                username: 'sooniic@live.com',
                                //usernameController.value.text,
                                password: '720327Sonic',
                                // userpassController.value.text,
                                server: XiomiServer.de),
                            cacheDevices: true);
                        bool loginSuccess = await extractor.login();
                        if (loginSuccess) {
                          List<XiomiDevice> xiomidevices =
                              await extractor.geDevices();
                          if (xiomidevices.length > 0) {
                            Map body = await BackendRequester.registerDevices(
                                xiomidevices, this.user);
                            if (body["success"]) {
                              List<XiomiDevice> backendDevices =
                                  await BackendRequester.getDevices(user);
                              this.setState(() {
                                devices = backendDevices;
                                selectedDevice = devices.first;
                              });
                            }
                          }
                        }
                        this.setLoading(false);
                      },
                      child: const Text('Submit'),
                    )
                  ],
                  if (selectedDevice != null) ...[
                    Card(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDevice.name,
                        items: devices
                            .map((device) => DropdownMenuItem(
                                  child: Text(device.name),
                                  value: device.name,
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            this.setState(() {
                              selectedDevice = devices.firstWhere(
                                  (device) => device.name == newValue);
                            });
                          });
                        },
                      ),
                    ),
                    if (selectedDevice != null) ...[
                      Container(
                        height: 50,
                        child: TextField(
                          onSubmitted: (val) {
                            setState(() {
                              _isLoading = true;
                            });
                            BackendRequester.changeDeviceName(
                                    user, selectedDevice, val)
                                .then((value) async {
                              if (value["success"]) {
                                List<XiomiDevice> xiomidevices =
                                    await BackendRequester.getDevices(user);
                                this.setState(() {
                                  devices = xiomidevices;
                                  selectedDevice = devices.first;
                                });
                              }
                              this.setLoading(false);
                            }).onError((error, stackTrace) {
                              this.setLoading(false);
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
                            child: Text(selectedDevice.model.toString(),
                                style: TextStyle(color: Colors.white))),
                      ),
                      Container(
                        height: 50,
                        color: Colors.blue[500],
                        child: Center(
                            child: Text(selectedDevice.token.toString(),
                                style: TextStyle(color: Colors.white))),
                      ),
                      Container(
                        height: 50,
                        color: Colors.blue[400],
                        child: Center(
                            child: Text(selectedDevice.localIp,
                                style: TextStyle(color: Colors.white))),
                      ),
                      if (selectedDevice.did != null &&
                          selectedDevice.did != "")
                        Container(
                          height: 50,
                          color: Colors.blue[300],
                          child: Center(
                              child: Text(selectedDevice.did,
                                  style: TextStyle(color: Colors.white))),
                        ),
                      if (selectedDevice.relativeEmails != null &&
                          selectedDevice.relativeEmails.length > 0) ...[
                        Container(
                          height: 50,
                          color: Colors.blue[200],
                          child: Center(
                              child: Text("Registered emails:",
                                  style: TextStyle(color: Colors.white))),
                        ),
                        ...getAssociateAccounts(selectedDevice.relativeEmails,
                            user, selectedDevice),
                      ]
                    ],
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        child: Icon(addAccountIcon),
                        onPressed: () {
                          addAccount();
                        },
                      ),
                    )),
                    if (!showAddAccount)
                      TextField(
                        decoration: InputDecoration(
                            errorText: relativeEmailText,
                            helperText:
                                "the email need to have the app installed and registered",
                            labelText:
                                "Enter the email that will share with you the vacuum",
                            border: OutlineInputBorder()),
                        onSubmitted: (email) async {
                          if (LoginScreen.validateEmail(email)) {
                            try {
                              this.setLoading(true);
                              Map response = await BackendRequester.addRelative(
                                  user, selectedDevice.mac, email);
                              if (response is Map &&
                                  response["message"] != null) {
                                this.setState(() {
                                  relativeEmailText = response["message"];
                                });
                              }
                              if (response["success"]) {
                                List<XiomiDevice> responseDevices =
                                    await BackendRequester.getDevices(user);
                                this.setState(() {
                                  relativeEmailText = "";
                                  devices = responseDevices;
                                  selectedDevice = devices.first;
                                });
                              }
                            } finally {
                              this.setLoading(false);
                            }
                          }
                        },
                      )
                  ],
                ],
              ),
            ),
          ),
        ];
        break;
    }

    return results;
  }

  void toggleXiomiCloud() {
    this.setState(() {
      xiomiCloudLogin = !xiomiCloudLogin;
      xiomiCloudButtonText =
          xiomiCloudLogin ? "Hide Xiomi Clound login" : "Xiomi Cloud login";
    });
  }

  void addAccount() {
    this.setState(() {
      showAddAccount = !showAddAccount;
      addAccountIcon = showAddAccount ? Icons.add : Icons.close;
    });
  }

  List<Widget> getAssociateAccounts(
      List<dynamic> associates, User user, XiomiDevice device) {
    return associates
        .map(
          (associateEmail) => Container(
            height: 50,
            color: Colors.blue[200],
            child: Dismissible(
              background: Container(
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Remove Forever',
                          style: TextStyle(color: Colors.white))
                    ],
                  ),
                ),
              ),
              key: Key(associateEmail),
              child: Center(
                  child: Text(associateEmail,
                      style: TextStyle(color: Colors.white))),
              confirmDismiss: (item) async {
                bool result = false;
                try {
                  this.setLoading(true);
                  Map response = await BackendRequester.removeRelative(
                      user, device.mac, associateEmail);
                  if (response["success"]) {
                    result = true;
                    List<XiomiDevice> backendDevices =
                        await BackendRequester.getDevices(user);
                    this.setState(() {
                      devices = backendDevices;
                      selectedDevice = devices.first;
                    });
                  }
                } finally {
                  this.setLoading(false);
                }
                return result;
              },
            ),
          ),
        )
        .toList();
  }

  void setLoading(bool loadingState) {
    setState(() {
      _isLoading = loadingState;
    });
  }
}
