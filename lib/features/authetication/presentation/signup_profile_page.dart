import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authetication/presentation/widget/text_field_container.dart';
import 'package:thai_safe/features/authetication/providers/auth_state_provider.dart';

class SignupProfilePage extends ConsumerStatefulWidget {
  const SignupProfilePage({super.key});

  @override
  ConsumerState<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends ConsumerState<SignupProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();

  final genders = ["ชาย", "หญิง", "ไม่ระบุ"];
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      // ERROR
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        return;
      }

      // SUCCESS
      // Note: Futre will route to home
      Navigator.pushNamed(context, "");
    });
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("ข้อมูลส่วนบุคคล"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _sectionTitle("ข้อมูลพื้นฐาน"),

              _label("ชื่อจริง"),
              TextFieldContainer(
                child: TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: "กรอกชื่อจริง",
                    border: InputBorder.none,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "กรุณากรอกชื่อจริง" : null,
                ),
              ),

              const SizedBox(height: 16),

              _label("นามสกุล"),
              TextFieldContainer(
                child: TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.assignment_ind_outlined),
                    hintText: "กรอกนามสกุล",
                    border: InputBorder.none,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "กรุณากรอกนามสกุล" : null,
                ),
              ),

              const SizedBox(height: 16),

              _label("อายุ"),
              TextFieldContainer(
                child: TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.cake_outlined),
                    hintText: "อายุ",
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "กรุณากรอกอายุ";
                    }
                    if (int.tryParse(value) == null) {
                      return "กรุณากรอกตัวเลขเท่านั้น";
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              _label("เพศ"),
              TextFieldContainer(
                child: DropdownButtonFormField<String>(
                  hint: Row(
                    children: const [
                      SizedBox(width: 12),
                      Icon(Icons.wc_outlined),
                      SizedBox(width: 8),
                      Text("เลือกเพศ"),
                    ],
                  ),
                  items: genders
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.wc_outlined),
                              const SizedBox(width: 8),
                              Text(g),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "กรุณาเลือกเพศ" : null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "ถัดไป",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      int age = int.parse(ageController.text);
      ref.watch(authControllerProvider.notifier).updateProfile(firstName: firstName, lastName: lastName, age: age, gender: selectedGender);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
