class TwoFactorRequest {
  final String userId;
  final String code;

  TwoFactorRequest({
    required this.userId,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'code': code,
    };
  }
}
