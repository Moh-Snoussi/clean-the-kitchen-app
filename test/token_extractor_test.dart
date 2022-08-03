import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';


void main() {
  final dio = Dio(BaseOptions());
  final dioAdapter = DioAdapter(dio: dio);

  group("Tests the Token extractor", () {
    test("Agent Id should be between 65 and 69", () {
      TokenExtractor extractor = TokenExtractor(XiomiUser.empty());

      String agentId = extractor.generateAgentId();
      expect(agentId.length, 13 * 2);

      agentId.codeUnits.forEach((element) =>
          expect(
              ["5", "6", "7", "8", "9"],
              contains(new String.fromCharCode(element))));

      print(agentId);
    });

    test("Device Id should be 6 in length", () {
      TokenExtractor extractor = TokenExtractor(XiomiUser.empty());

      String agentId = extractor.generateDeviceId();
      expect(agentId.length, 6);
      print(agentId);
    });

    void mockHttpLogin1(Dio dio) {
      dioAdapter.onGet(
        TokenExtractor.loginStep1Url,
            (server) =>
            server.reply(
              200,
              {'_sign': 'success'},
              // Reply would wait for one-sec before returning data.
              delay: const Duration(seconds: 1),
            ),
      );
    }
    test("login step 1 should success", () async {
      mockHttpLogin1(dio);
      TokenExtractor tokenExtractor = TokenExtractor(
          XiomiUser.empty(), httpClient: dio);
      bool actualResults = await tokenExtractor.loginStep1();
      expect(actualResults, true);
    });

    void mockHttpLogin2(Dio dio) {
      dioAdapter.onPost(
          TokenExtractor.loginStep2Url,
              (server) =>
              server.reply(
                200,
                {
                  'userId': 'another userId',
                  'cUserId': 'a userId',
                  'ssecurity': 'hard security',
                  'passToken': 'success',
                  'code': 'a code',
                  'location': 'https://aSecurityUrl.de',
                },
                // Reply would wait for one-sec before returning data.
                delay: const Duration(seconds: 1),
              ),
          data: Matchers.any
      );
    }
    test("login step 2 should success", () async {
      mockHttpLogin2(dio);

      TokenExtractor tokenExtractor = TokenExtractor(
          XiomiUser.empty(), httpClient: dio);
      bool actualResults = await tokenExtractor.loginStep2();
      expect(actualResults, true);
    });

    void mockHttpLogin3(Dio dio) {
      String securityUrl = "https://aSecurityUrl.de";
      dioAdapter.onGet(
          securityUrl,
              (server) =>
              server.reply(
                  200,
                  "",
                  headers:
                  {
                    "Set-cookie": [
                      "serviceToken=IreallybigfatsmallfitserviceToken;"
                    ]
                  }
              ),
          data: Matchers.any
      );
    }
    test("login step 3 should success", () async {
      mockHttpLogin3(dio);

      String securityUrl = "https://aSecurityUrl.de";

      TokenExtractor tokenExtractor = TokenExtractor(
          XiomiUser.empty(), httpClient: dio);
      tokenExtractor.xiomiSecurity = XiomiSecurity(location: securityUrl);
      bool actualResults = await tokenExtractor.loginStep3();
      expect(actualResults, true);
    });

    test("login as whole success", () async {
      mockHttpLogin1(dio);
      mockHttpLogin2(dio);
      mockHttpLogin3(dio);

      TokenExtractor tokenExtractor = TokenExtractor(
          XiomiUser.empty(), httpClient: dio);

      bool actualResults = await tokenExtractor.login();
      expect(actualResults, true);
    });


    test("Password should be correctly hashed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      String actualHash = tokenExtractor.hashPass("anyPass");
      String expectedResults = "0684828B47A8C51E4388E84DAEC31925";

      expect(actualHash, expectedResults);
    });

    test("Nonce should be correctly created", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      String actualHash = tokenExtractor.generateNonce(DateTime
          .now()
          .millisecondsSinceEpoch
          .floor() * 1000);

      expect(actualHash, isNotEmpty);
    });

    test("Nonce should be correctly signed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      dynamic actualHash = tokenExtractor.signNonce(
          "Slx5TxW98gYBpf7s", "Yz+ZSf5TvkPXUAayccOqNQ==");
      String expectedResults = "yEJhmw33NvbUdZpUaescFxC9enwDOYlm4AcAX7oP2iA=";

      expect(actualHash, expectedResults);
    });

    test("signature params should be correctly hashed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      Map actualParams = tokenExtractor.generateEncParams(
          "https://us.api.io.mi.com/app/home/device_list",
          "POST",
          "BwoVxjL2BFdS0H4NDdgFK0EZ2jQ6kHZYIFTSLJ/TiiA=",
          "81JENcAzjgYBpf/G",
          {
            "data": '{"getVirtualModel":true,"getHuamiDevices":1,"get_split_device":false,"support_smart_home":true}'
          },
          "BE/Gj05FWCiNcRTMJsT0qQ=="
      );
      String expectedResults = "9r92KSj1fTa3bfB0CvQhIjAvrbc=";

      expect(actualParams["signature"], expectedResults);
    });

    test("Enc signature should be correctly hashed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      dynamic actualHash = tokenExtractor.generateEncSign(
          "https://us.api.io.mi.com/app/home/device_list",
          "POST",
          "BwoVxjL2BFdS0H4NDdgFK0EZ2jQ6kHZYIFTSLJ/TiiA=",
          {
            "data": '{"getVirtualModel":true,"getHuamiDevices":1,"get_split_device":false,"support_smart_home":true}'
          }
      );
      String expectedResults = "RCAV8brgyX1A/c47/vC0bsrpUoY=";

      expect(actualHash, expectedResults);
    });

    test("rc4 encryption should be correctly hashed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      dynamic actualHash = tokenExtractor.encryptRc4(
          "hellomoh", "anypayloadshouldwork");
      String expectedResults = "GlkDXAZqRruFtCTiuuExrQBx+pk=";

      expect(actualHash, expectedResults);
    });

    test("rc4 decryption should be correctly hashed", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      String toEncrypt = "I am going to say a secret that only with the secret can be dycripted";
      String secret = "Iamasecretss";
      String enrypted = tokenExtractor.encryptRc4(secret, toEncrypt);
      String decrypted = tokenExtractor.decryptRc4(secret, enrypted);

      expect(decrypted, toEncrypt);
    });

    test("generate crypted params should be correctly", () async {
      TokenExtractor tokenExtractor = TokenExtractor(XiomiUser.empty());

      Map actualHash = tokenExtractor.generateEncParams(
          "https://us.api.io.mi.com/app/home/device_list",
          "POST",
          "BwoVxjL2BFdS0H4NDdgFK0EZ2jQ6kHZYIFTSLJ/TiiA=",
          "81JENcAzjgYBpf/G",
          {
            "data": '{"getVirtualModel":true,"getHuamiDevices":1,"get_split_device":false,"support_smart_home":true}'
          },
          "BE/Gj05FWCiNcRTMJsT0qQ=="
      );
      Map expectedResults = {
        'data': 'w+PUq//uS1VNpdL48HyEiKHSajBWTBLJCE2EKtrju6F/DTxh43N3LDIZxVxC0yJr3uG0lnKz9imHFhWPRZp8zgpSsvb82tbR85W0hI7P5lWdoNQ9ueP2IFuDBYToG6Q=',
        'rc4_hash__': '6oLymLPaUEBAiILVknDU2uKGE3RGSgWVf0W4Yw==',
        'signature': '9r92KSj1fTa3bfB0CvQhIjAvrbc=',
        'ssecurity': 'BE/Gj05FWCiNcRTMJsT0qQ==',
        '_nonce': '81JENcAzjgYBpf/G'
      };

      expect(actualHash, expectedResults);
    });
  });
}
