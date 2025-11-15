import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_helpers.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _response = '';

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _response = 'Please enter both email and password.';
      });
      return;
    }

    // Register new user on the new API (requires passwordadmin)
    final url = Uri.parse('$apiBase/register');
    final body = {
      'email': username, // Backend expects 'email' parameter
      'password': password,
      'passwordrepeat': password,
      'passwordadmin': 'afwan',
    };
    http.Response? signupResponse;
    try {
      signupResponse = await safeHttpPost(url, body: body);
    } catch (e) {
      setState(() {
        _response = 'Network error. Please check your internet connection.';
        _isLoading = false;
      });
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Internet Connection'),
            content: Text('Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (signupResponse != null && signupResponse.statusCode == 200) {
      final data = jsonDecode(signupResponse.body);
      if (data['status'] == 'ok') {
      setState(() {
        _response = 'Signup successful! You can now log in.';
      });

      // Optional: Navigate to login after short delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Go back to LoginPage
      });
      } else {
        setState(() {
          _response = data['result']?.toString() ?? 'Signup failed. Please try again.';
        });
      }
    } else {
      setState(() {
        _response = 'Signup failed. Please try again.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Signup Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/skywallpaper.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8), // Adjust opacity here (0.0 to 1.0)
              BlendMode.softLight, // Try different blend modes: overlay, softLight, hardLight, etc.
            ),
          ),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        shadowColor: Colors.black.withOpacity(0.5),
                        elevation: 10,
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(_response),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

