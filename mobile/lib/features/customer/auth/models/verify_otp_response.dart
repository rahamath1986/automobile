class VerifyOtpResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  VerifyOtpResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) => VerifyOtpResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

