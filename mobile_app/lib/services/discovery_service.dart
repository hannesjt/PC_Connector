import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DiscoveredAgent {
  final String name;
  final String ip;
  final int port;
  final String mac;

  DiscoveredAgent({
    required this.name,
    required this.ip,
    required this.port,
    required this.mac,
  });
}

class DiscoveryService {
  static const int discoveryPort = 8421;
  static const String magic = 'PCCONNECTOR_DISCOVER';

  /// Broadcast a UDP discovery packet and collect responses.
  static Future<List<DiscoveredAgent>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final agents = <DiscoveredAgent>[];
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    socket.send(
      utf8.encode(magic),
      InternetAddress('255.255.255.255'),
      discoveryPort,
    );

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      socket.close();
    });

    socket.listen(
      (event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null) {
            try {
              final data = jsonDecode(utf8.decode(dg.data));
              agents.add(DiscoveredAgent(
                name: data['name'] as String,
                ip: dg.address.address,
                port: data['port'] as int,
                mac: data['mac'] as String,
              ));
            } catch (_) {}
          }
        }
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    return agents;
  }
}
