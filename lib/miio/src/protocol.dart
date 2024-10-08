// Copyright (C) 2020-2021 Jason C.H
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See th e
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:io';

import 'package:tuple/tuple.dart';

import 'packet.dart';
import 'utils.dart';

/// MIIO LAN protocol.
class MiIo {
  static final instance = MiIo._();

  /// Cached stamps.
  final _stamps = <int, DateTime>{};

  MiIo._();

  /// Cache boot time of device from response packet.
  void _cacheStamp(MiIoPacket packet) {
    _stamps[packet.deviceId] =
        DateTime.now().subtract(Duration(seconds: packet.stamp));
  }

  /// Get current stamp of device from cache if existed.
  int stampOf(int deviceId) {
    final bootTime = _stamps[deviceId];
    // ignore: avoid_returning_null
    if (bootTime == null) return null;

    return DateTime.now().difference(bootTime).inSeconds;
  }

  /// Send discovery packet to [address].
  Stream<Tuple2<InternetAddress, MiIoPacket>> discover(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    Timer(timeout, socket.close);

    socket.send(MiIoPacket.hello.binary, address, 54321);

    await for (var _ in socket.where((e) => e == RawSocketEvent.read)) {
      var datagram = socket.receive();
      if (datagram == null) continue;

      var resp = await MiIoPacket.parse(datagram.data);
      _cacheStamp(resp);
      yield Tuple2(datagram.address, resp);
    }
  }

  /// Send a hello packet to [address].
  Future<MiIoPacket> hello(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) =>
      send(address, MiIoPacket.hello, timeout: timeout);

  /// Send a [packet] to [address].
  Future<MiIoPacket> send(
    InternetAddress address,
    MiIoPacket packet, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final completer = Completer<MiIoPacket>();
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    StreamSubscription<RawSocketEvent> subscription;
    final timer = Timer(timeout, () {
      if (completer.isCompleted) return;
      completer.completeError(
        TimeoutException('Timeout while receving response.'),
      );
      socket.close();
      subscription.cancel();
    });

    subscription =
        socket.where((e) => e == RawSocketEvent.read).listen((e) async {
      var datagram = socket.receive();
      if (datagram == null) return;

      logger.v('Receiving binary packet:\n' '${datagram.data.prettyString}');
      var resp = await MiIoPacket.parse(datagram.data, token: packet.token);

      logger.d(
        'Receiving packet ${resp.length == 32 ? '(hello)' : ''}\n'
        '$resp\n'
        'with payload\n'
        '${jsonEncoder.convert(resp.payload)}\n'
        'from ${datagram.address.address} port 54321',
      );
      _cacheStamp(resp);

      timer.cancel();
      socket.close();
      completer.complete(resp);
      await subscription.cancel();
    });

    logger.d(
      'Sending packet ${packet.length == 32 ? '(hello)' : ''}\n'
      '$packet\n'
      'with payload\n'
      '${jsonEncoder.convert(packet.payload)}\n'
      'to ${address.address} port 54321',
    );
    logger.v('Sending binary packet:\n' '${packet.binary.prettyString}');
    socket.send(packet.binary, address, 54321);

    return completer.future;
  }
}
