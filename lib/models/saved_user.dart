class SavedUser {
  final int? id;
  final String serverUrl;
  final String username;
  final String passwordHash;
  final String salt;
  final bool rememberPassword;
  final DateTime? lastLogin;
  final DateTime createdAt;

  SavedUser({
    this.id,
    required this.serverUrl,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.rememberPassword = false,
    this.lastLogin,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_url': serverUrl,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'remember_password': rememberPassword ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedUser.fromMap(Map<String, dynamic> map) {
    return SavedUser(
      id: map['id'],
      serverUrl: map['server_url'],
      username: map['username'],
      passwordHash: map['password_hash'],
      salt: map['salt'],
      rememberPassword: map['remember_password'] == 1,
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  SavedUser copyWith({
    int? id,
    String? serverUrl,
    String? username,
    String? passwordHash,
    String? salt,
    bool? rememberPassword,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return SavedUser(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SavedUser{id: $id, serverUrl: $serverUrl, username: $username, rememberPassword: $rememberPassword, lastLogin: $lastLogin}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedUser &&
        other.serverUrl == serverUrl &&
        other.username == username;
  }

  @override
  int get hashCode {
    return serverUrl.hashCode ^ username.hashCode;
  }
}