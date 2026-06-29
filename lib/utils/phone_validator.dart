/// Phone number normalization + validation utilities.
///
/// Strategy:
/// 1. Normalize: strip spaces, dashes, parens, dots. Keep leading '+'.
/// 2. Validate: E.164-ish — optional '+', then 7–15 digits.
///    (Some countries have 7-digit landlines; we accept 10–15 as "mobile-likely".)
/// 3. Dedupe key: digits-only suffix (last 10 digits) — handles same number
///    saved with/without country code.
class PhoneValidator {
  // Accepts +9198XXXXXXXX, 9198XXXXXXXX, etc. We require 10–15 digits.
  static final RegExp _validE164ish = RegExp(r'^\+?\d{10,15}$');

  /// Strip everything except digits and a single leading '+'.
  static String normalize(String raw) {
    if (raw.isEmpty) return raw;
    final hasPlus = raw.trim().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Returns true for mobile-likely numbers (10–15 digits, optional '+').
  static bool isValidMobile(String normalized) {
    return _validE164ish.hasMatch(normalized);
  }

  /// Dedupe key: last 10 digits. So "+919812345678" and "9812345678"
  /// and "98123 45678" all collapse to the same key.
  static String dedupeKey(String normalized) {
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }
}