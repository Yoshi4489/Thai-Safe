import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thai_safe/core/services/cloudinary_provider.dart';
import 'package:thai_safe/core/validators/phone_validator.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  File? _imageFile;
  String? _selectedBloodType;
  String? chronic_diseases;
  String? regular_medications;
  String? allergies;
  Map<String, String>? contact_list;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    setState(() {
        if (pickedFile != null) {
          _imageFile = File(pickedFile.path);
        };
    });
  }
  
  @override
  Widget build(BuildContext) {
    final _cloudProvider = ref.watch(cloudinaryServiceProvider);
    final _authController = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text("โปรไฟล์ & ข้อมูลแพทย์"),
        centerTitle: true,
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
                    await _pickImage(ImageSource.camera);
                    if (_imageFile != null) {
                      final res = await _cloudProvider.uploadImage(_imageFile!);
                      if (res.isNotEmpty) {
                        ref.read(authControllerProvider.notifier).updateProfile(profile_url: res);
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _authController.user?.profile_url != null
                            ? NetworkImage(_authController.user!.profile_url)
                            : null,
                        child: _authController.user?.profile_url == null
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
                        "${_authController.user?.firstName ?? "ชื่อจริง"} ${_authController.user?.lastName ?? "นามสกล"}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(PhoneValidator.convertToNormalPhone(_authController.user?.tel ?? "")),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24,),

            _profileHeader(),

            const SizedBox(height: 24),

            _sectionTitle("ข้อมูลทางการแพทย์"),

            _bloodTypeCard(),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.health_and_safety_outlined,
              label: "โรคประจำตัว",
              hint: "เช่น เบาหวาน, ความดัน, หอบหืด",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.medication_outlined,
              label: "ยาประจำ",
              hint: "เช่น Insulin, Ventolin",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.warning_amber_rounded,
              label: "อาการแพ้ยา / แพ้อาหาร",
              hint: "เช่น แพ้เพนนิซิลลิน, อาหารทะเล",
            ),

            const SizedBox(height: 24),

            _sectionTitle("ผู้ติดต่อฉุกเฉิน"),

            _medicalTextField(
              icon: Icons.person_outline,
              label: "ชื่อผู้ติดต่อ",
              hint: "ชื่อ – นามสกุล",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.phone_outlined,
              label: "เบอร์โทรศัพท์",
              hint: "0xx-xxx-xxxx",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.person_outline,
              label: "ชื่อผู้ติดต่อ",
              hint: "ชื่อ – นามสกุล",
            ),

            const SizedBox(height: 16),

            _medicalTextField(
              icon: Icons.phone_outlined,
              label: "เบอร์โทรศัพท์",
              hint: "0xx-xxx-xxxx",
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text(
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          maxLines: null,
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
