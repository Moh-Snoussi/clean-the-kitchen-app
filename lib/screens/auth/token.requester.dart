import 'dart:developer';

import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/styles/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'authenticator.dart';

class TokenRequester {
  AuthenticatorState parent;

  TokenRequester(this.parent);

  Color _pasteColor = AppColors.secondary;

  final accessTokenController = TextEditingController();
  final refreshTokenController = TextEditingController();
  final validUntilController = TextEditingController();
  final clientIdController = TextEditingController();
  final secretController = TextEditingController();
  bool _isLoading = false;

  setLoading(bool loadingState) {}

  tokenWidget() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 25.0),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: [
          if (parent.isLoading)
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [LinearProgressIndicator(color: Colors.blue)])),
          if (!parent.backendUser.emailVerified)
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  color: Colors.green.shade300,
                  child: Icon(
                    Icons.vpn_key,
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
                        'Login into the website and Import the keys',
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
                              launch('http://' +
                                  BackendRequester.backendUrl +
                                  '/login?appRequest=key');
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
                  controller: clientIdController,
                  decoration: InputDecoration(
                      labelText: 'Access Code',
                      helperText: 'refresh token can be found on xxx'),
                ),
                TextField(
                  controller: secretController,
                  decoration: InputDecoration(
                      labelText: 'JWT',
                      helperText: 'refresh token can be found on xxx'),
                ),
                TextField(
                  controller: validUntilController,
                  decoration: InputDecoration(
                      labelText: 'Secret',
                      helperText: 'refresh token can be found on xxx'),
                ),
                Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      transform: Matrix4.translationValues(0, 45, 0),
                      //alignment: Alignment(0, 0.9),
                      margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                      child: MaterialButton(
                        height: 100,
                        onPressed: () async {
                          parent.setState(() {
                            parent.authenticationFailed = false;
                            parent.logout();
                          });
                        },
                        color: AppColors.secondary,
                        textColor: AppColors.background,
                        child: Icon(
                          Icons.arrow_back,
                        ),
                        padding: EdgeInsets.all(16),
                        shape: CircleBorder(),
                      ),
                    ),
                    Container(
                      transform: Matrix4.translationValues(0, 45, 0),
                      //alignment: Alignment(0, 0.9),
                      margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                      child: MaterialButton(
                        height: 100,
                        onPressed: () async {
                          try {
                            ClipboardData data =
                                await Clipboard.getData('text/plain');

                            List<String> spliced = data.text.split(' ');

                            if (spliced.length == 5) {
                              accessTokenController.text = spliced[0];
                              refreshTokenController.text = spliced[1];
                              clientIdController.text = spliced[2];
                              secretController.text = spliced[3];
                              validUntilController.text = spliced[4];

                              parent.backendUser.accessToken = spliced[0];
                              parent.backendUser.refreshToken = spliced[1];
                              parent.backendUser.clientId = spliced[2];
                              parent.backendUser.secret = spliced[3];
                              parent.backendUser.validUntil =
                                  int.parse(spliced[4].toString());
                              log(parent.backendUser.secret,
                                  name: 'secret_pasted');
                              log(parent.backendUser.accessToken,
                                  name: 'access_pasted');

                              parent.authenticate();
                            }
                          } catch (e) {
                            print(e.toString());
                          }
                        },
                        color: AppColors.primary,
                        textColor: AppColors.background,
                        child: Icon(
                          Icons.paste,
                        ),
                        padding: EdgeInsets.all(16),
                        shape: CircleBorder(),
                      ),
                    ),
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
              onPressed: () {
                parent.backendUser.accessToken = accessTokenController.text;
                parent.backendUser.refreshToken = refreshTokenController.text;
                parent.backendUser.validUntil =
                    int.parse(validUntilController.text);
                parent.backendUser.secret = secretController.text;
                parent.backendUser.clientId = clientIdController.text;
                parent.authenticate();
              },
            ),
          ),
        ],
      ),
    );
  }
}
