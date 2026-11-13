class OtpResponse {
  final String requestId;
  final String otpSentAt;

  OtpResponse({required this.requestId, required this.otpSentAt});

  factory OtpResponse.fromJson(Map<String, dynamic> json) => OtpResponse(
        requestId: json['requestId'] as String,
        otpSentAt: json['otpSentAt'] as String,
      );
}

