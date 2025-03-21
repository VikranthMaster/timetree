import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timetree1/pages/login_page.dart';
import 'package:timetree1/pages/main_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController emailRegister = TextEditingController();
  final TextEditingController passwordRegister = TextEditingController();
  final TextEditingController passwordConfirm = TextEditingController();

  // Sign-up logic
  Future signup() async {
    if (passwordRegister.text.trim() != passwordConfirm.text.trim()) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Password Mismatch"),
          content: Text("Passwords do not match. Please try again."),
        ),
      );
      return;
    }

    try {
      // Firebase Auth - create user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailRegister.text.trim(),
        password: passwordRegister.text.trim(),
      );

      // Get UID
      String uid = userCredential.user!.uid;

      // Add user info to Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        'username': name.text.trim(),
        'email': emailRegister.text.trim(),
        'created_at': Timestamp.now(),
      });

      print("✅ User registered and data saved. UID: $uid");

      // Optional success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Successful!")),
      );

      // Navigate to Main Page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Main_Page()),
      );
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Registration Error"),
          content: Text(e.message ?? "An error occurred"),
        ),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    emailRegister.dispose();
    passwordRegister.dispose();
    passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      backgroundColor: const Color(0xFFD4E6C3),
      body: Transform.translate(
        offset: const Offset(0, -75),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),
                  Text(
                    "Hello There!",
                    style: GoogleFonts.bebasNeue(fontSize: 50),
                  ),
                  const SizedBox(height: 35),

                  // Name Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: name,
                      decoration: _buildInputDecoration('Name'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: emailRegister,
                      decoration: _buildInputDecoration('Email'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: passwordRegister,
                      obscureText: true,
                      decoration: _buildInputDecoration('Password'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Confirm Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: passwordConfirm,
                      obscureText: true,
                      decoration: _buildInputDecoration('Confirm Password'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: GestureDetector(
                      onTap: signup,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFD8A6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already a Member?",
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ));
                        },
                        child: const Text(
                          " Login Now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper InputDecoration
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[900]!),
        borderRadius: BorderRadius.circular(12),
      ),
      hintText: hint,
      fillColor: const Color(0xFFE6F2D9),
      filled: true,
    );
  }
}
