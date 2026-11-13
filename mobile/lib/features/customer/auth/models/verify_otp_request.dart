class VerifyOtpRequest {
  final String requestId;
  final String otp;

  VerifyOtpRequest({required this.requestId, required this.otp});

  Map<String, dynamic> toJson() => {'requestId': requestId, 'otp': otp};
}

