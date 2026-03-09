import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/rescue_approval/service/rescue_approval_service.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ดึงข้อมูล User ปัจจุบัน
    final currentUser = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("App"),
          _settingsTile(
            icon: Icons.notifications,
            title: "Notifications",
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.privacy_tip,
            title: "Privacy & Security",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          
          // ✅ ส่วนของ Rescue Request (จะแสดงเมื่อ Login แล้ว และยังไม่ได้เป็น rescue/admin)
          if (currentUser != null && currentUser.role != 'rescue' && currentUser.role != 'admin' && currentUser.role != 'officer') ...[
            _sectionTitle("Rescue Team"),
            _requestRescueTile(context, currentUser),
            const SizedBox(height: 24),
          ],

          _sectionTitle("Danger zone"),
          _logoutTile(context, ref),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _settingsTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ปุ่มขอเป็น Rescue
  Widget _requestRescueTile(BuildContext context, dynamic currentUser) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.medical_services, color: Colors.blue.shade700),
        title: Text("Request To Be Rescue", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          try {
            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            
            final name = '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim();
            await RescueApprovalService().createRescueRequest(
              userId: currentUser.id,
              name: name.isEmpty ? 'ไม่ระบุชื่อ' : name,
              phone: currentUser.tel ?? '',
            );

            if (context.mounted) {
              Navigator.pop(context); // ปิดโหลด
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ส่งคำขอสำเร็จ! กรุณารอ Admin อนุมัติ"), backgroundColor: Colors.green));
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // ปิดโหลด
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  Widget _logoutTile(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.logout, color: Colors.red.shade700),
        title: Text("Log out", style: TextStyle(color: Colors.red.shade700)),
        onTap: () => _confirmLogout(context, ref),
      ),
    );
  }

  // ---------- Logic ----------

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }
}
