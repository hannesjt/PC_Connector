import 'dart:io';
import 'dart:typed_data';

class WolService {
  /// Sends a Wake-on-LAN magic packet to the given MAC address.
  /// [macAddress] format: "AA:BB:CC:DD:EE:FF" or "AA-BB-CC-DD-EE-FF"
  /// [broadcastAddress] defaults to 255.255.255.255
  /// [port] defaults to 9
  Future<void> sendWol(
    String macAddress, {
    String broadcastAddress = '255.255.255.255',
    int port = 9,
  }) async {
    final macBytes = _parseMac(macAddress);
    final packet = _buildMagicPacket(macBytes);

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(
      packet,
      InternetAddress(broadcastAddress),
      port,
    );
    socket.close();
  }

  Uint8List _parseMac(String mac) {
    final parts = mac.replaceAll('-', ':').split(':');
    if (parts.length != 6) {
      throw ArgumentError('Invalid MAC address: $mac');
    }
    return Uint8List.fromList(
      parts.map((p) => int.parse(p, radix: 16)).toList(),
    );
  }

  Uint8List _buildMagicPacket(Uint8List macBytes) {
    // 6 bytes of 0xFF followed by 16 repetitions of the MAC address
    final packet = Uint8List(6 + 16 * 6);
    for (var i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    for (var i = 0; i < 16; i++) {
      final offset = 6 + i * 6;
      for (var j = 0; j < 6; j++) {
        packet[offset + j] = macBytes[j];
      }
    }
    return packet;
  }
}
