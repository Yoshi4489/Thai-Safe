import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/profile/provider/medical_profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);
    final medicalController = ref.watch(medicalProfileControllerProvider);

    if (medicalController.medicalProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = medicalController.medicalProfile!;
    final user = authController.user;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft modern background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "โปรไฟล์ & ข้อมูลแพทย์",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. MODERN CENTERED HEADER
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profile_url != null
                          ? NetworkImage(user!.profile_url)
                          : null,
                      child: user?.profile_url == null
                          ? const Icon(Icons.person_rounded,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${user?.firstName ?? "-"} ${user?.lastName ?? ""}".trim(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.tel ?? "-",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// 2. MEDICAL INFO SECTION
            _buildSectionTitle("ข้อมูลทางการแพทย์"),
            _buildSectionCard(
              children: [
                _buildInfoTile(
                  icon: Icons.bloodtype_rounded,
                  iconColor: Colors.redAccent,
                  label: "กรุ๊ปเลือด",
                  value: profile.blood_type,
                ),
                _buildInfoTile(
                  icon: Icons.health_and_safety_rounded,
                  iconColor: Colors.orange,
                  label: "โรคประจำตัว",
                  value: profile.chronic_diseases,
                ),
                _buildInfoTile(
                  icon: Icons.medication_rounded,
                  iconColor: Colors.teal,
                  label: "ยาประจำ",
                  value: profile.regular_medications,
                ),
                _buildInfoTile(
                  icon: Icons.warning_rounded,
                  iconColor: Colors.amber,
                  label: "อาการแพ้",
                  value: profile.allergies,
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// 3. EMERGENCY CONTACTS SECTION
            _buildSectionTitle("ผู้ติดต่อฉุกเฉิน"),
            if (profile.contact_list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  "ไม่มีข้อมูลผู้ติดต่อฉุกเฉิน",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildSectionCard(
                // Dynamically map through contacts for cleaner code
                children: profile.contact_list.asMap().entries.map((entry) {
                  int index = entry.key;
                  var contact = entry.value;
                  bool isLast = index == profile.contact_list.length - 1;

                  return _buildInfoTile(
                    icon: Icons.contact_emergency_rounded,
                    iconColor: Colors.blueAccent,
                    label: "ผู้ติดต่อฉุกเฉิน ${index + 1} (${contact["name"] ?? "-"})",
                    value: contact["tel"] ?? "-",
                    showDivider: !isLast,
                  );
                }).toList(),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// WIDGET: Modern Section Container
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// WIDGET: Modern Info Tile with Soft Icon Background
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    final displayValue = value.trim().isEmpty ? "-" : value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Soft tinted background for the icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[100],
            indent: 64, // Aligns divider with text, skipping the icon
          ),
      ],
    );
  }

  /// WIDGET: Section Title
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
