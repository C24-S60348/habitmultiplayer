import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import 'change_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _response = '';
  bool _isSuccess = false;

  Future<void> _requestPasswordReset() async {
    setState(() {
      _isLoading = true;
      _response = '';
      _isSuccess = false;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _response = 'Please enter your email address.';
      });
      return;
    }

    final url = Uri.parse('$apiBase/forgotpassword');
    final body = {
      'email': email,
    };
    
    http.Response? response;
    try {
      response = await safeHttpPost(url, body: body);
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

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          _isSuccess = true;
          _response = data['result']?.toString() ?? 
              'If an account with this email exists, a password reset link will be sent.';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _response = data['result']?.toString() ?? 
              'Failed to send password reset email. Please try again.';
        });
      }
    } else {
      setState(() {
        _isSuccess = false;
        _response = 'Server Error: ${response?.statusCode ?? 'Unknown'}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/skywallpaper.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.softLight,
            ),
          ),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Reset Your Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Enter your email address and we\'ll send you a password reset link.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _requestPasswordReset(),
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Send Reset Link',
                          onPressed: _requestPasswordReset,
                        ),
                        SizedBox(height: 20),
                        if (_response.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isSuccess ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSuccess ? Icons.check_circle : Icons.error,
                                  color: _isSuccess ? Colors.green : Colors.red,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _response,
                                    style: TextStyle(
                                      color: _isSuccess ? Colors.green[900] : Colors.red[900],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 20),
                        // if (_isSuccess)
                        //   Padding(
                        //     padding: const EdgeInsets.only(bottom: 8.0),
                        //     child: TextButton(
                        //       onPressed: () {
                        //         Navigator.of(context).push(
                        //           MaterialPageRoute(
                        //             builder: (context) => ChangePasswordPage(),
                        //           ),
                        //         );
                        //       },
                        //       child: Text('I have my reset token - Change Password'),
                        //     ),
                        //   ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Back to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

