import 'dart:convert';
import 'dart:developer';
import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/authenticator.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/social.login.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen {
  AuthenticatorState parent;
  SocialLogin socialLogin;

  LoginScreen(this.parent);

  String getAlternativeAction() {
    const String loginText = 'Already have an account? to login';
    const String registerText = 'You have no account? to register';

    return parent.isLoginAction() ? registerText : loginText;
  }

  Widget loginWidget() {
    return ListView(
        padding: const EdgeInsets.fromLTRB(6.33, 50.0, 6.33, 0),
        children: <Widget>[
          if (parent.isLoading) LinearProgressIndicator(),
          Text(
            parent.currentAction,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 24),
          ),
          TextField(
            controller: parent.emailController,
            decoration: InputDecoration(
                labelText: 'Email',
                helperText: 'The email you used when you first register',
                errorText: parent.emailError),
          ),
          TextField(
            controller: parent.passwordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'Type your password',
                errorText: parent.passwordError),
          ),
          if (!parent.isLoginAction())
            TextField(
              controller: parent.confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: 'Repeat password',
                  helperText: 'Retype your password',
                  errorText: parent.repeatPasswordError),
            ),
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 20.0, 0, 0),
              child: ElevatedButton(
                child: Text(parent.currentAction),
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ))),
                onPressed: () => appAuthenticate(),
              )),
          ElevatedButton.icon(
            label: Text(
              parent.currentAction + " with Google",
              textAlign: TextAlign.left,
            ),
            style: ButtonStyle(
                alignment: Alignment.center,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ))),
            icon: FaIcon(FontAwesomeIcons.google),
            onPressed: () => new SocialLogin(this.parent).handleGoogleSignIn(),
          ),
          ElevatedButton.icon(
            label: Text(
              parent.currentAction + " with Amazon",
              textAlign: TextAlign.left,
            ),
            style: ButtonStyle(
                alignment: Alignment.center,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ))),
            icon: FaIcon(FontAwesomeIcons.amazon),
            onPressed: () => new SocialLogin(this.parent).handleLWASignIn(),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: new RichText(
                  text: new TextSpan(children: [
                new TextSpan(
                  text: getAlternativeAction(),
                  style: new TextStyle(color: Colors.black),
                ),
                new TextSpan(
                  text: ' click here',
                  style: new TextStyle(color: Colors.blue),
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () {
                      parent.toggleAction();
                    },
                )
              ])),
            ),
          ),
        ]);
  }

  appAuthenticate() async {
    parent.setLoading(true);
    String email = parent.emailController.text;
    String password = parent.passwordController.text;
    String repeatedPassword = parent.confirmPasswordController.text;
    bool isEmailValid = validateEmail(email);
    bool isPasswordValid = validatePassword(password, repeatedPassword);

    if (!isEmailValid) {
      parent.setState(() {
        parent.emailError = 'email invalid, provide an email you can access';
      });
    } else if (!isPasswordValid) {
      parent.setState(() {
        parent.passwordError =
            'Password length should have at least 6 characters';
        parent.passwordError =
            'Passwords does not match, please provide a password that you can remember';
      });
    } else {
      parent.setState(() {
        resetErrors();
      });
      try {
        Map<String, dynamic> response = await BackendRequester.authenticate(
            parent.currentAction, email, password);

        if (response['success'] != null && response['success']) {
          parent.setState(() {
            parent.backendUser =
                User.fromApp(response['userId'], email, response['isVerified']);
            log(parent.backendUser.emailVerified.toString());
          });
        } else {
          parent.setState(() {
            parent.emailError = 'email maybe wrong';
            parent.passwordError = 'password maybe wrong';
          });
        }
      } finally {
        parent.setLoading(false);
      }
    }
    parent.setLoading(false);
  }

  void resetErrors() {
    parent.setState(() {
      parent.emailError = null;
      parent.passwordError = null;
      parent.repeatPasswordError = null;
    });
  }

  static bool validateEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  bool validatePassword(String password, [String repeatPassword = '']) {
    bool isValid = true;
    if (password.length < 6) {
      isValid = false;
    }
    if (repeatPassword.isNotEmpty && password != repeatPassword) {
      isValid = false;
    }
    return isValid;
  }
}
