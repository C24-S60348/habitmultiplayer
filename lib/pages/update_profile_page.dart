import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import 'change_password_page.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  String _response = '';
  bool _isSuccess = false;
  String? _currentUsername;
  String? _currentName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('loggedInUsername');
    final token = prefs.getString('token') ?? '';

    // Fetch current profile data (name) from API
    if (token.isNotEmpty && _currentUsername != null && _currentUsername != 'guest') {
      try {
        final url = Uri.parse('$apiBase/readprofile');
        final body = {
          'token': token,
          'usernames': _currentUsername!,
        };
        final response = await safeHttpPost(url, body: body);
        
        if (response != null && response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'ok' && data['data'] != null) {
            final List<dynamic> profiles = data['data'] as List<dynamic>;
            if (profiles.isNotEmpty) {
              final profile = profiles[0] as Map<String, dynamic>;
              _currentName = profile['name']?.toString() ?? '';
              // Pre-populate the name field
              if (_currentName!.isNotEmpty) {
                _nameController.text = _currentName!;
              }
            }
          }
        }
      } catch (e) {
        // If API call fails, continue without pre-populating name
        print('Error fetching profile: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true;
      _response = '';
      _isSuccess = false;
    });

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _isSaving = false;
        _response = 'Please enter your name.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      setState(() {
        _isSaving = false;
        _response = 'You must be logged in to update your profile.';
      });
      return;
    }

    final url = Uri.parse('$apiBase/updateprofile');
    final body = {
      'token': token,
      'name': name,
    };
    
    http.Response? response;
    try {
      response = await safeHttpPost(url, body: body);
    } catch (e) {
      setState(() {
        _response = 'Network error. Please check your internet connection.';
        _isSaving = false;
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
          _response = 'Profile updated successfully.';
          // Update current name to reflect the change
          _currentName = name;
        });
        
        // Show success message and update UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Return result indicating profile was updated
        Navigator.of(context).pop({'profileUpdated': true});
      } else {
        setState(() {
          _isSuccess = false;
          _response = data['message']?.toString() ?? 
              'Failed to update profile. Please try again.';
        });
      }
    } else {
      setState(() {
        _isSuccess = false;
        _response = 'Server Error: ${response?.statusCode ?? 'Unknown'}';
      });
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Update Profile'),
          backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profile',
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Update Your Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_currentUsername != null && _currentUsername != 'guest')
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Username: $_currentUsername',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_currentName != null && _currentName!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current Name: $_currentName',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  SizedBox(height: 32),
                  // Name section
                  Text(
                    'Update Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 24),
                  CustomButton(
                    text: _isSaving ? 'Saving...' : 'Update Name',
                    onPressed: _isSaving ? null : _updateProfile,
                  ),
                  // Change Password section
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChangePasswordPage(),
                        ),
                      ),
                      child: Text(
                        'Change Password?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

