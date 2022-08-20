import 'dart:convert';
import 'dart:typed_data';
import 'dart:typed_data';

import 'package:alexa_clean_the_kitchen/services/device.request.dart';
import 'package:alexa_clean_the_kitchen/services/token_extrator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:miio/miio.dart';

void main() {
  group("Tests requests to the user device", () {
    test("User device should return hello packet", () async {
      MiIoDevice device = new MiIoDevice(
          token: hex.decode("4e4c6b55736454564d6952334574506b"),
          address: InternetAddress.tryParse("192.168.2.39"));
 dynamic deviceResponse = await device.call("miIO.status", []);


      //dynamic deviceResponse = await device.call("get_properties", [{'did': 'battery_level', 'siid': 2, 'piid': 1}]);
      expect(deviceResponse, isTrue);
    });

    test("User device should  hello packet", () async {
      TokenExtractor extractor = TokenExtractor(
          XiomiUser(
              username: 'sooniic@live.com', //usernameController.value.text,
              password: '720327Sonic', // userpassController.value.text,
              server: XiomiServer.de),
          cacheDevices: true);
      bool loginSuccess = await extractor.login();
      if (loginSuccess) {
        //List<XiomiDevice> devices = await extractor.geDevices();
        int userId = 6347111016;
        String deviceId = "332856720";

        String apiUrl = extractor.getApiUrl(XiomiServer.de) +
            "/v2/home/get_interim_file_url";
        String objectName =
            '{"obj_name":"' + userId.toString() + '/' + deviceId + '/0"}';
        Map<String, String> params =
            new Map<String, String>.from({"data": objectName});
        String response = await extractor.callEncrypted(apiUrl, params);

        String mapUrl = json.decode(response)["result"]["url"];

        Response response2 = await extractor.getMapData(mapUrl);

        expect(response, true);
      }
    });

    List<int> mapDecode(String mapBody) {
      mapBody = mapBody.replaceAll("_", "/").replaceAll("-", "+");
      List<int> bodyBytes = base64Decode(Uri.decodeComponent(mapBody));
      return zlib.decode(bodyBytes);
    }

    Map reformateData(String mapBody) {
      List bodyBytes = mapDecode(mapBody);

      Int32List vacuumPos1 = new Int32List(4)
        ..[0] = bodyBytes[5]
        ..[1] = bodyBytes[6];
      int pos1 = vacuumPos1.buffer.asByteData().getInt8(0);
      Int32List vacuumPos2 = new Int32List(4)
        ..[0] = bodyBytes[7]
        ..[1] = bodyBytes[8];
      int pos2 = vacuumPos2.buffer.asByteData().getInt8(0);
      Int32List vacuumPos3 = new Int32List(4)
        ..[0] = bodyBytes[9]
        ..[1] = bodyBytes[11];
      int pos3 = vacuumPos3.buffer.asByteData().getInt8(0);

      Int32List vacuumWidth = new Int32List(4)
        ..[0] = bodyBytes[19]
        ..[1] = bodyBytes[20];
      int width = vacuumWidth.buffer.asByteData().getUint8(0);
      Int32List pxSize = new Int32List(4)
        ..[0] = bodyBytes[17]
        ..[1] = bodyBytes[18];
      int pxSizex = pxSize.buffer.asByteData().getInt8(0);
      Int32List vacuumHeight = new Int32List(4)
        ..[0] = bodyBytes[21]
        ..[1] = bodyBytes[23];
      int height = vacuumHeight.buffer.asByteData().getUint8(0);

      Int32List lefts = new Int32List(4)
        ..[0] = bodyBytes[23]
        ..[1] = bodyBytes[24];
      int leftsx = lefts.buffer.asByteData().getInt8(0);
      Int32List top = new Int32List(4)
        ..[0] = bodyBytes[25]
        ..[1] = bodyBytes[26];
      int topX = top.buffer.asByteData().getInt8(0);

      return json.decode(utf8.decode(bodyBytes.sublist((height * width) + 27)));
    }

    test('testMapDecode', () async {
      String mapBody =
          "eF7t10fOw8iZBuDGwEeYAxj_ugkwh8Z4IYo5J1EkDYNgzkHMpGH41rP1sG14lnOAgZ6FBJZKBaaq760__PKf_yH-4-__-Psvv_z--Y-_w7_Ev2y__Nd_K3_45evr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr6-vr_6G__sTLz29_xuFfIQz9y68_3VKlP7_9YBmWIyCGQySRZD-__lRz0mZR3w7Fz2_LtGa__vTRdPebkj_2SR__8e6S5D-_QfcAU3S3g3dDP_2zYam6bF6ibgy7-W7AcRABKYygKAr89WfK2rvxrz9z8vPbfZgn__xLmt2n9Offu8IgToLErwD0l7_87e5dzd09eMYRC5xwK-aYr2PjX9vcubAKdfq0YAXS8CXv07T7fhbFgwY_ldIbmm4ruzCRj2dletXzXdg6EYUwTeQYUx7n1ixW19hwCHQUHmF9uq44hUEDFQLAZucpBaUUsiFxmAs9EQJGBrl201dJXYMiE_dLazqom7g8DLM-9KKZFHjO0fRAVmGdVob5FCK0X9xWPripjI0KLEmXaTL0zbgtmmRgYL15lGDqKK8zr5PQDKZE7ySSPjPhDhdKtK6O-F2hOovN_DGsdWnE5bS4fpiXqIOSONPABqcMNPjSLyzyeoN_VetVJSe7ZcR0qCKqbo16sTMwiFA7dnShlGheZvLZOYYuJuYDV7SrZsuLf2TVkIgAT4AIQ-FxmVHGvr17FFmVkhuxRbCcVWjtbPXN9hi59wPg112M0US2oJdS9nJVyZTzMuuJ659u6HMMEULq2LHuGw6eA7n2ST7uiNFBpDTuC7LHHMtYWY96C_HK2EQHriVmxcYwMOFFRhaNrpyFtRut5tupABnBIbY4nBdk6mnOQ59KEPCsDiClpnUPBfj6qPoJzBkL0AkeywYfeaGIOJMra6Y4qR3jCKdSeYRTl0jeAci8nK02fhLvqcRE-4DR8DMpkf9WS8-WULoA3iu27HFdNZKNWtggz8pFCYHyrpUkfkkOG-D9Ai0noVInykjLlG6ON1VIPa_g8saNstmksp9Bjx0PQBpicQYU-AliY8ZPU90bFVUsepqxAAEYzXRh7pALQk2ZVI1mg0gmPbSncSE9D5NErEzILkdY1u0xqkN8QEplk4xCR6jX4xn4tjkLoVFTaLFroeTOi_WtXPBEEQA6Mj79_oyChIZDpOY3rFTFvnz2Hpg_Kv5DlLWc872zJcZClWf_1p9qxruOTVZiMOm6PibxysMk1T-uOnibuPIpO4DmU1a1Y941j7xy2GOaub1QXT4D-Mec1miOZrF1QMlrt-o5ZkuEwSPo9cnU-3QuGpbnZ1v30CnMXtvEn5NNTX1TaUZ_H1BNnkUsNNjOqXEHej0zIgoh3y9-ZlRmOk87CBGHyk3MAmtq35Wo5l8Si6ihwYVorrb5a6vX-nSt-j4ffTqtCCPwp5be78Fb0rU9BIWHVAqCJZGaBAIsxlc4PT-JetPZpbWMN3bPt4cqo8ID9Ey68gaAfT517dS4_eG7p14Wc1Gry4h7CXAfv8uOEmApatF0tpbOHQEhYmO3ibYSKt9YxMdg7reLa2eGaMQ1q5UvUnweKug9xtL3Zd4-2dnR6F32be5pDWsZP3Yz0VuW9rtIqV7gnM3YLCkT0fHnyc21Ju26b2uv3_sSj8OejZZlAn6x7inLZTI9a0Ipc-KOvqyyEjUO9P2qthKeZwewp8v__e2jjLv5FASf3DX50yaGGpq_j_uCOR_693VuVvLg2cRpImV47EqTM7TF8P_nPUovNZ-dHc0KhnJShXBdnuJqalIz571YNeXDPES5NZXAwb6nqN8t-MT44CZOpeQLnLUaZacvQ0a_KKweIq95G6uP8-49yPQxSje3fRwuUc5DfL4_aezyW1vzdsG0R37CGdLRowQj9kaMNyK-yodzflz2lSt1GCZ9T6C5ou2AQWEZdB8BeCgw4fEKHWjK89yhZkOB77Y6pPJVOHCAZyHSCK8rM4jjLgAKhmrQTj0Jn8ont4OFnr-uDc-asGjqz77_6U-_179_FbO7aP38Bt_f4_qvgjhV_y5iPbvqAvsyTXnjnFdQYTsCX3W-8xZzPgofZMuCfUqP2dtXKUMeHNcUM0ungyDxeSWeaqi9kPODCv5nOMVLyy3QbVOfjPNL0kB8loAc2ZyQojQHzsOxBrqQIHEiDT1940rPW1PdKvvcF5txjx9NcsIFbWtrefplzp9How-fQ7EEXmwONbE0EN1nTR2Vy9Fhtk-8yA3StHlpB7F-JhWSW9reXubYTgcd0KZ_v6tiaqI0NrZt_dFHWw1dZyD0nVrONwxziofz43NRPiIUwaDCO8GmTw7uwpK5SU4XZo13gAWBLEh1BANQiQNGDYkD0x4L8voY69EqXPw7jsySmK8lctVF5uiH3pl502Wb3z7WpOwwJXy-Je4asAfEDnqRXlGeCtU4D3mKuJYtQAcTVZ7Co_iWEFTUtMHhRtorE1ksgaLMjDWLB1X9KWiHAZEotZdzxwLRIdNmjKsFSfST9FLIZGYCiRzGWHBhM5ArtYstIrOMfYDkcxOHKaobdHXGveoNaXjAfshJbkh7tMq0tEAvsJPBeKw-G86z5QWJPcsnenSaRZr4nEKGno6P8DIGxmDFriVuJpKIc2-vM-DN6RZbIpZP9qY-sd5k0ioCGW4Jmme0DlmuRKJR8tw6z5mPC1clkZpJZRHGnlXGODain_ILQKq2wdmFAMuYzY9Uhu2Me-J4mOTVe6V4UvA-69Upxa7LzHHOQokZofkyCD8XB6LLl_fwZk2d2ioLQD8Icix81Y50rpAGZT5XeKIR1X4viQzBXJ8RXSsOg92D3AeuMoNvY7N3V2OWOnKnzvVpCbooieSr2455YB55UdgQAoyg2avvulSKoPB8-3GBOjINtC-iAppBRbYiEBb1rCjFAikLOKx54jLNGZkxizKg2aL0mCjRVdqQvexn-G5_5BGNRCyCZQAkcr8ZE2NafZ2HLG12nSScmIgYXhQ7VfJDE0mvuEZk1SKcKw9KbYliE5u-xONrPChd23KPJor347jXwGZBdJYWN40eYYPFUrfrOyF0aRgQWaHjValklEcSXm7KKz3DQWsQJFPrINxmA_fTskVIRe7A4cGES9RgwegJDrKLtWQnfBw8s8rSwj15QFrfTEtIiMFHlsi8NEFlh9x6C9U5oDqHbSx8BEv1Vp8GX2LI-3RWyxXSN6kqrLnMh7RHFGmyJHRt2AUpGye-yywA1irwEWTGRr8_iCprXkeCltiBKubgJFQX3M-yX8-85epqzI3P_iBPty99INo_D-cq5Ag3Z4WWiici4JQXaAgNtPoEo2jesyfJjs2dnf1lJUdjK8_ZUvagr9VJ9jD4k63S0Vp5cSaFALy6qEU0iIXjg4LY9OjfO53XmCHwuYit4FPbvcB-FDn8QlTWJCeX8rfX4Rkxbz4a34VZ9a08OrdgTjxE54O3hviqP1ACh0xfUZmAMeJpiJjRJrWFOxIK09IBJ08L8Hl3Huud3DHCepx36kVxtOGOmQmHkX7nGZQBJqivkuzQx1uL4xfDOia8aSSVV5sveapvzsIUdxiqGM8dGxv9MZW41jJsoAa2KQY8H5_2egGyM0QHVvTUCa9SjU0SXVqSxxXUFGnKQzGErmGmufroC9mkLoVVyb3nENZY3lrOyExXHsd0pbWCbtPIXPLZyO1kLC-X40qlBHyIXjF1oFO35IMFhewqC55AfGfpoUVRmoQreCRBgwty0rQjZBhf8uuQeRYmSxu3Wkd6ImeXSfv4toeyZja-1Rp0W0rfncvU0DIyOt7AfaMHPithKGhyVMFRfV9ad1mVbRV8Xdxn4NBfiVs6XIjf0a0KqKe5aqdkRMST71TaCE8dodxcBlgKrbwrEY1XtINPVQva7NOizSZ0WyvaPTKucUVmSDg3faSL1kF3TuKbmscXkY9Zc9-8q1eHoqwXIZNnfdBJ0SH49UnpoWozBRGbDWH3ilw_V68I5GqqwZ3XZF2NRWjsG6XjFu-q6HojobsaBOvefB6mNtivg0JigLuwGdPZai1muuGfLBEMdKenHMpVHqTSYSh-hjcECnR2cpYF19a9ZyCnrYChUt_IQUINFsB5gIbqp6lMw2s9uOBi_DfKyR3eOXbFd16FSk_ekp3VW0s-VXThdaB8DAwGWL3kGEnRczKU5PNYh3eWVPFa2GtKj3d2uNd7qea54xXv7yNyX687gKUIW_N0YGCxKMqAYj9hpspyKjieC0VT4usiJocPkz3VAVynqVDgMJWgN8uZ0F0MW558UA8bmTAidJZOC62NN_vNhKUHOOkmGNo1g7wvTqdgiQV9LGmTgDvucJsgqs-ckq6w-JVS5GTR94qL1g0cADFvN14kv7LjCGhMaok6nkvy0JbXOed3bu2Mylo_bcRGy2kCbS8xSHkvcE_hmq1PeEjJJXWEAMCqpcH3FN3YMrm2qji78ODS4tROG5CemJpzQOreG2yQsZWQd3E6QoIei8ioJ0jSbLdSSRdPlqa7dCx4n2ss1XNjClg2caRZsbUJsTUrxi9EdXimeyJbrkWIUW1Og0gUFmN5zI5vnraRfVE2ngIyhruCLnenK0akESV2Q-yNclRxjGrBkOuZEpUpYDnjR29sLxeo3vdFJW6L-UE74fveVfJO-jUNdcU9zeDFDo8795gLXGdUUiDRgwhicauPTpK3yoiZFdpG56P31VA6YqvceaK72Iwi_Mro3NnakByo67ayoDPS7l0GF4pWlczBXTJqNk5t2THYOiiMatwOoTYRjAEHpUnyU3yio3d5R6IRaX4NPoBc9YnqRxVAfPb0fTfzhqCPl90HSVf3e8hNyBhPzRaeyGCFPGdjCC-1-bGYqztRx0SkjHah9VpMTLrcX3nRbgWb37kdu-5rpOwm1AqeQJf-MkaCLjK2b2i7n6-NLCMLZjPluARIskH_3jAv97a-jbNQ2iJQ50B53okDyRpmae0Jo4izaZC8y87relzvdx77CvZJZQ3gzxzVYlXnYDdW47iEKCD3aoxahXi8czxzkmEIKMGOAoYXEnM9EURYJGhm5DMa5UIMoeGWN9GjBpiQOLBcmO4g7RHXmpvAdYzAegVPuCTFzMi2fM6hHSuGxx38__Y_IQZ-4w==";
      Map addiontalData = reformateData(mapBody);
      String rism = addiontalData["rism"];
      Map addiontalData2 = reformateData(rism);


      expect(true, true);
    });
  });
}

class XiomiMapHeader {}
