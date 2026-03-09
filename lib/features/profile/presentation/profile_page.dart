import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thai_safe/core/services/cloudinary_provider.dart';
import 'package:thai_safe/core/validators/phone_validator.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/profile/data/medical_profile_model.dart';
import 'package:thai_safe/features/profile/provider/medical_profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("เลือกจาก Gallery"),
              onTap: () {
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("ถ่ายภาพ"),
              onTap: () {
                _pickImage(ImageSource.camera);
              },
            ),
          ],
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

    // Add this to show stream errors instead of infinite loading
    if (medicalController.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Error",
          style: TextStyle(fontSize: 14),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "เกิดข้อผิดพลาดในการโหลดข้อมูล:\n${medicalController.error}",
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (medicalController.medicalProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "โปรไฟล์ & ข้อมูลแพทย์",
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("ข้อมูลส่วนตัว"),

            const SizedBox(height: 24),

            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    _showImageSourceActionSheet();
                    if (_imageFile != null) {
                      final res = await cloudProvider.uploadImage(_imageFile!);
                      if (res.isNotEmpty && mounted) {
                        ref
                            .read(authControllerProvider.notifier)
                            .updateProfile(profile_url: res);
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            authController.user?.profile_url != null
                            ? NetworkImage(authController.user!.profile_url)
                            : null,
                        child: authController.user?.profile_url == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${authController.user?.firstName ?? "ชื่อจริง"} ${authController.user?.lastName ?? "นามสกุล"}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        PhoneValidator.convertToNormalPhone(
                          authController.user?.tel ?? "",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _profileHeader(),

            const SizedBox(height: 24),

            _sectionTitle("ข้อมูลทางการแพทย์"),

            _bloodTypeCard(),

            const SizedBox(height: 16),

            _medicalTextField(
              controller: chronic_diseases_controller,
              icon: Icons.health_and_safety_outlined,
              label: "โรคประจำตัว",
              hint: "เช่น เบาหวาน, ความดัน, หอบหืด",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              controller: regular_medications_controller,
              icon: Icons.medication_outlined,
              label: "ยาประจำ",
              hint: "เช่น Insulin, Ventolin",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.warning_amber_rounded,
              controller: allergies_controller,
              label: "อาการแพ้ยา / แพ้อาหาร",
              hint: "เช่น แพ้เพนนิซิลลิน, อาหารทะเล",
            ),

            const SizedBox(height: 24),

            _sectionTitle("ผู้ติดต่อฉุกเฉิน"),

            _medicalTextField(
              icon: Icons.person_outline,
              controller: contact_name_controller_one,
              label: "ชื่อผู้ติดต่อ",
              hint: "ชื่อ – นามสกุล",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.phone_outlined,
              controller: contact_tel_controller_one,
              keyboardType: TextInputType.phone,
              label: "เบอร์โทรศัพท์",
              hint: "0xx-xxx-xxxx",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.person_outline,
              controller: contact_name_controller_two,
              label: "ชื่อผู้ติดต่อ",
              hint: "ชื่อ – นามสกุล",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.phone_outlined,
              controller: contact_tel_controller_two,
              keyboardType: TextInputType.phone,
              label: "เบอร์โทรศัพท์",
              hint: "0xx-xxx-xxxx",
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
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
                                  'เบอร์โทรศัพท์ผู้ติดต่อฉุกเฉิน 1 ไม่ถูกต้อง',
                                ),
                                backgroundColor: Colors.red,
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
                                  'เบอร์โทรศัพท์ผู้ติดต่อฉุกเฉิน 2 ไม่ถูกต้อง',
                                ),
                                backgroundColor: Colors.red,
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
                              const SnackBar(
                                content: Text('บันทึกข้อมูลสำเร็จ!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: medicalController.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "บันทึกข้อมูล",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          CircleAvatar(radius: 30, child: Icon(Icons.person, size: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "ข้อมูลนี้จะถูกใช้ในกรณีฉุกเฉิน\nเพื่อช่วยให้เจ้าหน้าที่ช่วยเหลือได้เร็วขึ้น",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloodTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.bloodtype, color: Colors.red, size: 32),
          const SizedBox(width: 16),
          const Text(
            "กรุ๊ปเลือด",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          DropdownButton<String>(
            hint: const Text("เลือก"),
            value: _selectedBloodType,
            underline: const SizedBox(),
            items: [
              "A",
              "B",
              "AB",
              "O",
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBloodType = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _medicalTextField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: null,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
