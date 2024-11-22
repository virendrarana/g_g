import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:g_g/screens/forgot_password_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';// Password confirmation field
  bool _isPasswordVisible = false; // Track password visibility for password field
  bool _isConfirmPasswordVisible = false; // Track password visibility for confirm password field

  String _contactNumber = ''; // Contact number field
  String _role = 'Customer'; // Hardcoded role as 'Customer'
  String _referralCode = ''; // New field for referral code
  bool _isLoading = false;
  bool _isReferralValid = true; // To track if referral code is valid or not

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // If a referral code is provided, validate it first
      if (_referralCode.isNotEmpty) {
        _isReferralValid = await _validateReferralCode(_referralCode);
        if (!_isReferralValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid referral code. Please try again.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Show dialog to inform the user that the email verification link has been sent
        _showEmailVerificationDialog();

        // Save user data and role to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': _fullName,
          'email': _email,
          'contactNumber': _contactNumber, // Save contact number
          'role': _role, // Role is always 'Customer'
          'createdAt': FieldValue.serverTimestamp(),
          'referralCodeUsed': _referralCode, // Store the used referral code
        });

        // If a referral code is used, update its usage count
        if (_referralCode.isNotEmpty) {
          await _firestore
              .collection('referral_codes')
              .doc(_referralCode)
              .update({
            'usageCount': FieldValue.increment(1), // Increment usage count
          });
        }
        // Create a wallet for the user
        await _firestore.collection('wallets').doc(user.uid).set({
          'fullName': _fullName,
          'points': 0,
          'transactionHistory': [],

        });

        // Log the user out until they verify their email
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Show dialog to inform user that the email verification link has been sent
  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Your Email'),
          content: Text(
              'A verification link has been sent to your email. Please verify your email and log in again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Validate referral code by checking if it exists in Firestore
  Future<bool> _validateReferralCode(String code) async {
    try {
      DocumentSnapshot referralDoc =
      await _firestore.collection('referral_codes').doc(code).get();
      return referralDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Color color_main = const Color.fromRGBO(10, 81, 37, 1);

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color_main,
              color_main,
              color_main,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 25.0),
            child: Column(
              children: [
                _buildLogo(screenSize),
                _buildSignUpCard(screenSize),
                SizedBox(height: 20),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Size screenSize) {
    return Center(
      child: Container(
        width: screenSize.width * 0.85,
        height: screenSize.width * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('images/Gutful_page.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpCard(Size screenSize) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFullNameField(),
              SizedBox(height: 15),
              _buildEmailField(),
              SizedBox(height: 15),
              _buildPasswordField(),
              SizedBox(height: 15),
              _buildConfirmPasswordField(), // New password confirmation field
              SizedBox(height: 15),
              _buildContactNumberField(), // Contact number field
              SizedBox(height: 15),
              _buildReferralCodeField(), // Referral code field
              SizedBox(height: 20),
              _buildSignUpButton(),
              SizedBox(height: 10),
              _buildForgotPasswordLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Full Name',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: Colors.black87),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
      onSaved: (value) {
        _fullName = _capitalizeEachWord(value!.trim());
      },
    );
  }

  Widget _buildContactNumberField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.phone, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Contact Number',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: Colors.black87),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your contact number';
        } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
          return 'Please enter a valid 10-digit number';
        }
        return null;
      },
      onSaved: (value) {
        _contactNumber = value!.trim();
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Email',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: Colors.black87),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null ||
            value.isEmpty ||
            !value.contains('@') ||
            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onSaved: (value) {
        _email = value!.trim();
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Password',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Color.fromRGBO(10, 81, 37, 1),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
            });
          },
        ),
      ),
      style: TextStyle(color: Colors.black87),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        } else if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
      onChanged: (value) {
        _password = value.trim();
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Color.fromRGBO(10, 81, 37, 1),
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible; // Toggle visibility
            });
          },
        ),
      ),
      style: TextStyle(color: Colors.black87),
      obscureText: !_isConfirmPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        } else if (value != _password) {
          return 'Passwords do not match';
        }
        return null;
      },
      onSaved: (value) {
        _confirmPassword = value!.trim();
      },
    );
  }


  Widget _buildReferralCodeField() {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.card_giftcard, color: Color.fromRGBO(10, 81, 37, 1)),
        labelText: 'Referral Code (optional)',
        labelStyle: TextStyle(color: Color.fromRGBO(10, 81, 37, 1)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: Colors.black87),
      onSaved: (value) {
        _referralCode = value!.trim();
      },
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(10, 81, 37, 1),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: _isLoading ? 0 : 5,
        ),
        child: _isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
          );
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color.fromRGBO(10, 81, 37, 1),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to capitalize each word in the name
  String _capitalizeEachWord(String value) {
    return value.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).join(' ');
  }
}
