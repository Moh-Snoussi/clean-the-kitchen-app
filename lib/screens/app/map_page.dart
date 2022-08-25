import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/backend.requester.dart';
import '../../services/token_extrator.dart';
import '../../styles/style.dart';
import '../auth/login.dart';
import 'AppWidget.dart';

Widget getMapPage(AppWidgetState parent) {
  return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Maps maybe comming Soon',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.font),
                ),
                //   Flex(
                //     direction: Axis.horizontal,
                //     children: [Text('props:'), Text('value')],
                //   ),
                //   Flex(
                //     direction: Axis.horizontal,
                //     children: [Text('props:'), Text('value')],
                //   ),
                //   Flex(
                //     direction: Axis.horizontal,
                //     textDirection: TextDirection.rtl,
                //     children: [Icon(Icons.edit)],
                //   )
                // ]),
                //),
              ])));
}
