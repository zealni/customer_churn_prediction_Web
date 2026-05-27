library;

/// ── Form Validators ────────────────────────────────────────────────────────

class Validators {
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? number(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  static String? positiveNumber(String? value,
      [String fieldName = 'This field']) {
    final numError = number(value, fieldName);
    if (numError != null) return numError;
    if (double.parse(value!) < 0) {
      return '$fieldName must be positive';
    }
    return null;
  }

  static String? tenure(String? value) {
    final numError = number(value, 'Tenure');
    if (numError != null) return numError;
    final tenure = int.tryParse(value!);
    if (tenure == null || tenure < 0 || tenure > 120) {
      return 'Tenure must be between 0 and 120 months';
    }
    return null;
  }

  static String? monthlyCharges(String? value) {
    final numError = positiveNumber(value, 'Monthly Charges');
    if (numError != null) return numError;
    final charges = double.parse(value!);
    if (charges > 500) {
      return 'Monthly charges seem too high (max: \$500)';
    }
    return null;
  }

  static String? totalCharges(String? value) {
    return positiveNumber(value, 'Total Charges');
  }
}
