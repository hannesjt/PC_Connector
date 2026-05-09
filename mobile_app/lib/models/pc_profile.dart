class PcProfile {
  final String id;
  final String name;
  final String macAddress;
  final String ipAddress;
  final int port;
  final String? deviceToken;
  final DateTime? lastSeen;

  PcProfile({
    String? id,
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    this.port = 8420,
    this.deviceToken,
    this.lastSeen,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get isPaired => deviceToken != null;

  String get baseUrl => 'http://$ipAddress:$port';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'macAddress': macAddress,
        'ipAddress': ipAddress,
        'port': port,
        'deviceToken': deviceToken,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
      };

  factory PcProfile.fromJson(Map<String, dynamic> json) => PcProfile(
        id: json['id'] as String?,
        name: json['name'] as String,
        macAddress: json['macAddress'] as String,
        ipAddress: json['ipAddress'] as String,
        port: json['port'] as int? ?? 8420,
        deviceToken: json['deviceToken'] as String? ?? json['apiKey'] as String?,
        lastSeen: json['lastSeen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
            : null,
      );

  PcProfile copyWith({
    String? name,
    String? macAddress,
    String? ipAddress,
    int? port,
    String? deviceToken,
    bool clearToken = false,
    DateTime? lastSeen,
  }) =>
      PcProfile(
        id: id,
        name: name ?? this.name,
        macAddress: macAddress ?? this.macAddress,
        ipAddress: ipAddress ?? this.ipAddress,
        port: port ?? this.port,
        deviceToken: clearToken ? null : (deviceToken ?? this.deviceToken),
        lastSeen: lastSeen ?? this.lastSeen,
      );
}
