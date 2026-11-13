// models/otp_request.dart
class OtpRequest {
  final String phoneNumber;

  OtpRequest(this.phoneNumber);

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
      };
}

