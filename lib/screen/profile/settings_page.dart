import 'package:flutter/material.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../auth/change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _mealReminder = true;
  bool _waterReminder = false;
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF9FBFF);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingTile(
            title: "Change Password",
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            title: "Export Monthly Report",
            icon: Icons.file_download_outlined,
            onTap: _exportMonthlyReport, 
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            title: "F&Q",
            icon: Icons.help_outline,
            onTap: () {
              Navigator.pushNamed(context, '/faq');
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: "Daily Meal Reminder",
            icon: Icons.notifications_active_outlined,
            value: _mealReminder,
            onChanged: (val) => setState(() => _mealReminder = val),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: "Water Intake Reminder",
            icon: Icons.local_drink_outlined,
            value: _waterReminder,
            onChanged: (val) => setState(() => _waterReminder = val),
          ),
        ],
      ),
    );
  }

  Future<void> _exportMonthlyReport() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No logged-in user.")),
    );
    return;
  }

  final now = DateTime.now();
  final firstDay = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);

  try {
    final rows = await supabase
        .from("calories_log")
        .select()
        .eq("user_id", user.id)
        .gte("log_date", firstDay.toIso8601String())
        .lte("log_date", lastDay.toIso8601String());

    // Sort rows by log_date in ascending order
    rows.sort((a, b) {
      final dateA = DateTime.parse(a['log_date']);
      final dateB = DateTime.parse(b['log_date']);
      return dateA.compareTo(dateB);
    });

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs found for this month.")),
      );
      return;
    }

  final excel = Excel.createExcel();
  excel.rename('Sheet1', 'Monthly Report');
  final sheet = excel['Monthly Report'];
  excel.setDefaultSheet('Monthly Report');

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Meal Type'),
      TextCellValue('Name'),
      TextCellValue('Calories'),
      TextCellValue('Carbs'),
      TextCellValue('Protein'),
      TextCellValue('Fat'),
    ]);

    for (var row in rows) {
      sheet.appendRow([
        TextCellValue(row['log_date'] != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(row['log_date']))
            : ''),
        TextCellValue(row['meal_type'] ?? ''),
        TextCellValue(row['name'] ?? ''),
        DoubleCellValue(row['calories']?.toDouble() ?? 0),
        DoubleCellValue(row['carbs']?.toDouble() ?? 0),
        DoubleCellValue(row['protein']?.toDouble() ?? 0),
        DoubleCellValue(row['fat']?.toDouble() ?? 0),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Failed to encode Excel.");

    final tempDir = await getTemporaryDirectory();
    final fileName = "monthly_report_${now.year}_${now.month}.xlsx";
    final tempPath = "${tempDir.path}/$fileName";

    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(fileBytes);
    await OpenFilex.open(tempPath);
    
    final params = SaveFileDialogParams(
      sourceFilePath: tempPath,
      fileName: fileName,
    );

    final savedPath = await FlutterFileDialog.saveFile(params: params);

    if (savedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download canceled")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved to Downloads: $savedPath")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error exporting report: $e")),
    );
  }
}

  Widget _buildSettingTile({required String title, required IconData icon, VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        secondary: Icon(icon, color: const Color(0xFF6C63FF)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6C63FF),
      ),
    );
  }
}
