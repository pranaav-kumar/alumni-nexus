import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  // Color Palette
  final Color lightBeige = Color.fromRGBO(247, 240, 234, 1);
  final Color warmBeige = Color.fromRGBO(225, 213, 201, 1);
  final Color darkGrayBlack = Color.fromRGBO(34, 35, 37, 1);
  final Color darkGrayBlack70 = Color.fromRGBO(34, 35, 37, 0.7);

  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String userType = 'Student';
  bool _isObscured = true;

  Future<void> _signUp() async {
    String? error = await _authService.signUp(
      emailController.text,
      passwordController.text,
      userType,
      nameController.text,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign Up Successful!'),
          backgroundColor: darkGrayBlack,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: darkGrayBlack),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: darkGrayBlack,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Sign up to get started',
                    style: TextStyle(fontSize: 18, color: darkGrayBlack70),
                  ),
                ),
                SizedBox(height: 40),
                _buildTextField(
                  controller: nameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  isObscured: _isObscured,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: darkGrayBlack,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: warmBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: darkGrayBlack.withOpacity(0.2)),
                  ),
                  child: DropdownButton<String>(
                    value: userType,
                    isExpanded: true,
                    underline: SizedBox(),
                    dropdownColor: warmBeige,
                    style: TextStyle(color: darkGrayBlack),
                    icon: Icon(Icons.arrow_drop_down, color: darkGrayBlack),
                    items:
                        ['Student', 'Alumni'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged:
                        (newValue) => setState(() => userType = newValue!),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGrayBlack,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      color: lightBeige,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: darkGrayBlack70),
                    ),
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInPage(),
                            ),
                          ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: darkGrayBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isObscured = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: darkGrayBlack),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: darkGrayBlack70),
        filled: true,
        fillColor: warmBeige,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGrayBlack.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGrayBlack, width: 2),
        ),
      ),
    );
  }
}
