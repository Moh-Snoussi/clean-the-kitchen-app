import 'dart:developer';

import 'package:flutter/material.dart';

class DeviceWidget extends StatelessWidget {
  const DeviceWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(15.0), children: <Widget>[
      Text(
        'this is a text',
        style: TextStyle(fontSize: 18),
      ),
      TextField(
        decoration: InputDecoration(labelText: 'Device name'),
      ),
      TextField(
        decoration: InputDecoration(labelText: 'Device Token'),
      ),
      TextField(
        decoration: InputDecoration(labelText: 'Device Ip'),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0,20.0,0,20.0),
        child: TextButton(
          child: Text('hello'),
          onPressed: () => log('works'),
        ),
      )
    ]);
  }
}
