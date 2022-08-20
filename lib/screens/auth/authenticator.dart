import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/login.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/token.requester.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/services/session.service.dart';
import 'package:alexa_clean_the_kitchen/styles/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class Authenticator extends StatefulWidget {
  MyHomePageState parent;

  Authenticator({Key key, this.parent}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AuthenticatorState(parent: parent);
}

class AuthenticatorState extends State<Authenticator> {
  MyHomePageState parent;

  AuthenticatorState({this.parent});

  bool authenticationFailed = false;

  User backendUser = User(userEmail: '', provider: '', providerId: '');

  static const String loginAction = 'Login';
  static const String registerAction = 'Register';
  static const String defaultAction = loginAction;
  String currentAction = defaultAction;
  bool isLoading = false;

  String emailError;
  String passwordError;
  String repeatPasswordError;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  setLoading(bool loadingState) {
    setState(() {
      isLoading = loadingState;
    });
  }

  toggleAction() {
    setState(() {
      currentAction = isLoginAction() ? registerAction : loginAction;
    });
  }

  bool isLoginAction() => currentAction == loginAction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: currentAction,
        theme: ThemeData(
            primaryColor: AppColors.primary,
            backgroundColor: AppColors.background),
        home: Stack(children: [
          Card(
              child: backendUser.providerGranted()
                  ? TokenRequester(this).tokenWidget()
                  : LoginScreen(this).loginWidget()),
          if (authenticationFailed)
            Padding(
              padding: const EdgeInsets.only(top:20),
              child: Card(
                color: Colors.redAccent,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      'Make sure that you have verified your email and entered your credentials correctly'),
                ),
              ),
            )
        ]));
  }

  void authenticate() async {
    bool success = await BackendRequester.validateUserToken(backendUser);

    if (success) {
      SessionService.saveUser(backendUser);
      parent.setState(() {
        parent.setUser(backendUser);
        authenticationFailed = false;
      });
    } else {
      this.setState(() {
        authenticationFailed = true;
      });
    }
  }

  void logout() {
    backendUser = User.empty();
    parent.logoutUser();
  }
}
