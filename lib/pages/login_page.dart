import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import 'signup_page.dart';
import 'splash_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _response = '';

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _response = 'Please enter both username and password.';
      });
      return;
    }

    final url = Uri.parse('$apiBase/login?username=$username&password=$password&keeptoken=yes');
    http.Response? response;
    try {
      response = await http.get(url).timeout(Duration(seconds: 10));
    } catch (e) {
      setState(() {
        _response = 'Network error. Please check your internet connection.';
        _isLoading = false;
      });
      // Also prompt a dialog for internet connectivity
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
        final result = data['result'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInUsername', result['username'] ?? username);
        if (result['token'] != null) {
          await prefs.setString('token', result['token']);
        }

        setState(() {
          _response = 'Login successful! Welcome, $username.';
        });

        // Navigate to AdminPage if admin, else SplashScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
        
      } else {
        setState(() {
          _response = data['result']?.toString() ?? 'Invalid username or password.';
        });
      }
    } else {
      setState(() {
        _response = 'Server Error: ${response?.statusCode ?? 'Unknown'}';
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
          'Welcome Back!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7), // soft orange, matches home
        elevation: 0,
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
                      decoration: InputDecoration(labelText: 'Username'),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _fetchData(),
                    ),
                    SizedBox(height: 20),
                    CustomButton(
                      text: 'Login',
                      onPressed: _fetchData,
                    ),
                    SizedBox(height: 20),
                    Text(_response),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SignupPage(),
                          ),
                        );
                      },
                      child: Text('Don\'t have an account? Sign up'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

