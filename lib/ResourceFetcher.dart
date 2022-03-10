import 'package:alexa_clean_the_kitchen/models/backend_response.dart';
import 'package:alexa_clean_the_kitchen/reactor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


/// requests resources from server
class ResourceFetcher {
  int resourceId;
  int userId;
  String token;

  ResourceFetcher({this.userId, this.token, this.resourceId});

  static String get uri => 'localhost:3000';

  static String get deviceSyncPath => 'clean';

  static int get okStatusCode => 200;

  static  Future<Function> syncBackendWithDevice() async {
    int userId = 2;
    String backendToken = 'test';
    String refreshToken = 'test';

    Map<String, String> headers = {'Auth': backendToken, 'refreshToken': refreshToken};
    final response =
        await http.get(Uri.http(uri, deviceSyncPath, {'userId': userId.toString()}), headers: headers);

    if (response.statusCode != okStatusCode) {
      throw Exception('Failed fetching racecourses');
    }
    BackendResponse backendResponse = BackendResponse.fromJson(jsonDecode(response.body));
    Reactor deviceReactor = Reactor(backendResponse);
   deviceReactor.syncDevice();
  }
}
