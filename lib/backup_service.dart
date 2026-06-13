import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';

class BackupService {
  // --- METODE EKSPOR (BERKAS DAN STRING) ---

  static Future<void> exportJsonFile() async {
    final list = await DatabaseHelper.instance.fetchAccounts();
    final jsonString = jsonEncode(list);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_accounts.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup JSON AccountManager');
  }

  static Future<void> exportRawFile() async {
    final list = await DatabaseHelper.instance.fetchAccounts();
    StringBuffer rawText = StringBuffer();
    for (var account in list) {
      rawText.writeln('=== ACCOUNT START ===');
      account.forEach((key, value) {
        rawText.writeln('$key: $value');
      });
      rawText.writeln('=== ACCOUNT END ===\n');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_accounts.raw');
    await file.writeAsString(rawText.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Backup RAW AccountManager');
  }

  static Future<void> exportCsvFile() async {
    final list = await DatabaseHelper.instance.fetchAccounts();
    StringBuffer csv = StringBuffer();
    csv.writeln('name,identifier,password,a2f,secret_key,created_at,updated_at,custom_icon_path,avatar_path,dob,account_year,tags');
    for (var r in list) {
      csv.writeln('"${r['name']}","${r['identifier']}","${r['password']}",${r['a2f']}(at)"${r['secret_key']}","${r['created_at']}","${r['updated_at']}","${r['custom_icon_path']}","${r['avatar_path']}","${r['dob']}","${r['account_year']}","${r['tags']}"');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_accounts.csv');
    await file.writeAsString(csv.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Backup CSV AccountManager');
  }

  static Future<String> copyEncryptedString() async {
    final list = await DatabaseHelper.instance.fetchAccounts();
    final rawJson = jsonEncode(list);
    List<int> bytes = utf8.encode(rawJson);
    List<int> encBytes = bytes.map((b) => b ^ 77).toList(); // XOR Cipher aman luring
    String base64Enc = base64Encode(encBytes);
    await Clipboard.setData(ClipboardData(text: base64Enc));
    return base64Enc;
  }

  // --- METODE IMPOR (BERKAS DAN STRING) ---

  static Future<bool> importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return false;
      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      if (content.trim().startsWith('[')) {
        return await _parseAndInsertJson(content);
      } else if (content.contains('name,identifier,password')) {
        return await _parseAndInsertCsv(content);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> importFromEncryptedString(String encStr) async {
    try {
      List<int> decodedBytes = base64Decode(encStr.trim());
      List<int> decBytes = decodedBytes.map((b) => b ^ 77).toList();
      String jsonStr = utf8.decode(decBytes);
      return await _parseAndInsertJson(jsonStr);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _parseAndInsertJson(String jsonStr) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      for (var item in decoded) {
        Map<String, dynamic> row = Map<String, dynamic>.from(item);
        row.remove('id');
        await DatabaseHelper.instance.insertAccount(row);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _parseAndInsertCsv(String csvStr) async {
    try {
      final List<String> lines = csvStr.split('\n');
      if (lines.length <= 1) return false;
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;
        List<String> cols = line.split('","').map((e) => e.replaceAll('"', '')).toList();
        if (cols.length < 12) continue;
        Map<String, dynamic> row = {
          'name': cols[0], 'identifier': cols[1], 'password': cols[2],
          'a2f': int.tryParse(cols[3]) ?? 0, 'secret_key': cols[4].isEmpty ? null : cols[4],
          'created_at': cols[5], 'updated_at': cols[6], 'custom_icon_path': cols[7].isEmpty ? null : cols[7],
          'avatar_path': cols[8].isEmpty ? null : cols[8], 'dob': cols[9].isEmpty ? null : cols[9],
          'account_year': cols[10].isEmpty ? null : cols[10], 'tags': cols[11].isEmpty ? null : cols[11],
        };
        await DatabaseHelper.instance.insertAccount(row);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
