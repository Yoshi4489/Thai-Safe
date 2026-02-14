import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thai_safe/features/authetication/presentation/widget/text_field_container.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _telcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              "Log In",
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.groups, size: 80, color: Colors.blue),
              Text(
                "ThaiSafe",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                  letterSpacing: 3,
                ),
              ),
              Text(
                "รวดเร็ว มั่นคง ปลอดภัย",
                style: GoogleFonts.sarabun(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 30),
              TextFieldContainer(
                child: TextField(
                  controller: _telcontroller,
                  keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    hintText: "Telephone",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sign-up-otp');
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                  ),
                  child: Text("Sign Up"),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("or sign up with"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              IconButton(
                onPressed: null,
                icon: Image.asset(
                  "assets/images/auth/ThaiID.png",
                  height: 40,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
