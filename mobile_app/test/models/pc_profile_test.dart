import 'package:flutter_test/flutter_test.dart';
import 'package:pc_connector/models/pc_profile.dart';

void main() {
  group('PcProfile', () {
    test('constructor sets default port', () {
      final p = PcProfile(
        name: 'PC',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '192.168.1.100',
      );
      expect(p.port, 8420);
      expect(p.isPaired, false);
      expect(p.deviceToken, null);
      expect(p.id, isNotEmpty);
    });

    test('baseUrl', () {
      final p = PcProfile(
        name: 'PC',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '192.168.1.100',
        port: 9000,
      );
      expect(p.baseUrl, 'http://192.168.1.100:9000');
    });

    test('isPaired returns true when token set', () {
      final p = PcProfile(
        name: 'PC',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '192.168.1.100',
        deviceToken: 'tok123',
      );
      expect(p.isPaired, true);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final p = PcProfile(
        id: '42',
        name: 'TestPC',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '10.0.0.1',
        port: 8420,
        deviceToken: 'secret',
        lastSeen: now,
      );
      final json = p.toJson();
      final p2 = PcProfile.fromJson(json);

      expect(p2.id, '42');
      expect(p2.name, 'TestPC');
      expect(p2.macAddress, 'AA-BB-CC-DD-EE-FF');
      expect(p2.ipAddress, '10.0.0.1');
      expect(p2.port, 8420);
      expect(p2.deviceToken, 'secret');
      expect(p2.lastSeen?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromJson with missing optional fields', () {
      final json = {
        'name': 'PC',
        'macAddress': 'AA-BB-CC-DD-EE-FF',
        'ipAddress': '192.168.1.1',
      };
      final p = PcProfile.fromJson(json);
      expect(p.port, 8420);
      expect(p.deviceToken, null);
      expect(p.lastSeen, null);
    });

    test('fromJson falls back to apiKey for token', () {
      final json = {
        'name': 'PC',
        'macAddress': 'AA-BB-CC-DD-EE-FF',
        'ipAddress': '192.168.1.1',
        'apiKey': 'legacy_token',
      };
      final p = PcProfile.fromJson(json);
      expect(p.deviceToken, 'legacy_token');
    });

    test('copyWith', () {
      final p = PcProfile(
        name: 'Old',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '1.2.3.4',
        deviceToken: 'tok',
      );
      final p2 = p.copyWith(name: 'New', ipAddress: '5.6.7.8');
      expect(p2.name, 'New');
      expect(p2.ipAddress, '5.6.7.8');
      expect(p2.deviceToken, 'tok'); // unchanged
      expect(p2.id, p.id); // preserved
    });

    test('copyWith clearToken', () {
      final p = PcProfile(
        name: 'PC',
        macAddress: 'AA-BB-CC-DD-EE-FF',
        ipAddress: '1.2.3.4',
        deviceToken: 'tok',
      );
      final p2 = p.copyWith(clearToken: true);
      expect(p2.deviceToken, null);
    });
  });
}
