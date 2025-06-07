class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final List<String> groups;
  final double totalBalance;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.groups = const [],
    this.totalBalance = 0.0,
  });

  // Factory constructor to build from Firebase user + extra data
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      groups: List<String>.from(data['groups'] ?? []),
      totalBalance: (data['totalBalance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'groups': groups,
      'totalBalance': totalBalance,
    };
  }
}
