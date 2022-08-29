import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/screens/app/AppWidget.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/authenticator.dart';
import 'package:alexa_clean_the_kitchen/services/firebase.push.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  runApp(HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StateHome(),
    );
  }
}

class StateHome extends StatefulWidget {
  const StateHome({Key key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<StateHome> with TickerProviderStateMixin {
  User user = User.empty();
  final _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Container(
        child: FutureBuilder(
          future: _fetchCredentials(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            Widget returns = new Authenticator(parent: this);

            log(snapshot.data.toString(), name:'future builder in main');
            if (snapshot.hasData && snapshot.data) {
                registerPushHandler(user);

                setUser(user);
                returns = AppWidget(parent: this, user: user);
            }
            return returns;
          },
        ));
  }

  Future<bool> _fetchCredentials() async {
    try {

    Map<String, String> data = await _storage.readAll();

    this.user = User.fromSession(data);

    return this.user.isFullyAuthenticated();
    } catch (e) {
      log(e.toString(), name: "error from fetchCredentials");
    }
  }

  void logoutUser() {
    _storage.deleteAll().then((value) => {
      this.setState(() {
        this.user = User.empty();
      })
    });
  }

  void setUser(User user) {
    this.user = user;
    user.writeInSession(_storage);
  }
}
