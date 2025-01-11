// lib/utils/input_utils.dart

class InputUtils {
  // Validate that the input is not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $fieldName';
    }
    return null;
  }

  // Validate that the input is a valid number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $fieldName';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number for $fieldName';
    }
    return null;
  }

  // Sanitize string inputs by escaping harmful characters
  static String sanitizeString(String input) {
    // Basic sanitization: remove leading/trailing whitespace and escape quotes
    return input.trim().replaceAll("'", "\\'").replaceAll('"', '\\"');
  }

  // Additional sanitization methods can be added here
}