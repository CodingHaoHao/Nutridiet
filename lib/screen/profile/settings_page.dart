import 'package:flutter/material.dart';
import '../auth/change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _mealReminder = true;
  bool _waterReminder = false;

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
                      builder: (_) => const ChangePasswordPage()),
                );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            title: "Export Monthly Report",
            icon: Icons.file_download_outlined,
            onTap: () {
              Navigator.pushNamed(context, '/exportReport');
            },
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
