class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? name(String? value, {String label = 'Name'}) {
    final requiredError = required(value, label: label);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return '$label must be at least 2 characters.';
    return null;
  }

  static String? phone(String? value) {
    final requiredError = required(value, label: 'Mobile number');
    if (requiredError != null) return requiredError;
    final cleaned = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 10 || cleaned.length > 13) {
      return 'Enter a valid mobile number.';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().length != 6 || int.tryParse(value.trim()) == null) {
      return 'Enter the 6-digit OTP.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[0-9]{4,10}$').hasMatch(value.trim())) return 'Enter a valid postal code.';
    return null;
  }

  static String? drivingLicense(String? value) {
    // Optional field: never block form submission
    return null;
  }
}
