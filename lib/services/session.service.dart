
import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService
{
  static final _storage = FlutterSecureStorage();

  static void saveUser(User user) {
    user.getUserProps().forEach((key, value) {
      _storage.write(key: key, value: value.toString());
    });
  }
}