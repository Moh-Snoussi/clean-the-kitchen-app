// Copyright (C) 2020-2021 Jason C.H
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

import 'protocol.dart';
import 'utils.dart';

/// Represent a packet in MIIO LAN protocol.
@immutable
class MiIoPacket {
  /// AES-CBC cipher for payload encryption.
  static final _cipher = AesCbc.with128bits(macAlgorithm: MacAlgorithm.empty);

  /// The "hello" packet.
  static final hello = MiIoPacket._(
    length: 0x20,
    unknown: 0xFFFFFFFF,
    deviceId: 0xFFFFFFFF,
    stamp: 0xFFFFFFFF,
    token: null,
    checksum: List.filled(16, 0xFF),
    payload: null,
    binary: [0x21, 0x31, 0x0, 0x20] + List.filled(28, 0xFF),
  );

  /// 16 bits magic.
  static const magic = 0x2131;

  /// 16 bits length.
  final int length;

  /// 32 bits unknown field.
  ///
  /// `0xFFFFFFFF` in hello packet and `0x00000000` in other packet.
  final int unknown;

  /// 32 bits device ID.
  final int deviceId;

  /// 32 bits stamp.
  ///
  /// Number of seconds since device startup.
  final int stamp;

  /// 128 bits device token.
  final List<int> token;

  /// 128 bits MD5 checksum.
  final List<int> checksum;

  /// Variable sized payload.
  final Map<String, dynamic> payload;

  /// Binary form of packet.
  final List<int> binary;

  const MiIoPacket._({
    this.length,
    this.unknown,
    this.deviceId,
    this.stamp,
    this.token,
    this.checksum,
    this.payload,
    this.binary,
  });

  /// Build an outgoing packet.
  static Future<MiIoPacket> build(
    final int deviceId,
    final List<int> token, {
    final Map<String, dynamic> payload,
    int stamp,
  }) async {
    assert(token.length == 16);
    stamp ??= MiIo.instance.stampOf(deviceId) ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Uint8List binary;
    if (payload != null) {
      // Variable sized payload.
      var binaryPayload =
          await encrypt(utf8.encode(jsonEncode(payload)), token);
      binary = Uint8List(0x20 + binaryPayload.length)
        ..setAll(0x20, binaryPayload);
    } else {
      // Header only packet.
      binary = Uint8List(0x20);
    }

    // 16 bits magic.
    binary[0] = magic >> 8;
    binary[1] = magic & 0xFF;

    // 16 bits length.
    binary[2] = binary.length >> 8;
    binary[3] = binary.length & 0xFF;

    // 32 bits unknown field `0x00000000`.
    binary.fillRange(4, 8, 0);

    // 4 bytes device ID.
    var deviceIdToWrite = deviceId;
    for (var i = 11; i >= 8; --i, deviceIdToWrite >>= 8) {
      binary[i] = deviceIdToWrite & 0xFF;
    }

    // 4 bytes stamp.
    var stampToWrite = stamp;
    for (var i = 15; i >= 12; --i, stampToWrite >>= 8) {
      binary[i] = stampToWrite & 0xFF;
    }

    // Initialize checksum field with token.
    binary.setAll(16, token);

    // 128 bits MD5 checksum.
    final checksum = md5.convert(binary).bytes;
    binary.setAll(16, checksum);

    return MiIoPacket._(
      length: binary.length,
      unknown: 0x00000000,
      deviceId: deviceId,
      stamp: stamp,
      token: token,
      checksum: checksum,
      payload: payload,
      binary: binary,
    );
  }

  /// Parse incoming packet.
  static Future<MiIoPacket> parse(
    final List<int> binary, {
    List<int> token,
  }) async {
    final length = binary[2] << 8 | binary[3];

    var unknown = 0;
    for (var i = 4; i <= 7; ++i) {
      unknown <<= 8;
      unknown |= binary[i];
    }

    var deviceId = 0;
    for (var i = 8; i <= 11; ++i) {
      deviceId <<= 8;
      deviceId |= binary[i];
    }

    var stamp = 0;
    for (var i = 12; i <= 15; ++i) {
      stamp <<= 8;
      stamp |= binary[i];
    }

    final checksum = binary.sublist(16, 32);
    final binaryPayload = binary.sublist(32);

    Map<String, dynamic> payload;
    if (token != null) {
      final decrypted = await decrypt(binaryPayload, token);
      // Remove '\x00' at the end of string.
      final payloadStr = utf8.decode(decrypted).replaceAll('\x00', '');
      payload = jsonDecode(payloadStr) as Map<String, dynamic>;
    }

    return MiIoPacket._(
      length: length,
      unknown: unknown,
      deviceId: deviceId,
      stamp: stamp,
      token: token,
      checksum: checksum,
      payload: payload,
      binary: binary,
    );
  }

  static Future<List<int>> encrypt(List<int> payload, List<int> token) async {
    assert(payload.isNotEmpty);
    assert(token.length == 16);

    // Key = MD5(token)
    final key = md5.convert(token).bytes;
    // IV  = MD5(Key + token)
    // TODO: https://github.com/dart-lang/sdk/issues/45140
    final iv = md5.convert(key.toList()..addAll(token)).bytes;

    final encrypted = await _cipher.encrypt(
      payload,
      secretKey: SecretKey(key),
      nonce: iv,
    );

    return encrypted.cipherText;
  }

  static Future<List<int>> decrypt(List<int> packet, List<int> token) async {
    assert(packet.isNotEmpty);
    assert(token.length == 16);

    // Key = MD5(token)
    final key = md5.convert(token).bytes;
    // IV  = MD5(Key + token)
    // TODO: https://github.com/dart-lang/sdk/issues/45140
    final iv = md5.convert(key.toList()..addAll(token)).bytes;

    final decrypted = await _cipher.decrypt(
      SecretBox(packet, nonce: iv, mac: Mac.empty),
      secretKey: SecretKey(key),
    );

    return decrypted;
  }

  @override
  String toString() => 'MiIoPacket('
      'len: $length, '
      'unknown: ${unknown.toHexString(8)}, '
      'device: ${deviceId.toHexString(8)}, '
      'stamp: ${stamp.toHexString(8)} '
      'token: ${token.hexString.padLeft(32, '0')} '
      'checksum: ${checksum.hexString}'
      ')';
}
