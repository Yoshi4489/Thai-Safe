import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _telcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sign-up');
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
              TextField(
                controller: _telcontroller,
                decoration: InputDecoration(
                  labelText: "Telephone",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9999)
                  ),
                  prefix: Icon(Icons.phone)
                ),
              ),
              const SizedBox(height: 30,),
              TextField(
                controller: _passwordcontroller,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9999)
                  ),
                  prefix: Icon(Icons.lock)
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
                  Text("Or sign in with"),
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
