import 'package:permission_handler/permission_handler.dart';

/// Centralized contact permission handling.
///
/// Returns a [ContactPermissionResult] so the UI layer can react to each state
/// distinctly (granted / denied once / permanently denied / restricted).
enum ContactPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class PermissionService {
  /// Requests READ_CONTACTS. If already granted, returns immediately.
  /// If permanently denied, the caller should prompt the user to open Settings.
  static Future<ContactPermissionResult> requestContactsPermission() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) return ContactPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return ContactPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) return ContactPermissionResult.restricted;

    final result = await Permission.contacts.request();

    if (result.isGranted) return ContactPermissionResult.granted;
    if (result.isPermanentlyDenied) {
      return ContactPermissionResult.permanentlyDenied;
    }
    if (result.isRestricted) return ContactPermissionResult.restricted;
    return ContactPermissionResult.denied;
  }

  /// Opens the system app settings page so the user can re-grant permission.
  static Future<bool> openSettings() => openAppSettings();
}