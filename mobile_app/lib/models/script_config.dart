class ScriptConfig {
  final String id;
  final String name;
  final String icon;
  final bool confirm;
  final String group;
  final int order;
  final bool isGlobal;

  const ScriptConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.confirm,
    this.group = '',
    this.order = 0,
    this.isGlobal = false,
  });

  factory ScriptConfig.fromJson(Map<String, dynamic> json) => ScriptConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'play_arrow',
        confirm: json['confirm'] as bool? ?? false,
        group: json['group'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        isGlobal: json['is_global'] as bool? ?? false,
      );
}

class ScriptResult {
  final String scriptId;
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;

  const ScriptResult({
    required this.scriptId,
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  factory ScriptResult.fromJson(Map<String, dynamic> json) => ScriptResult(
        scriptId: json['script_id'] as String,
        success: json['success'] as bool,
        exitCode: json['exit_code'] as int,
        stdout: json['stdout'] as String? ?? '',
        stderr: json['stderr'] as String? ?? '',
      );
}

class ChainStep {
  final String scriptId;
  final int delaySeconds;

  const ChainStep({required this.scriptId, this.delaySeconds = 0});

  factory ChainStep.fromJson(Map<String, dynamic> json) => ChainStep(
        scriptId: json['script_id'] as String,
        delaySeconds: json['delay_seconds'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'script_id': scriptId,
        'delay_seconds': delaySeconds,
      };
}

class ScriptChain {
  final String id;
  final String name;
  final List<ChainStep> steps;
  final int order;

  const ScriptChain({
    required this.id,
    required this.name,
    required this.steps,
    this.order = 0,
  });

  factory ScriptChain.fromJson(Map<String, dynamic> json) => ScriptChain(
        id: json['id'] as String,
        name: json['name'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => ChainStep.fromJson(e))
            .toList(),
        order: json['order'] as int? ?? 0,
      );
}
