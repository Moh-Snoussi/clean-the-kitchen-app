import 'dart:developer';
import 'package:alexa_clean_the_kitchen/models/user.dart';
import 'package:alexa_clean_the_kitchen/reactor.dart';
import 'package:alexa_clean_the_kitchen/services/backend.requester.dart';
import 'package:alexa_clean_the_kitchen/services/device.request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

int userId;
String backendToken;
String refreshToken;
bool busy = false;

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

    messaging.onTokenRefresh.listen((token) {
      log(token.toString(), name: "push token from firebase refresh");
      user.mobileId = token.toString();
      BackendRequester.registerPushClient(user);
    });

    String token = await messaging.getToken();
    log(token.toString(), name: "push token from firebase");
    user.mobileId = token.toString();
    BackendRequester.registerPushClient(user);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  _deviceActivate(message);
}

void registerPushHandler(User user) async {
  await getPermission(user);

  if (!user.notificationRegistered) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage
        .listen((RemoteMessage message) => _deviceActivate(message));
    user.notificationRegistered = true;
  }
}

_deviceActivate(RemoteMessage message) async {
  log(message.notification.body.toString(), name: "from fireBaseMessage");

  Command command;
  if (!busy) {
    try {
      busy = true;

      command = Command.fromMessage(message);
      try {
        command.success = await DeviceRequester.forwardCommands(command);
      } catch (e) {
        command.errors = e.toString();
        log(e.toString(), name: "from push notification error");
      }
    } catch (e) {
      print(e.toString());
    } finally {
      busy = false;
      if (command != null && command.success != null) {
        User user = await User.fromSecureStorage();
        Map response = await BackendRequester.logOnBackend(command, user);
        log(response.toString(),
            name:
            "from backend log device action response 'api/device/action_process'");
      }
    }
  }
}
