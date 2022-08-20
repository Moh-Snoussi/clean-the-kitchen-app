import 'dart:developer';
import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/services/device.request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

int userId;
String backendToken;
String refreshToken;

getPermission(User user) async {
  Firebase.initializeApp().then((value) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    String token = await messaging.getToken();
    user.mobileId = token.toString();
    BackendRequester.registerPushClient(user);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  _deviceActivate(message);
}

void registerPushHandler(User user) async
{
  await getPermission(user);

  if (!user.notificationRegistered) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) =>
        _deviceActivate(message));
    user.notificationRegistered = true;
  }
}

_deviceActivate(RemoteMessage message) {
  Command command = Command.fromMessage(message);
  try {
  DeviceRequester.forwardCommands(command);
    command.success = true;
  } catch (e) {
  }
  User.fromSecureStorage().then((user) => BackendRequester.logOnBackend(command, user));
}
