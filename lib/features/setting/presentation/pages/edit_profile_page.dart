import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thai_safe/core/services/cloudinary_provider.dart';
import 'package:thai_safe/core/validators/phone_validator.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/profile/data/medical_profile_model.dart';
import 'package:thai_safe/features/profile/provider/medical_profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  File? _imageFile;
  String? _selectedBloodType;

  final TextEditingController chronic_diseases_controller =
      TextEditingController();
  final TextEditingController regular_medications_controller =
      TextEditingController();
  final TextEditingController allergies_controller = TextEditingController();
  final TextEditingController contact_name_controller_one =
      TextEditingController();
  final TextEditingController contact_tel_controller_one =
      TextEditingController();
  final TextEditingController contact_name_controller_two =
      TextEditingController();
  final TextEditingController contact_tel_controller_two =
      TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  "เลือกจากแกลเลอรี",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.teal,
                  ),
                ),
                title: const Text(
                  "ถ่ายภาพ",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final authController = ref.read(authControllerProvider);
    if (authController.user != null) {
      Future.microtask(
        () => ref
            .read(medicalProfileControllerProvider.notifier)
            .createNewMedicalProfile(authController.user!.id),
      );
    }
  }

  @override
  void dispose() {
    chronic_diseases_controller.dispose();
    regular_medications_controller.dispose();
    allergies_controller.dispose();
    contact_name_controller_one.dispose();
    contact_tel_controller_one.dispose();
    contact_name_controller_two.dispose();
    contact_tel_controller_two.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloudProvider = ref.watch(cloudinaryServiceProvider);
    final authController = ref.watch(authControllerProvider);
    final medicalController = ref.watch(medicalProfileControllerProvider);

    ref.listen<MedicalProfileState>(medicalProfileControllerProvider, (
      previous,
      next,
    ) {
      final profile = next.medicalProfile;
      if (profile != null && previous?.medicalProfile != profile) {
        final validBloodTypes = ["A", "B", "AB", "O"];
        if (validBloodTypes.contains(profile.blood_type)) {
          setState(() {
            _selectedBloodType = profile.blood_type;
          });
        }

        chronic_diseases_controller.text = profile.chronic_diseases;
        regular_medications_controller.text = profile.regular_medications;
        allergies_controller.text = profile.allergies;

        if (profile.contact_list.isNotEmpty) {
          contact_name_controller_one.text =
              profile.contact_list[0]['name'] ?? '';
          contact_tel_controller_one.text =
              profile.contact_list[0]['tel'] ?? '';
        }
        if (profile.contact_list.length > 1) {
          contact_name_controller_two.text =
              profile.contact_list[1]['name'] ?? '';
          contact_tel_controller_two.text =
              profile.contact_list[1]['tel'] ?? '';
        }
      }
    });

    if (medicalController.error != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Error",
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "เกิดข้อผิดพลาดในการโหลดข้อมูล:\n${medicalController.error}",
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (medicalController.medicalProfile == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "แก้ไขโปรไฟล์",
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
            /// 1. CENTERED AVATAR (Matches ProfilePage)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      _showImageSourceActionSheet();
                      if (_imageFile != null) {
                        final res = await cloudProvider.uploadImage(
                          _imageFile!,
                        );
                        if (res.isNotEmpty && mounted) {
                          ref
                              .read(authControllerProvider.notifier)
                              .updateProfile(profile_url: res);
                        }
                      }
                    },
                    child: Stack(
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
                            backgroundImage:
                                authController.user?.profile_url != null
                                ? NetworkImage(authController.user!.profile_url)
                                : null,
                            child: authController.user?.profile_url == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${authController.user?.firstName ?? "-"} ${authController.user?.lastName ?? ""}"
                        .trim(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PhoneValidator.convertToNormalPhone(
                      authController.user?.tel ?? "-",
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// 2. INFO BANNER
            _buildInfoBanner(),

            const SizedBox(height: 32),

            /// 3. MEDICAL INFO FORM
            _sectionTitle("ข้อมูลทางการแพทย์"),
            _buildSectionCard(
              children: [
                _buildBloodTypeDropdown(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                ),
                _buildModernTextField(
                  controller: chronic_diseases_controller,
                  icon: Icons.health_and_safety_rounded,
                  iconColor: Colors.orange,
                  label: "โรคประจำตัว",
                  hint: "เช่น เบาหวาน, ความดัน, หอบหืด",
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                ),
                _buildModernTextField(
                  controller: regular_medications_controller,
                  icon: Icons.medication_rounded,
                  iconColor: Colors.teal,
                  label: "ยาประจำ",
                  hint: "เช่น Insulin, Ventolin",
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                ),
                _buildModernTextField(
                  controller: allergies_controller,
                  icon: Icons.warning_rounded,
                  iconColor: Colors.amber,
                  label: "อาการแพ้ยา / แพ้อาหาร",
                  hint: "เช่น แพ้เพนนิซิลลิน, อาหารทะเล",
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// 4. EMERGENCY CONTACTS FORM
            _sectionTitle("ผู้ติดต่อฉุกเฉิน"),
            _buildSectionCard(
              children: [
                _buildModernTextField(
                  controller: contact_name_controller_one,
                  icon: Icons.person_rounded,
                  iconColor: Colors.blueAccent,
                  label: "ชื่อผู้ติดต่อ 1",
                  hint: "ชื่อ – นามสกุล",
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                ),
                _buildModernTextField(
                  controller: contact_tel_controller_one,
                  icon: Icons.phone_rounded,
                  iconColor: Colors.blueAccent,
                  label: "เบอร์โทรศัพท์ 1",
                  hint: "0xx-xxx-xxxx",
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionCard(
              children: [
                _buildModernTextField(
                  controller: contact_name_controller_two,
                  icon: Icons.person_outline_rounded,
                  iconColor: Colors.indigo,
                  label: "ชื่อผู้ติดต่อ 2 (ถ้ามี)",
                  hint: "ชื่อ – นามสกุล",
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                ),
                _buildModernTextField(
                  controller: contact_tel_controller_two,
                  icon: Icons.phone_outlined,
                  iconColor: Colors.indigo,
                  label: "เบอร์โทรศัพท์ 2",
                  hint: "0xx-xxx-xxxx",
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const SizedBox(height: 40),

            /// 5. SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: medicalController.isLoading
                    ? null
                    : () async {
                        if (authController.user == null) return;

                        List<Map<String, dynamic>> contacts = [];

                        if (!PhoneValidator.isValidThaiPhone(
                              contact_tel_controller_one.text,
                            ) &&
                            contact_tel_controller_one.text.isNotEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'เบอร์โทรศัพท์ผู้ติดต่อ 1 ไม่ถูกต้อง',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }

                        if (!PhoneValidator.isValidThaiPhone(
                              contact_tel_controller_two.text,
                            ) &&
                            contact_tel_controller_two.text.isNotEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'เบอร์โทรศัพท์ผู้ติดต่อ 2 ไม่ถูกต้อง',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }

                        if (contact_name_controller_one.text.isNotEmpty ||
                            contact_tel_controller_one.text.isNotEmpty) {
                          contacts.add({
                            "name": contact_name_controller_one.text.trim(),
                            "tel": contact_tel_controller_one.text.trim(),
                          });
                        }
                        if (contact_name_controller_two.text.isNotEmpty ||
                            contact_tel_controller_two.text.isNotEmpty) {
                          contacts.add({
                            "name": contact_name_controller_two.text.trim(),
                            "tel": contact_tel_controller_two.text.trim(),
                          });
                        }

                        final profile = MedicalProfileModel(
                          user_id: authController.user!.id,
                          chronic_diseases: chronic_diseases_controller.text
                              .trim(),
                          regular_medications: regular_medications_controller
                              .text
                              .trim(),
                          allergies: allergies_controller.text.trim(),
                          blood_type: _selectedBloodType ?? "",
                          contact_list: contacts,
                          updated_at: DateTime.now(),
                        );
                        try {
                          await ref
                              .read(medicalProfileControllerProvider.notifier)
                              .saveMedicalProfile(profile);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('บันทึกข้อมูลสำเร็จ!'),
                                backgroundColor: Colors.green[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            // Optionally pop the page after saving
                            // Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: $e'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: medicalController.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "บันทึกข้อมูล",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
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
      child: Column(children: children),
    );
  }

  /// WIDGET: Info Banner Header
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blueAccent.shade700,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "ข้อมูลนี้จะถูกใช้ในกรณีฉุกเฉิน\nเพื่อช่วยให้เจ้าหน้าที่ช่วยเหลือได้เร็วขึ้น",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueAccent.shade700,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WIDGET: Blood Type Dropdown Tile
  Widget _buildBloodTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bloodtype_rounded,
              size: 24,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "กรุ๊ปเลือด",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text("เลือก"),
              value: _selectedBloodType,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.grey,
              ),
              borderRadius: BorderRadius.circular(12),
              items: ["A", "B", "AB", "O"]
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        g,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodType = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// WIDGET: Modern Text Field Tile
  Widget _buildModernTextField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: null,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 2,
                  bottom: 2,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WIDGET: Section Title
  Widget _sectionTitle(String text) {
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
