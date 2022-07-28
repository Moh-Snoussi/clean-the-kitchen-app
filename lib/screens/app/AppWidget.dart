import 'dart:developer';
import 'dart:html';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
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

  AppWidgetState({@required this.parent, @required this.user});

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
          child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: getPage(_page),
          ),
        ));
  }

  _logoutUser() {
    parent.logoutUser();
  }

  List <Widget>getPage(int page) {
    List<Widget> results;
    switch (page) {
      case 0:
        results =  [
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
        results =  [
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
        results =  [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          labelText: "Xiomi user",
                          helperText: "the email or username",
                          helperStyle: TextStyle()
                        ),
                      ),
                    TextField(
                      controller: userpassController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Password"
                      ),
                    ),
                    TextButton(
                      onPressed: () async {

                        log(usernameController.text.toString());
                        log(userpassController.text.toString());
                      },
                      child: const Text('Submit'),
                    ),
                  ],

              ),

            ),
          ),
        ];
        break;

    }
    return results;
  }
}
