import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/screens/app/map_page.dart';
import 'package:alexa_clean_the_kitchen/screens/app/page_device_connector.dart';
import 'package:alexa_clean_the_kitchen/screens/app/page_device_log.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';
import 'package:alexa_clean_the_kitchen/styles/style.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

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

  List<BackendLogs> logs = [];

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
                          BackendRequester.validateUserRefreshToken(parent.user)
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
        results = [getDeviceConnectorPage(this)];
        break;
      case 1:
        results = [getDeviceLogPage(this)];
        break;
      case 2:
        results = [getMapPage(this)];
        break;
    }

    return results;
  }

  void setDevices(List<XiomiDevice> devices) {
    this.setState(() {
      this.devices = devices;
      this.selectedDevice = selectedDevice != null
          ? devices.firstWhere((element) => element.mac == selectedDevice.mac)
          : devices.first;
    });
  }

  void setDropDown(String value) {
    setState(() {
      dropDownVal = XiomiServer.us.toString();
    });
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

  void setSelectedDevice(String newValue) {
    this.setState(() {
      selectedDevice = devices.firstWhere((device) => device.name == newValue);
    });
  }

  void setRelativeEmailText(String message) {
    this.setState(() {
      relativeEmailText = message;
    });
  }

  void setLogs(List<BackendLogs> logs) {
    this.setState(() {
      this.logs = logs;
    });
  }
}
