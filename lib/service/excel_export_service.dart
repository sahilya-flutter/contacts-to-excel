import 'dart:io';

import 'package:contact_app/model/contact_entry.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Builds a clean, formatted .xlsx and exposes save / share helpers.
///
/// Sheet layout:
///   Col A: Sr. No.
///   Col B: Name
///   Col C: Mobile Number   (forced as text so leading '+' / '0' aren't stripped)
class ExcelExportService {
  /// Builds the Excel file in memory and writes it to the app's temp directory.
  /// Returns the absolute path of the written file.
  static Future<String> exportToFile(
    List<ContactEntry> contacts, {
    String fileNamePrefix = 'contacts',
  }) async {
    final excel = Excel.createExcel();

    // Excel package creates a default 'Sheet1' — rename it cleanly.
    const sheetName = 'Contacts';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    // --- Header row (styled) ---
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E78'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headers = ['Sr. No.', 'Name', 'Mobile Number'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // --- Data rows ---
    final textStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    for (var i = 0; i < contacts.length; i++) {
      final row = i + 1;
      final entry = contacts[i];

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = IntCellValue(i + 1)
        ..cellStyle = textStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue(entry.name)
        ..cellStyle = textStyle;

      // Force as text — preserves '+' prefix and any leading zeros.
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = TextCellValue(entry.mobileNumber)
        ..cellStyle = textStyle;
    }

    // --- Column widths (auto-fit to content) ---
    sheet.setColumnAutoFit(0);
    sheet.setColumnAutoFit(1);
    sheet.setColumnAutoFit(2);

    // --- Encode + write ---
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file.');
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filePath = '${dir.path}/${fileNamePrefix}_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Opens the native share sheet so the user can save to Drive, send via
  /// WhatsApp/email, etc. This is the most reliable cross-Android-version
  /// way to "save" without dealing with Scoped Storage / MediaStore directly.
  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? 'Contacts Export',
      text: 'Exported contacts',
    );
  }
}