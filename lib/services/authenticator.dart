import 'dart:convert';
import 'dart:developer' as dev;

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/styles/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lwa/lwa.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_lwa_platform_interface/flutter_lwa_platform_interface.dart';

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

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  LwaAuthorizeResult _lwaAuth;
  LwaUser _lwaUser;
  User _backendUser = User(userEmail: '', provider: '', providerId: '');

  final accessTokenController = TextEditingController();
  final refreshTokenController = TextEditingController();
  final validUntilController = TextEditingController();

  Color _pasteColor;

  static const String loginAction = 'Login';
  static const String registerAction = 'Register';
  static const String defaultAction = loginAction;
  String currentAction = defaultAction;

  @override
  void initState() {
    super.initState();
    _loginWithAmazon.onLwaAuthorizeChanged.listen((LwaAuthorizeResult auth) {
      setState(() {
        _lwaAuth = auth;
      });
      _fetchLWAUserProfile();
    });

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount googleUser) {
      setState(() {
        _backendUser = User.fromGoogle(googleUser);
      });
    });
  }


  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _fetchLWAUserProfile() async {
    if (_lwaAuth != null && _lwaAuth.isLoggedIn) {
      _lwaUser = await _loginWithAmazon.fetchUserProfile();
      setState(() {
        _backendUser = User.fromAmazon(_lwaUser);
      });
    } else {
      _lwaUser = null;
      dev.log(_backendUser.provider);
    }
  }

  Future<void> _handleLWASignIn(BuildContext context) async {
    try {
      await _loginWithAmazon.signIn();
    } catch (error) {
      if (error is PlatformException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${error.message}"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
        ));
      }
    }
  }

  Future<void> _handleLWASignOut() => _loginWithAmazon.signOut();

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      dev.log(error.toString());
      if (error is PlatformException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${error.message}"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
        ));
      }
    }
  }

  Future<void> _handleGoogleSignOut() => _googleSignIn.disconnect();

  toggleAction() {
    setState(() {
      currentAction =
      currentAction == loginAction ? registerAction : loginAction;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String assetName = 'lib/assets/login_background.svg';
    //final Widget svg = SvgPicture.asset(
    //assetName,
    //);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: currentAction,
        theme: ThemeData(
            primaryColor: AppColors.primary,
            backgroundColor: AppColors.background),
        home: Stack(children: [
          //svg,
          Card(
              child: _backendUser.providerGranted()
                  ? tokenWidget()
                  : loginWidget()),
        ]));
  }

  loginWidget() {
    return ListView(
        padding: const EdgeInsets.fromLTRB(6.33, 50.0, 6.33, 0),
        children: <Widget>[
          Text(
            currentAction,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 24),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Email',
                helperText: 'The email you used when you first register'),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Password', helperText: 'Type your password'),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 20.0, 0, 0),
              child: ElevatedButton(
                child: Text(currentAction),
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ))),
                onPressed: () => toggleAction(),
              )),
          ElevatedButton.icon(
            label: Text(
              currentAction + " with Google",
              textAlign: TextAlign.left,
            ),
            style: ButtonStyle(
                alignment: Alignment.center,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ))),
            icon: FaIcon(FontAwesomeIcons.google),
            onPressed: () =>
            currentAction == loginAction
                ? _handleGoogleSignIn(context)
                : _handleGoogleSignOut(),
          ),
          ElevatedButton.icon(
            label: Text(
              currentAction + " with Amazon",
              textAlign: TextAlign.left,
            ),
            style: ButtonStyle(
                alignment: Alignment.center,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ))),
            icon: FaIcon(FontAwesomeIcons.amazon),
            onPressed: () => _handleLWASignIn(context),
          ),
          Card(
            color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ]);
  }

  tokenWidget() {
    return Container(
      color: AppColors.background,
        padding: const EdgeInsets.only(top: 25.0),
        child: ListView(children: [
          Row(
            children: [
              Container(
                height: 70,
                width: 70,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  color: Colors.green.shade300,
                  child: Icon(
                    Icons.check,
                    size: 30,
                  ),
                ),
              ),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: Text(
                            'You successfully logged in with ' +
                                _backendUser.provider +
                                ', one more step is required:',
                            style: (TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ))
            ],
          ),
          Row(
            children: [
              Container(
                height: 70,
                width: 70,
                child: Card(
                  color: _pasteColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  child: Icon(
                    Icons.paste,
                    size: 30,
                  ),
                ),
              ),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: new RichText(
                              text: new TextSpan(children: [
                                new TextSpan(
                                  text: 'Login at:',
                                  style: new TextStyle(color: Colors.black),
                                ),
                                new TextSpan(
                                  text: ' alexa-clean-the-kitchen.de',
                                  style: new TextStyle(color: Colors.blue),
                                  recognizer: new TapGestureRecognizer()
                                    ..onTap = () {
                                      launch(
                                          'http://' + BackendRequester.backendUrl + '/login'
                                      );
                                    },
                                ),
                                new TextSpan(
                                  text: ', and import the following values:',
                                  style: new TextStyle(color: Colors.black),
                                ),
                              ])),
                        ),
                      ),
                    ],
                  ))
            ],
          ),
          Card(
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8.0),
              children: [
                TextField(
                  controller: accessTokenController,
                  decoration: InputDecoration(
                      labelText: 'Token',
                      helperText: 'this value can be found on xxx '),
                ),
                TextField(
                  controller: refreshTokenController,
                  decoration: InputDecoration(
                      labelText: 'Refresh token',
                      helperText: 'refresh token can be found on xxx'),
                ),
                TextField(
                  controller: validUntilController,
                  decoration: InputDecoration(
                      labelText: 'Valid till',
                      helperText: 'refresh token can be found on xxx'),
                ),
                Stack(
                  alignment: Alignment(0.7, 0.9),
                  children: [
                    Container(
                      transform: Matrix4.translationValues(0, 45, 0),
                      //alignment: Alignment(0, 0.9),
                      margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                      child: MaterialButton(
                        height: 60,
                        onPressed: () async {
                          ClipboardData data = await Clipboard.getData('text/plain');
                          List<String> spliced = data.text.split(' ');

                          log.info(spliced.toString());
                          log.info(spliced.length.toString());

                          if (spliced.length == 3) {
                          accessTokenController.text = spliced[0];
                          refreshTokenController.text = spliced[1];
                          validUntilController.text = spliced[2];
                          _backendUser.accessToken = spliced[0];
                          _backendUser.refreshToken = spliced[1];
                          _backendUser.validUntil = int.parse(spliced[2]);
                          setState(() {
                              _pasteColor = Colors.green.shade300;
                            });
                          }
                        },
                        color: Colors.blue,
                        textColor: Colors.white,
                        child: Icon(
                          Icons.paste,
                        ),
                        padding: EdgeInsets.all(16),
                        shape: CircleBorder(),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 50),
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              label: Text(
                'Authenticate',
                textAlign: TextAlign.left,
              ),
              style: ButtonStyle(
                  alignment: Alignment.center,
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ))),
              icon: FaIcon(FontAwesomeIcons.key),
              onPressed: () => {
                //presistLogin()
              },
            ),
          ),
        ],
        ),
        );
    // return Container(
    //   color: AppColors.background,
    //   child: ListView(
    //     children: <Widget>[
    //       Card(
    //         child: Padding(
    //           padding: const EdgeInsets.all(8.0),
    //           child: Text(
    //             'You successfully logged in with ' +
    //                 _backendUser.provider +
    //                 ', one more step is required:',
    //             style: (TextStyle(fontWeight: FontWeight.bold)),
    //           ),
    //         ),
    //       ),
    //       Padding(
    //         padding: const EdgeInsets.all(8.0),
    //         child: new RichText(
    //             text: new TextSpan(children: [
    //           new TextSpan(
    //             text:
    //                 'To unsure security we kindly require you to login in to the website at:',
    //             style: new TextStyle(color: Colors.black),
    //           ),
    //           new TextSpan(
    //             text: ' alexa-clean-the-kitchen.de',
    //             style: new TextStyle(color: Colors.blue),
    //             recognizer: new TapGestureRecognizer()
    //               ..onTap = () {
    //                 launch('https://www.alexa-clean-the-kitchen.de');
    //               },
    //           ),
    //           new TextSpan(
    //             text: ', and import the following values:',
    //             style: new TextStyle(color: Colors.black),
    //           ),
    //         ])),
    //       ),
    //       Card(
    //         color: AppColors.secondary,
    //         child: ListView(
    //           scrollDirection: Axis.vertical,
    //           shrinkWrap: true,
    //           padding: const EdgeInsets.all(8.0),
    //           children: [
    //             TextField(
    //               decoration: InputDecoration(
    //                   labelText: 'Token',
    //                   helperText: 'this value can be found on xxx '),
    //             ),
    //             TextField(
    //               decoration: InputDecoration(
    //                   labelText: 'Refresh token',
    //                   helperText: 'refresh token can be found on xxx'),
    //             ),
    //             Stack(
    //               alignment: Alignment(0.7, 0.9),
    //
    //               children: [
    //                 Container(
    //                   height: 30,
    //                   transform: Matrix4.translationValues(0, 50, 0),
    //                 //alignment: Alignment(0, 0.9),
    //                 margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
    //                 child: MaterialButton(
    //                   onPressed: () {},
    //                   color: Colors.blue,
    //                   textColor: Colors.white,
    //                   child: Icon(
    //                     Icons.paste,
    //                     size: 24,
    //                   ),
    //                   padding: EdgeInsets.all(16),
    //                   shape: CircleBorder(),
    //                 ),
    //               )],
    //             ),
    //           ],
    //         ),
    //       ),
    //       ElevatedButton.icon(
    //         label: Text(
    //           'Authenticate',
    //           textAlign: TextAlign.left,
    //         ),
    //         style: ButtonStyle(
    //             alignment: Alignment.center,
    //             shape: MaterialStateProperty.all<RoundedRectangleBorder>(
    //                 RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.zero,
    //                 ))),
    //         icon: FaIcon(FontAwesomeIcons.key),
    //         onPressed: () => log('handle backend login'),
    //       ),
    //       Padding(
    //         padding: const EdgeInsets.all(80.0),
    //         child: Image(
    //             image: AssetImage('lib/assets/logo.png'),
    //             width: 200.0,
    //             height: 200.0),
    //       )
    //     ],
    //   ),
    // );
  }
}
