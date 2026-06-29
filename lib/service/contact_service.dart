import 'package:contact_app/model/contact_entry.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../utils/phone_validator.dart';

/// Fetches device contacts and filters to MOBILE numbers only.
///
/// Uses flutter_contacts v2 API (`getAll` + `ContactProperty` set).
///
/// Filtering strategy (in order of preference):
/// 1. Prefer phones explicitly labeled `mobile` (or `iPhone` / `main` as fallback).
/// 2. If a contact has NO mobile-labeled phone, we still try its other phones
///    but only keep ones that pass numeric validation.
/// 3. Validate format (10–15 digits, optional '+').
/// 4. Dedupe globally across the export by last-10-digit key.
class ContactService {
  /// Returns sorted, deduped list of [ContactEntry].
  /// Caller is responsible for permission — call after permission is granted.
  ///
  /// [onProgress] receives values 0.0–1.0 for UI progress feedback.
  static Future<List<ContactEntry>> fetchMobileContacts({
    void Function(double progress)? onProgress,
  }) async {
    // v2 API: pass the exact ContactProperty set we need. Skipping photo,
    // thumbnail, accounts, groups, etc. keeps the fetch fast and lean.
    final contacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.phone,
      },
    );

    // v2 doesn't expose a `sorted` flag — sort manually by display name.
    contacts.sort(
      (a, b) =>
          (a.displayName ?? '').toLowerCase().compareTo((b.displayName ?? '').toLowerCase()),
    );

    final seenKeys = <String>{};
    final entries = <ContactEntry>[];
    final total = contacts.length;

    for (var i = 0; i < total; i++) {
      final c = contacts[i];

      if (c.phones.isEmpty) continue;

      // Prefer mobile-labeled phones; fallback to all phones if none labeled.
      final mobilePhones = c.phones.where(_isMobileLabel).toList();
      final candidates = mobilePhones.isNotEmpty ? mobilePhones : c.phones;

      for (final phone in candidates) {
        final normalized = PhoneValidator.normalize(phone.number);
        if (!PhoneValidator.isValidMobile(normalized)) continue;

        final key = PhoneValidator.dedupeKey(normalized);
        if (seenKeys.contains(key)) continue;
        seenKeys.add(key);

        final raw = c.displayName?.trim() ?? '';
        final name = raw.isEmpty ? '(Unnamed)' : raw;

        entries.add(ContactEntry(name: name, mobileNumber: normalized));
      }

      // Throttle progress updates — every 25 contacts is plenty for UI.
      if (onProgress != null && (i % 25 == 0 || i == total - 1)) {
        onProgress((i + 1) / total);
      }
    }

    return entries;
  }

  static bool _isMobileLabel(Phone phone) {
    return phone.label == PhoneLabel.mobile ||
        phone.label == PhoneLabel.iPhone ||
        phone.label == PhoneLabel.main;
  }
}