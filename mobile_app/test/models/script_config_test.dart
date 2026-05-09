import 'package:flutter_test/flutter_test.dart';
import 'package:pc_connector/models/script_config.dart';

void main() {
  group('ScriptConfig', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'shutdown',
        'name': 'Shutdown',
        'icon': 'power_off',
        'confirm': true,
        'group': 'System',
        'order': 3,
        'is_global': true,
      };
      final s = ScriptConfig.fromJson(json);
      expect(s.id, 'shutdown');
      expect(s.name, 'Shutdown');
      expect(s.icon, 'power_off');
      expect(s.confirm, true);
      expect(s.group, 'System');
      expect(s.order, 3);
      expect(s.isGlobal, true);
    });

    test('fromJson with defaults', () {
      final json = {'id': 'x', 'name': 'X'};
      final s = ScriptConfig.fromJson(json);
      expect(s.icon, 'play_arrow');
      expect(s.confirm, false);
      expect(s.group, '');
      expect(s.order, 0);
      expect(s.isGlobal, false);
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'icon': null,
        'confirm': null,
        'group': null,
        'order': null,
        'is_global': null,
      };
      final s = ScriptConfig.fromJson(json);
      expect(s.icon, 'play_arrow');
      expect(s.confirm, false);
      expect(s.group, '');
      expect(s.order, 0);
      expect(s.isGlobal, false);
    });
  });

  group('ScriptResult', () {
    test('fromJson', () {
      final json = {
        'script_id': 'echo',
        'success': true,
        'exit_code': 0,
        'stdout': 'hello',
        'stderr': '',
      };
      final r = ScriptResult.fromJson(json);
      expect(r.scriptId, 'echo');
      expect(r.success, true);
      expect(r.exitCode, 0);
      expect(r.stdout, 'hello');
      expect(r.stderr, '');
    });

    test('fromJson with null stdout/stderr defaults', () {
      final json = {
        'script_id': 'x',
        'success': false,
        'exit_code': 1,
      };
      final r = ScriptResult.fromJson(json);
      expect(r.stdout, '');
      expect(r.stderr, '');
    });
  });

  group('ChainStep', () {
    test('fromJson', () {
      final json = {'script_id': 's1', 'delay_seconds': 5};
      final step = ChainStep.fromJson(json);
      expect(step.scriptId, 's1');
      expect(step.delaySeconds, 5);
    });

    test('fromJson with default delay', () {
      final json = {'script_id': 's1'};
      final step = ChainStep.fromJson(json);
      expect(step.delaySeconds, 0);
    });

    test('toJson', () {
      const step = ChainStep(scriptId: 's1', delaySeconds: 3);
      final json = step.toJson();
      expect(json['script_id'], 's1');
      expect(json['delay_seconds'], 3);
    });
  });

  group('ScriptChain', () {
    test('fromJson', () {
      final json = {
        'id': 'ch1',
        'name': 'Morning',
        'steps': [
          {'script_id': 's1', 'delay_seconds': 0},
          {'script_id': 's2', 'delay_seconds': 10},
        ],
        'order': 2,
      };
      final chain = ScriptChain.fromJson(json);
      expect(chain.id, 'ch1');
      expect(chain.name, 'Morning');
      expect(chain.steps.length, 2);
      expect(chain.steps[1].delaySeconds, 10);
      expect(chain.order, 2);
    });

    test('fromJson with default order', () {
      final json = {
        'id': 'ch1',
        'name': 'C',
        'steps': [],
      };
      final chain = ScriptChain.fromJson(json);
      expect(chain.order, 0);
    });
  });
}
