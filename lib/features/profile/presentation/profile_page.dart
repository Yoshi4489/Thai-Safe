import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final cloud_url = Uri.parse("${dotenv.env['CLOUD_URL']}/${dotenv.env['CLOUD_NAME']}/upload");

  @override
  Widget build(BuildContext context) {
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

  // ---------------- WIDGETS ----------------

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 30,
            child: Icon(Icons.person, size: 32),
          ),
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
            underline: const SizedBox(),
            items: ["A", "B", "AB", "O"]
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g),
                  ),
                )
                .toList(),
            onChanged: (_) {},
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
