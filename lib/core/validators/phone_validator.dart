class PhoneValidator {
  static bool isValidThaiPhone(String phone) {
    return RegExp(r'^(\+66|0)\d{9}$').hasMatch(phone);
  }

  static String normalizeThaiPhone(String phone) {
    if (phone.startsWith('0')) {
      return '+66${phone.substring(1)}';
    }
    return phone;
  }

  static String convertToNormalPhone(String phone) {
    if (phone.startsWith("+66")) {
      return '0${phone.substring(3)}';
    }
    if (phone.startsWith("+")) {
      return '0${phone.substring(1)}';
    }

    return phone;
  }
}
