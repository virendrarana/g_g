import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenerateLoginPage extends StatefulWidget {
  @override
  _GenerateLoginPageState createState() => _GenerateLoginPageState();
}

class _GenerateLoginPageState extends State<GenerateLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _selectedRole = 'Promoter';
  bool _isLoading = false;
  String? _message;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  Future<void> _generateLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Check password match manually before proceeding
    if (_password != _confirmPassword) {
      setState(() {
        _message = 'Passwords do not match!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      User? user = userCredential.user;

      // Send email verification
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      // Create a new user document in Firestore
      await _firestore.collection('users').doc(user?.uid).set({
        'fullName': _fullName,
        'email': _email,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create a wallet for the new user
      await _firestore.collection('wallets').doc(user?.uid).set({
        'balance': 0,
        'transactionHistory': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = 'Login ID for $_selectedRole created successfully! An email verification link has been sent.';
      });

      _formKey.currentState!.reset();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _message = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Full Name input field
  Widget _buildFullNameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
      onSaved: (value) {
        _fullName = value!.trim();
      },
    );
  }

  // Email input field
  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        } else if (!_emailRegExp.hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onSaved: (value) {
        _email = value!.trim();
      },
    );
  }

  // Password input field
  Widget _buildPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.teal,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
          tooltip: _passwordVisible ? 'Hide Password' : 'Show Password',
        ),
      ),
      obscureText: !_passwordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        } else if (!_passwordRegExp.hasMatch(value)) {
          return '''
Password must be at least 8 characters,
include an uppercase letter, number, and symbol.
''';
        }
        return null;
      },
      onSaved: (value) {
        _password = value!;
      },
    );
  }

  // Confirm Password input field
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.teal,
          ),
          onPressed: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
          tooltip: _confirmPasswordVisible ? 'Hide Password' : 'Show Password',
        ),
      ),
      obscureText: !_confirmPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        return null;
      },
      onSaved: (value) {
        _confirmPassword = value!;
      },
    );
  }

  // Role selection dropdown
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: Icon(Icons.group, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: ['Promoter', 'DeliveryPartner']
          .map((role) => DropdownMenuItem(
        value: role,
        child: Text(role),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }

  // Generate login button
  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _generateLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        'Generate Login ID',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  // Display confirmation or error message
  Widget _buildMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _message!.startsWith('Error') ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _message!.startsWith('Error') ? Icons.error_outline : Icons.check_circle_outline,
            color: _message!.startsWith('Error') ? Colors.red : Colors.green,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                color: _message!.startsWith('Error') ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Login ID'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              _buildFullNameField(),
              SizedBox(height: 20),
              _buildEmailField(),
              SizedBox(height: 20),
              _buildPasswordField(),
              SizedBox(height: 20),
              _buildConfirmPasswordField(),
              SizedBox(height: 20),
              _buildRoleDropdown(),
              SizedBox(height: 30),
              _buildGenerateButton(),
              SizedBox(height: 20),
              if (_message != null) _buildMessage(),
            ],
          ),
        ),
      ),
    );
  }
}

