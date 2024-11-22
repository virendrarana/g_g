class Validators {
  static String? validateEmail(String value) {
    final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (value.isEmpty) {
      return 'Email can\'t be empty';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Enter a correct email';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password can\'t be empty';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateName(String value) {
    if (value.isEmpty) {
      return 'Name can\'t be empty';
    }
    return null;
  }

  static String? validatePhoneNumber(String value) {
    final RegExp phoneRegExp = RegExp(
      r'^[0-9]{10}$',
    );
    if (value.isEmpty) {
      return 'Phone number can\'t be empty';
    } else if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateAddress(String value) {
    if (value.isEmpty) {
      return 'Address can\'t be empty';
    }
    return null;
  }
}
