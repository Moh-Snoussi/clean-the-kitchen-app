import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/screens/auth/authenticator.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:flutter_lwa/lwa.dart';
import 'package:flutter_lwa_platform_interface/flutter_lwa_platform_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

class SocialLogin {
  AuthenticatorState parent;

  SocialLogin(this.parent);

  LoginWithAmazon _loginWithAmazon = LoginWithAmazon(
    scopes: <Scope>[ProfileScope.profile(), ProfileScope.postalCode()],
  );

  GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    scopes: <String>[
      'email',
      'profile',
    ],
  );

  Future<void> handleGoogleSignIn() async {
    parent.setLoading(true);
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount googleUser) async {
        User user = User.fromGoogle(googleUser);
        Map<String, dynamic> response = await BackendRequester.registerUser(user);
        if(response['success']) {
          user.userId = response['userId'];
          parent.setState(() {
            parent.backendUser = user;
          });
        }
    });
    try {
      await _googleSignIn.signIn();
    } catch (error) {log.info(error.toString());
    parent.setErrorMessage(error.toString());
    }
    parent.setLoading(false);
  }

  Future<void> handleLWASignIn() async {
    parent.setLoading(true);

    _loginWithAmazon.onLwaAuthorizeChanged
        .listen((LwaAuthorizeResult auth) async {
      if (auth.isLoggedIn) {
        LwaUser _lwaUser = await _loginWithAmazon.fetchUserProfile();
        User user = User.fromAmazon(_lwaUser);
        Map<String, dynamic> response = await BackendRequester.registerUser(user);
        if(response['success']) {
          user.userId = response['userId'];
          parent.setState(() {
            parent.backendUser = user;
          });
        }
      }
      parent.setLoading(false);
    });
    try {
      await _loginWithAmazon.signIn();
    } catch (error) {
      parent.setErrorMessage(error.toString());
      parent.setLoading(false);
    }
  }
}
