import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/presentation/widget/text_field_container.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class SignupProfilePage extends ConsumerStatefulWidget {
  const SignupProfilePage({super.key});

  @override
  ConsumerState<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends ConsumerState<SignupProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();

  DateTime? selectedBirthDate;
  final genders = ["ชาย", "หญิง", "ไม่ระบุ"];
  String? selectedGender;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  String formatThaiDate(DateTime date) {
    final buddhistYear = date.year + 543;
    return "${date.day}/${date.month}/$buddhistYear";
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        return;
      }

      if (next.user != null && next.user!.firstLogin != true) {
        Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);
      }
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("ข้อมูลส่วนบุคคล", style: TextStyle(fontSize: 14)),
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
                  validator: (value) => value == null || value.isEmpty
                      ? "กรุณากรอกชื่อจริง"
                      : null,
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
                  validator: (value) => value == null || value.isEmpty
                      ? "กรุณากรอกนามสกุล"
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              _label("วันเกิด"),
              TextFieldContainer(
                child: TextFormField(
                  controller: birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.cake_outlined),
                    hintText: "เลือกวันเกิด (พ.ศ.)",
                    border: InputBorder.none,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "กรุณาเลือกวันเกิด"
                      : null,
                  onTap: () async {
                    FocusScope.of(context).unfocus();

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2005),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      locale: const Locale("th", "TH"),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedBirthDate = pickedDate;
                        birthDateController.text = formatThaiDate(pickedDate);
                      });
                    }
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
                              const Icon(Icons.wc_outlined),
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
                  validator: (value) => value == null ? "กรุณาเลือกเพศ" : null,
                  decoration: const InputDecoration(border: InputBorder.none),
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
                  child: const Text("ถัดไป", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate() && selectedBirthDate != null) {
      ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            birthdate: selectedBirthDate!,
            gender: selectedGender,
          );
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
