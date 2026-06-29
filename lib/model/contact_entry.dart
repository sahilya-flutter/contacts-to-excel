/// Lightweight model for an exported contact row.
/// We deliberately keep ONLY name + mobile number (no email/address) per requirements.
class ContactEntry {
  final String name;
  final String mobileNumber;

  const ContactEntry({
    required this.name,
    required this.mobileNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactEntry &&
          other.name == name &&
          other.mobileNumber == mobileNumber;

  @override
  int get hashCode => Object.hash(name, mobileNumber);
}