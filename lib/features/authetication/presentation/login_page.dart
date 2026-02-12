import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thai_safe/features/authetication/presentation/widget/text_field_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _telcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/sign-up');
            },
            child: Text(
              "Sign Up",
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 18
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups,
                  size: 80, 
                  color: Colors.blue,
                ),
                Text(
                  "ThaiSafe",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                    letterSpacing: 3
                  ),
                ),
                Text(
                  "รวดเร็ว มั่นคง ปลอดภัย",
                  style: GoogleFonts.sarabun(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    letterSpacing: 1
                  ),
                ),
                const SizedBox(height: 30,),
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
                const SizedBox(height: 30,),
                TextFieldContainer(
                  child: TextField(
                    controller: _passwordcontroller,
                    obscureText: _isPasswordVisible ? false : true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                            ? Icons.visibility 
                            : Icons.visibility_off
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      hintText: "Password",
                      border: InputBorder.none,
                    ),
                  ),
                ),
            
                Text(
                  "Forgot Password?",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 1
                      ),
                    ),
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
                    Text("or sign in with"),
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
      ),
    );
  }
}
