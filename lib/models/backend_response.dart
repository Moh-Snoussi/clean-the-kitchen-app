import 'dart:io';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';

/// backend response model
class BackendResponse {
  // a list of 16 bytes
  List<int> token;
  InternetAddress ipAddress;
  String method;
  var params = [];
  bool isNew;

  BackendResponse(
      {@required String token,
      @required String ipAddress,
      @required String method,
      @required var params,
      @required bool isNew}) {
    this.ipAddress = InternetAddress.tryParse(ipAddress);
    this.token = hex.decode(token);
    this.method = method;
    this.params = params;
    this.isNew = isNew;
  }

  factory BackendResponse.fromJson(Map<String, dynamic> json) {
    return BackendResponse(
        token: json['token'],
        ipAddress: json['ipAddress'],
        method: json['method'],
        params: json['params'],
        isNew: json['isNew']);
  }
}
