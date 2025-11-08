import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'fy/main.dart'; // Import FYPage
import 'test/main.dart'; // Import TestPage


//------------ Conditional imports
import 'platform_mobile.dart'
  if (dart.library.html) 'platform_web.dart'
  if (dart.library.io) 'platform_windows.dart';

// API base for new server
const String apiBase = 'https://afwanhaziq.vps.webdock.cloud/api/habit';

// Simple connectivity check (works on all platforms)
Future<bool> hasInternetConnection() async {
  try {
    final response = await http
        .get(Uri.parse('https://www.google.com/generate_204'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 204 || response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

// Helper function for safe HTTP GET requests with timeout and error handling
Future<http.Response?> safeHttpGet(Uri url, {Duration timeout = const Duration(seconds: 10)}) async {
  try {
    // Yield control to UI thread before making request
    await Future.delayed(Duration.zero);
    return await http.get(url).timeout(timeout);
  } catch (e) {
    print('Network error: $e');
    return null;
  }
}

// Helper function for safe JSON decoding that yields control
dynamic safeJsonDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (e) {
    print('JSON decode error: $e');
    return null;
  }
}

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.fontSize = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

void main() {
  //runAppEntry();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Multiplayer',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 62, 83, 93),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 62, 83, 93),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

//--------splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String loggedInUser = '';
  bool _isLoading = true;
  bool _isCheckingInternet = false;

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    // Check internet after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndPrompt();
    });
  }

  // Method to fetch logged-in user from SharedPreferences
  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    setState(() {
      loggedInUser = username; // Display a default if not logged in
      _isLoading = false;
    });
  }

  Future<void> _checkInternetAndPrompt() async {
    if (_isCheckingInternet || !mounted) return;
    setState(() {
      _isCheckingInternet = true;
    });
    try {
      final online = await hasInternetConnection();
      if (!online && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Internet Connection'),
            content: Text('Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _checkInternetAndPrompt();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingInternet = false;
        });
      } else {
        _isCheckingInternet = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show spinner while loading user
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🌟 Habit Multiplayer 🌟',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    letterSpacing: 2,
                    color: Theme.of(context).primaryColor,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.blueGrey.withOpacity(0.3),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32), // Spacing
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 170, 247, 93).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Welcome, $loggedInUser',
                    style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 121, 133, 139)),
                  ),
                ),
                SizedBox(height: 32), // Spacing
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomePage()));
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: EdgeInsets.all(80),
                    backgroundColor: Theme.of(context).primaryColor,
                    shadowColor: Colors.black.withOpacity(0.5),
                    elevation: 10,
                  ),
                  child: Text('Start', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.5)),
                ),
                if (loggedInUser == 'afwan')
                  Column(
                    children: [
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => FYPage()));
                      },
                      child: Text('Fy Page'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => TestPage()));
                      },
                      child: Text('Test Page'),
                    ),
                   ],
                   
                  ),
                
                
                const SizedBox(height: 32),
                if (loggedInUser == 'guest')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CustomButton(
                      text: 'Login',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                        );
                      },
                    ),
                  ),
                if (loggedInUser != 'guest')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CustomButton(
                      text: 'Logout',
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('loggedInUsername'); // Clear the logged-in user
                        await prefs.remove('token'); // Clear token
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => SplashScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//--------Login page
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

//--------Signup page
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
        _response = 'Please enter both username and password.';
      });
      return;
    }

    // Register new user on the new API (requires passwordadmin)
    final url = Uri.parse(
      '$apiBase/register?username=$username&password=$password&passwordrepeat=$password&passwordadmin=afwan',
    );
    http.Response? signupResponse;
    try {
      signupResponse = await http.get(url).timeout(Duration(seconds: 10));
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
                      decoration: InputDecoration(labelText: 'Username'),
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

//------------- home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

final buttonData = [
  {'title': 'Baca Al-quran', 'link': 'https://quran.com'},
  {'title': 'Buat app', 'link': 'https://flutter.dev'},
  {
    'title': 'Workout',
    'link':
        'https://www.nerdfitness.com/wp-content/uploads/2021/02/Beginner-Bodyweight-Workout-Infographic-scaled.jpg',
  },
  {'title': 'Jog', 'link': 'https://www.finishline.com/'},
  {'title': 'Meditasi', 'link': 'https://www.meditation.com'},
];

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String loggedInUser = '';
  final TextEditingController _habitTitleController = TextEditingController();
  final TextEditingController _habitLinkController = TextEditingController();
  bool _isLoading = true;
  bool _hasShownNoInternetDialog = false;
  bool _isLoadingHabits = false; // Guard to prevent concurrent loads

  Color _colorFromThirdLetterLightMode(String title) {
    if (title.length < 3) return Colors.blueGrey;
    
    final thirdLetter = title[2].toLowerCase();
    final colors = {
      'a': Color(0xFFE57373), // Light Red
      'b': Color(0xFF81C784), // Light Green
      'c': Color(0xFF64B5F6), // Light Blue
      'd': Color(0xFFFFB74D), // Light Orange
      'e': Color(0xFFBA68C8), // Light Purple
      'f': Color(0xFF4DB6AC), // Teal
      'g': Color(0xFFFFD54F), // Yellow
      'h': Color(0xFF7986CB), // Indigo
      'i': Color(0xFFF06292), // Pink
      'j': Color(0xFF4DD0E1), // Cyan
      'k': Color(0xFFFF8A65), // Deep Orange
      'l': Color(0xFF9575CD), // Deep Purple
      'm': Color(0xFF4FC3F7), // Light Blue
      'n': Color(0xFFFFB74D), // Orange
      'o': Color(0xFF81C784), // Green
      'p': Color(0xFFBA68C8), // Purple
      'q': Color(0xFF4DB6AC), // Teal
      'r': Color(0xFFE57373), // Red
      's': Color(0xFF64B5F6), // Blue
      't': Color(0xFFFFD54F), // Yellow
      'u': Color(0xFF7986CB), // Indigo
      'v': Color(0xFFF06292), // Pink
      'w': Color(0xFF4DD0E1), // Cyan
      'x': Color(0xFFFF8A65), // Deep Orange
      'y': Color(0xFF9575CD), // Deep Purple
      'z': Color(0xFF4FC3F7), // Light Blue
    };
    
    return colors[thirdLetter] ?? Colors.blueGrey;
  }

  Color _colorFromThirdLetterDarkMode(String title) {
    if (title.length < 3) return Colors.blueGrey.shade800;
    
    final thirdLetter = title[2].toLowerCase();
    final colors = {
      'a': Color(0xFFB71C1C), // Dark Red
      'b': Color(0xFF1B5E20), // Dark Green
      'c': Color(0xFF0D47A1), // Dark Blue
      'd': Color(0xFFE65100), // Dark Orange
      'e': Color(0xFF4A148C), // Dark Purple
      'f': Color(0xFF004D40), // Dark Teal
      'g': Color(0xFFF57F17), // Dark Yellow
      'h': Color(0xFF1A237E), // Dark Indigo
      'i': Color(0xFF880E4F), // Dark Pink
      'j': Color(0xFF006064), // Dark Cyan
      'k': Color(0xFFBF360C), // Dark Deep Orange
      'l': Color(0xFF4A148C), // Dark Deep Purple
      'm': Color(0xFF01579B), // Dark Light Blue
      'n': Color(0xFFE65100), // Dark Orange
      'o': Color(0xFF1B5E20), // Dark Green
      'p': Color(0xFF4A148C), // Dark Purple
      'q': Color(0xFF004D40), // Dark Teal
      'r': Color(0xFFB71C1C), // Dark Red
      's': Color(0xFF0D47A1), // Dark Blue
      't': Color(0xFFF57F17), // Dark Yellow
      'u': Color(0xFF1A237E), // Dark Indigo
      'v': Color(0xFF880E4F), // Dark Pink
      'w': Color(0xFF006064), // Dark Cyan
      'x': Color(0xFFBF360C), // Dark Deep Orange
      'y': Color(0xFF4A148C), // Dark Deep Purple
      'z': Color(0xFF01579B), // Dark Light Blue
    };
    
    return colors[thirdLetter] ?? Colors.blueGrey.shade800;
  }

  final bool _isDarkMode = true; // Add this state variable

  Color _colorFromThirdLetter(String title) {
    return _isDarkMode ? _colorFromThirdLetterDarkMode(title) : _colorFromThirdLetterLightMode(title);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getLoggedInUser();
    _loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLoadingHabits) {
      // Add small delay to prevent rapid-fire calls
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted && !_isLoadingHabits) {
          _loadHabits(); // Reload habits when app is resumed
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadHabits();
  }

  Future<void> _showNoInternetDialog() async {
    if (_hasShownNoInternetDialog || !mounted) return;
    setState(() {
      _hasShownNoInternetDialog = true;
    });
    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Internet Connection'),
            content: Text('Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadHabits();
                },
                child: Text('Retry'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _hasShownNoInternetDialog = false;
        });
      } else {
        _hasShownNoInternetDialog = false;
      }
    }
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUser = prefs.getString('loggedInUsername') ?? 'guest';
    });
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _habitTitleController,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g., Read Books',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _habitLinkController,
                decoration: InputDecoration(
                  labelText: 'Habit Link (Optional)',
                  hintText: 'e.g., https://example.com',
                  errorText: _habitLinkController.text.isNotEmpty && !DialogUtils.isValidUrl(_habitLinkController.text)
                      ? 'Please enter a valid URL (e.g., https://example.com)'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show/hide error
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            CustomButton(
              text: 'Add Habit',
              onPressed: () async {
                if (_habitTitleController.text.isNotEmpty) {
                  final success = await _addNewHabit(
                    _habitTitleController.text,
                    _habitLinkController.text,
                  );
                  // Only close dialog and clear fields if habit was successfully added
                  if (success) {
                    Navigator.of(context).pop();
                    _habitTitleController.clear();
                    _habitLinkController.clear();
                  }
                  // If not successful, keep dialog open so user can fix the error
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> showLinkValidationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Link'),
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Continue Anyway'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _addNewHabit(String title, String link) async {
    if (link.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return false;
    } else if (!DialogUtils.isValidUrl(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return false; // Return false to keep dialog open
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final createUrl = Uri.parse(
      '$apiBase/createhabit?name=${Uri.encodeQueryComponent(title)}&url=${Uri.encodeQueryComponent(link.isEmpty ? 'https://example.com' : link)}&token=$token',
    );
    final createResp = await safeHttpGet(createUrl);
    if (createResp == null || createResp.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create habit'), backgroundColor: Colors.red),
      );
      return false; // Return false to keep dialog open
    }
    final respData = jsonDecode(createResp.body);
    if (respData['status'] != 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(respData['message']?.toString() ?? 'Failed to create habit'), backgroundColor: Colors.red),
      );
      return false; // Return false to keep dialog open
    }
    
    // Handle both Map and List responses from the API
    Map<String, dynamic>? createdHabit;
    final data = respData['data'];
    if (data != null) {
      if (data is List && data.isNotEmpty) {
        // If it's a list, take the first element
        createdHabit = data.first as Map<String, dynamic>?;
      } else if (data is Map) {
        // If it's already a Map, use it directly
        createdHabit = data as Map<String, dynamic>?;
      }
    }

    // Update the local buttonData
    setState(() {
      if (createdHabit != null) {
        buttonData.add({
          'id': createdHabit['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'title': createdHabit['name']?.toString() ?? title,
          'link': createdHabit['url']?.toString() ?? (link.isEmpty ? 'https://example.com' : link),
        });
      } else {
        // If we couldn't parse the response, still add the habit with generated ID
        buttonData.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'link': link.isEmpty ? 'https://example.com' : link,
        });
      }
    });
    
    // Reload habits from server to ensure we have the latest data
    _loadHabits();
    return true; // Return true to indicate success
  }

  Future<void> _editHabit(String habitId, String newTitle, String newLink) async {
    if (newLink.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return;
    } else if (!DialogUtils.isValidUrl(newLink)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Update title (name)
    final updateNameUrl = Uri.parse(
      '$apiBase/updatehabit?id=${Uri.encodeQueryComponent(habitId)}&newname=name&newdata=${Uri.encodeQueryComponent(newTitle)}&token=${Uri.encodeQueryComponent(token)}',
    );
    final updateNameResp = await safeHttpGet(updateNameUrl);
    if (updateNameResp == null || updateNameResp.statusCode != 200) {
      final errorMsg = updateNameResp != null 
          ? (jsonDecode(updateNameResp.body)['message']?.toString() ?? 'Failed to update title')
          : 'Network error. Please check your connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }
    final updateNameData = jsonDecode(updateNameResp.body);
    if (updateNameData['status'] != 'ok') {
      final errorMsg = updateNameData['message']?.toString() ?? 'Failed to update title';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }

    // Update link (url) if provided, else keep old (server disallows empty)
    if (newLink.isNotEmpty) {
      final updateUrlUrl = Uri.parse(
        '$apiBase/updatehabit?id=${Uri.encodeQueryComponent(habitId)}&newname=url&newdata=${Uri.encodeQueryComponent(newLink)}&token=${Uri.encodeQueryComponent(token)}',
      );
      final updateUrlResp = await safeHttpGet(updateUrlUrl);
      if (updateUrlResp == null || updateUrlResp.statusCode != 200) {
        final errorMsg = updateUrlResp != null
            ? (jsonDecode(updateUrlResp.body)['message']?.toString() ?? 'Failed to update link')
            : 'Network error. Please check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }
      final updateUrlData = jsonDecode(updateUrlResp.body);
      if (updateUrlData['status'] != 'ok') {
        final errorMsg = updateUrlData['message']?.toString() ?? 'Failed to update link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }
    }

      // Update the local buttonData
      setState(() {
        final index = buttonData.indexWhere((item) => item['id'] == habitId);
        if (index != -1) {
          buttonData[index]['title'] = newTitle;
        if (newLink.isNotEmpty) {
          buttonData[index]['link'] = newLink;
        }
        }
      });
  }

  Future<void> _showEditHabitDialog(BuildContext context, String habitId, String currentTitle, String currentLink) async {
    final TextEditingController titleController = TextEditingController(text: currentTitle);
    final TextEditingController linkController = TextEditingController(text: currentLink);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g., Read Books',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'Habit Link (Optional)',
                  hintText: 'e.g., https://example.com',
                  errorText: linkController.text.isNotEmpty && !DialogUtils.isValidUrl(linkController.text)
                      ? 'Please enter a valid URL (e.g., https://example.com)'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show/hide error
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            CustomButton(
              text: 'Save Changes',
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await _editHabit(
                    habitId,
                    titleController.text,
                    linkController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadHabits() async {
    if (!mounted || _isLoadingHabits) return; // Prevent concurrent loads
    
    setState(() {
      _isLoading = true;
      _isLoadingHabits = true;
    });
    
    // Yield control to UI thread
    await Future.delayed(Duration.zero);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/readhabit?token=$token');

    try {
      final response = await safeHttpGet(url);

      if (response != null && response.statusCode == 200) {
        // Yield before parsing JSON
        await Future.delayed(Duration.zero);
        final data = safeJsonDecode(response.body);
        if (data != null && data['status'] == 'ok') {
          final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              buttonData.clear();
              for (final item in list) {
                final m = item as Map<String, dynamic>;
                buttonData.add({
                  'id': m['id']?.toString() ?? '',
                  'title': m['name']?.toString() ?? '',
                  'link': m['url']?.toString() ?? 'https://example.com',
                });
              }
            });
          }
        } else {
          // Server responded but status not ok; optionally notify
        }
      } else {
        if (mounted) {
          await _showNoInternetDialog();
        }
      }
    } catch (e) {
      print('Error loading habits: $e');
      if (mounted) {
        await _showNoInternetDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingHabits = false;
        });
      } else {
        _isLoadingHabits = false;
      }
    }
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 6, // Show 6 shimmer items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete All Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHabits,
            tooltip: 'Refresh Habits',
          ),
          // IconButton(
          //   icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          //   onPressed: () {
          //     setState(() {
          //       _isDarkMode = !_isDarkMode;
          //     });
          //   },
          // ),
        ],
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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _isLoading
                            ? _buildShimmerGrid()
                            : buttonData.isEmpty
                                ? Center(
                                    child: Text(
                                      'No habits yet. Add some!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: buttonData.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.all(8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final result = await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => InsidePage(
                                                  title: buttonData[index]['title']!,
                                                  link: buttonData[index]['link']!,
                                                  habitId: buttonData[index]['id']!,
                                                ),
                                              ),
                                            );
                                            if (result != null && result == true) {
                                              _loadHabits(); // Refresh the habits list
                                            }
                                          },
                                          onLongPress: () {
                                            _showEditHabitDialog(
                                              context,
                                              buttonData[index]['id']!,
                                              buttonData[index]['title']!,
                                              buttonData[index]['link']!,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _colorFromThirdLetter(buttonData[index]['title']!),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(50),
                                            ),
                                          ),
                                          child: Text(
                                            buttonData[index]['title']!,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0,bottom: 16.0),
                  child: CustomButton(
                    text: 'Add New Habit',
                    onPressed: () async {
                      await _showAddHabitDialog(context);
                      _loadHabits(); // Reload habits after adding new one
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//--------- InsidePage with Tab Navigation
class InsidePage extends StatefulWidget {
  final String habitId;
  String title;
  String link;

  InsidePage({
    super.key, 
    required this.title, 
    required this.link,
    required this.habitId,
  });

  @override
  _InsidePageState createState() => _InsidePageState();
}

class _InsidePageState extends State<InsidePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late WebIframeView _webIframeView;
  final bool _showNotes = false;
  int _habitState = 0; // 0: blank, 1: ticked, 2: X
  bool _isLoadingHabitState = false; // Add loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _webIframeView = WebIframeView(url: widget.link);
    _loadHabitState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHabitState(); // Reload habit state when app is resumed
    }
  }

  Future<void> _loadHabitState() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final url = Uri.parse('$apiBase/readhistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&token=${Uri.encodeQueryComponent(token)}');
      final response = await safeHttpGet(url);
      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ReadHistory network error: Please check your connection'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          final List<dynamic> hist = (data['data'] ?? []) as List<dynamic>;
          
          // Debug: Show what we received
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📖 Loaded ${hist.length} history entries for habit ${widget.habitId}'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
          
          // Find the history entry for today for this user
          Map<String, dynamic>? mineToday;
          for (final item in hist) {
            final m = item as Map<String, dynamic>;
            final itemUsername = m['username']?.toString() ?? '';
            final itemDate = m['historydate']?.toString() ?? '';
            
            if (itemUsername == username && itemDate == dateKey) {
              mineToday = m;
              break;
            }
          }
          
          setState(() {
            if (mineToday != null && mineToday['historystatus'] != null) {
              _habitState = int.tryParse(mineToday['historystatus']?.toString() ?? '0') ?? 0;
              
              // Debug: Show what state was found
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Found state: $_habitState for $username on $dateKey'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              _habitState = 0; // Default to unchecked if no entry found
              
              // Debug: Show that no entry was found
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ No history found for $username on $dateKey (Looking for: username="$username", date="$dateKey")'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          });
        } else {
          // API returned error status
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ReadHistory failed: ${data['message']?.toString() ?? 'Unknown error'}'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // HTTP error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ReadHistory HTTP error: ${response.statusCode}'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading habit state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ReadHistory exception: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cycleHabitState() async {
    // Store previous state for potential revert
    final previousState = _habitState;
    
    // Set loading state to true
    setState(() {
      _isLoadingHabitState = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Update the tick state for this habit and date
    int newState;
    if (_habitState == 0) {
      newState = 1;
    } else if (_habitState == 1) {
      newState = -1;
    } else {
      newState = 0;
    }
    
    // Update UI optimistically
    setState(() {
      _habitState = newState;
    });
    
    // Debug: Show what we're trying to save
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💾 Saving: habitId=${widget.habitId}, date=$dateKey, status=$newState, username=$username'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
    
    try {
      final url = Uri.parse(
        '$apiBase/updatehistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&historydate=$dateKey&historystatus=$newState&token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await safeHttpGet(url);
      if (response == null) {
        // Revert on network error
        setState(() {
          _habitState = previousState; // Revert to previous state
          _isLoadingHabitState = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Network error: Please check your connection'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          // Successfully saved
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ UpdateHistory success! Message: ${data['message']?.toString() ?? 'Saved'}'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Now reload from server to ensure we have the correct state
          await _loadHabitState();
        } else {
          // API returned error
          final errorMsg = data['message']?.toString() ?? 'Failed to update habit state';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ UpdateHistory failed: $errorMsg'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Reload to get the actual state from server
          await _loadHabitState();
        }
      } else {
        // HTTP error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ UpdateHistory HTTP error: ${response.statusCode}\nResponse: ${response.body}'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Reload to get actual state
        await _loadHabitState();
      }
    } catch (e) {
      print('Error updating habit state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ UpdateHistory exception: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      // On error, reload to get actual state from server
      await _loadHabitState();
    } finally {
      setState(() {
        _isLoadingHabitState = false;
      });
    }
  }

  IconData get _habitIcon {
    switch (_habitState) {
      case 1:
        return Icons.check_box;
      case -1:
        return Icons.close;
      default:
        return Icons.check_box_outline_blank;
    }
  }

  String get _habitTooltip {
    switch (_habitState) {
      case 1:
        return 'Habit done (tap to mark as not done)';
      case 2:
        return 'Habit not done (tap to reset)';
      default:
        return 'Mark habit as done';
    }
  }

  void _navigateToEditPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditHabitPage(
          habitId: widget.habitId,
          currentTitle: widget.title,
          currentLink: widget.link,
        ),
      ),
    );

    if (result != null) {
      if (result['deleted'] == true) {
        // If habit was deleted, pop back to home page and trigger refresh
        Navigator.of(context).pop(true); // Pass true to indicate deletion
      } else {
        setState(() {
          widget.title = result['title'];
          widget.link = result['link'];
          _webIframeView = WebIframeView(url: widget.link);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _navigateToEditPage,
          child: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        actions: [
          IconButton(
            icon: Icon(Icons.note),
            tooltip: 'Open Notes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotesPage(
                    title: widget.title,
                    habitId: widget.habitId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Habit History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitHistoryPage(habitId: widget.habitId, habitTitle: widget.title),
                ),
              );
            },
          ),
          IconButton(
            icon: _isLoadingHabitState 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_habitIcon),
            tooltip: _habitTooltip,
            onPressed: _isLoadingHabitState ? null : _cycleHabitState,
          ),
        ],
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
        child: (kIsWeb && _showNotes) ? SizedBox.shrink() : _webIframeView,
      ),
    );
  }
}

//--------note page
class NotesPage extends StatefulWidget {
  final String title;
  final String habitId;
  final VoidCallback? onClose;

  const NotesPage({
    super.key, 
    required this.title, 
    required this.habitId,
    this.onClose
  });

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Map<String, String> notesMap = {}; // Map from username to notes
  Set<String> allMembersSet = {}; // Store all members
  Map<String, TextEditingController> controllersMap = {}; // Controllers for each member
  Map<String, bool> notesChangedMap = {}; // Track changes for each member
  bool _isLoading = true;
  String? _savingUsername; // Track which user's notes are being saved
  String? _selectedMember; // Currently selected member to view/edit

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in controllersMap.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateNotesOnServer(String username, String newNote) async {
    setState(() {
      _savingUsername = username;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$apiBase/updatenote?habitid=${Uri.encodeQueryComponent(widget.habitId)}&notes=${Uri.encodeQueryComponent(newNote)}&token=${Uri.encodeQueryComponent(token)}');
    final resp = await safeHttpGet(url);
    if (resp != null && resp.statusCode == 200 && (jsonDecode(resp.body)['status'] == 'ok')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notes saved successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        notesChangedMap[username] = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notes'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _savingUsername = null;
    });
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // First, get the habit data to find owner and member
    final habitUrl = Uri.parse('$apiBase/readhabit?token=${Uri.encodeQueryComponent(token)}');
    final habitResponse = await safeHttpGet(habitUrl);
    
    Set<String> membersFromHabit = {};
    if (habitResponse != null && habitResponse.statusCode == 200) {
      final habitData = jsonDecode(habitResponse.body);
      if (habitData['status'] == 'ok') {
        final List<dynamic> habits = (habitData['data'] ?? []) as List<dynamic>;
        for (final habit in habits) {
          final h = habit as Map<String, dynamic>;
          if (h['id']?.toString() == widget.habitId) {
            // Add owner
            final owner = h['username']?.toString() ?? '';
            if (owner.isNotEmpty) {
              membersFromHabit.add(owner);
            }
            // Add member
            final member = h['member']?.toString() ?? '';
            if (member.isNotEmpty) {
              membersFromHabit.add(member);
            }
            break;
          }
        }
      }
    }

    // Then get all notes
    final url = Uri.parse('$apiBase/readnote?habitid=${Uri.encodeQueryComponent(widget.habitId)}&token=${Uri.encodeQueryComponent(token)}');
    final response = await safeHttpGet(url);

    final Map<String, String> notes = {};
    final Set<String> membersFromNotes = {};
    
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final username = m['username']?.toString() ?? '';
          final note = m['notes']?.toString() ?? '';
          if (username.isNotEmpty) {
            membersFromNotes.add(username);
            notes[username] = note;
          }
        }
      }
    }

    // Combine members from habit and notes
    final allMembers = {...membersFromHabit, ...membersFromNotes};
    
    // Create controllers for all members
    final Map<String, TextEditingController> controllers = {};
    final Map<String, bool> changedMap = {};
    for (final member in allMembers) {
      controllers[member] = TextEditingController(text: notes[member] ?? '');
      changedMap[member] = false;
    }

    // Set selected member (default to current user, or first member)
    final currentUsername = prefs.getString('loggedInUsername') ?? 'guest';
    final selectedMember = allMembers.contains(currentUsername) ? currentUsername : (allMembers.isNotEmpty ? allMembers.first : null);
    
    setState(() {
      notesMap = notes;
      allMembersSet = allMembers;
      controllersMap = controllers;
      notesChangedMap = changedMap;
      _selectedMember = selectedMember;
      _isLoading = false;
    });
  }
  
  List<String> _getAllMembers() {
    return allMembersSet.toList()..sort();
  }

  Widget _buildNotesView(String member, String currentUsername) {
    final isCurrentUser = member == currentUsername;
    final controller = controllersMap[member];
    final isSaving = _savingUsername == member;
    final hasChanges = notesChangedMap[member] == true;
    
    if (controller == null) {
      return Center(
        child: Text(
          'Loading notes...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member name header
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  member,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentUser ? Colors.blue : Colors.black87,
                  ),
                ),
                if (isCurrentUser && hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '(unsaved)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            // Notes text field
            TextField(
              controller: controller,
              maxLines: null,
              enabled: isCurrentUser && !_isLoading && !isSaving,
              readOnly: !isCurrentUser, // Read-only for other users
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notes',
                hintText: isCurrentUser 
                    ? 'Write your notes here...' 
                    : 'No notes yet',
                filled: !isCurrentUser,
                fillColor: Colors.grey[100],
              ),
              onChanged: isCurrentUser ? (value) {
                setState(() {
                  notesChangedMap[member] = true;
                });
              } : null,
            ),
            // Save button (only for current user)
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: (isSaving || !hasChanges) ? null : () {
                        _updateNotesOnServer(member, controller.text);
                      },
                      child: isSaving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : Text('Save Notes'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if current user has unsaved changes
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('loggedInUsername') ?? 'guest';
    if (notesChangedMap[currentUsername] == true) {
      // Show confirmation dialog if there are unsaved changes
      return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Are you sure you want to leave without saving?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Stay on the page
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Leave without saving
                    },
                    child: const Text('Leave'),
                  ),
                ],
              );
            },
          ) ??
          false; // Default to false if dialog is dismissed
    }
    return true; // Allow back navigation if no unsaved changes
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('loggedInUsername') ?? 'guest'),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data ?? 'guest';
        final allMembers = _getAllMembers();
        
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.title} - Notes',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadNotes();
                  },
                  tooltip: 'Refresh Notes',
                ),
              ],
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : allMembers.isEmpty
                      ? Center(
                          child: Text(
                            'No members yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Members list at the top
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people, color: Theme.of(context).primaryColor),
                                      SizedBox(width: 8),
                                      Text(
                                        'Members',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: allMembers.map<Widget>((member) {
                                      final isCurrentUser = member == currentUsername;
                                      final isSelected = member == _selectedMember;
                                      final hasChanges = notesChangedMap[member] == true && isCurrentUser;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMember = member;
                                          });
                                        },
                                        child: Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                member,
                                                style: TextStyle(
                                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected 
                                                      ? (isCurrentUser ? Colors.blue : Colors.black87)
                                                      : (isCurrentUser ? Colors.blue[300] : Colors.grey[600]),
                                                ),
                                              ),
                                              if (hasChanges)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4.0),
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: 8,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          backgroundColor: isSelected
                                              ? (isCurrentUser 
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(0.2))
                                              : Colors.transparent,
                                          side: BorderSide(
                                            color: isSelected
                                                ? (isCurrentUser ? Colors.blue : Colors.grey)
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, thickness: 1),
                            // Selected member's notes below
                            Expanded(
                              child: _selectedMember == null
                                  ? Center(
                                      child: Text(
                                        'Select a member to view notes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  : _buildNotesView(_selectedMember!, currentUsername),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }
}

//Webview
class WebIframeView extends StatelessWidget {
  final String url;

  iframeMatcher() {
    return (context, element) => element.localName == 'iframe';
  }

  const WebIframeView({super.key, required this.url});

  // Helper method to validate and normalize URL
  String? _validateAndNormalizeUrl(String url) {
    if (url.isEmpty) return null;
    
    try {
      // Try parsing as-is first
      final uri = Uri.parse(url);
      // If it has a scheme, return as-is
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return url;
      }
      // If no scheme, try adding https://
      final normalized = Uri.parse('https://$url');
      if (normalized.hasAuthority) {
        return normalized.toString();
      }
      return null;
    } catch (e) {
      // If parsing fails, try adding https://
      try {
        final normalized = Uri.parse('https://$url');
        if (normalized.hasAuthority) {
          return normalized.toString();
        }
      } catch (_) {
        // If that also fails, URL is invalid
        return null;
      }
      return null;
    }
  }

  Widget _buildInvalidUrlView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Invalid URL',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'The URL "$url" is not valid.\nPlease check the habit link.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    final validUrl = _validateAndNormalizeUrl(url);
    
    if (validUrl == null) {
      return _buildInvalidUrlView();
    }

    if (kIsWeb) {
      // Web platform - use iframe
      final String viewId = 'iframe-${validUrl.hashCode}';
      registerIframe(viewId, validUrl);
      return HtmlElementView(viewType: viewId);
    } else if (Theme.of(context).platform == TargetPlatform.windows) {
      // Windows platform - try webview_windows, fallback if not available
      return _WindowsWebViewWrapper(url: validUrl);
    } else {
      // Mobile platforms (iOS/Android) - use webview_flutter package
      return _buildMobileWebView(validUrl);
    }
  }

  Widget _buildMobileWebView(String validUrl) {
    try {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(validUrl));
    return WebViewWidget(controller: controller);
    } catch (e) {
      // If loading fails, show error view
      return _buildInvalidUrlView();
    }
  }
}

// Windows WebView wrapper with fallback
class _WindowsWebViewWrapper extends StatefulWidget {
  final String url;

  const _WindowsWebViewWrapper({required this.url});

  @override
  _WindowsWebViewWrapperState createState() => _WindowsWebViewWrapperState();
}

class _WindowsWebViewWrapperState extends State<_WindowsWebViewWrapper> {
  bool _webViewAvailable = true;

  @override
  Widget build(BuildContext context) {
    if (_webViewAvailable) {
      return _WindowsWebView(url: widget.url, onError: () {
        setState(() {
          _webViewAvailable = false;
        });
      });
    } else {
      return _buildFallbackView();
    }
  }

  Widget _buildFallbackView() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'WebView not available on Windows',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'URL: ${widget.url}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Try to parse and validate URL
                  Uri uri;
                  try {
                    uri = Uri.parse(widget.url);
                    // If no scheme, try adding https://
                    if (!uri.hasScheme) {
                      uri = Uri.parse('https://${widget.url}');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invalid URL: ${widget.url}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening URL: Invalid URL format'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }
}

// Windows-specific WebView widget
class _WindowsWebView extends StatefulWidget {
  final String url;
  final VoidCallback onError;

  const _WindowsWebView({required this.url, required this.onError});

  @override
  _WindowsWebViewState createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<_WindowsWebView> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Try to use webview_windows package
      await _tryWebViewWindows();
    } catch (e) {
      print('Failed to initialize Windows WebView: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        widget.onError();
      }
    }
  }

  Future<void> _tryWebViewWindows() async {
    // This is a placeholder for the webview_windows implementation
    // You would need to properly import and use the package here
    // For now, we'll simulate an error to trigger the fallback
    throw Exception('webview_windows not properly configured');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading WebView...'),
          ],
        ),
      );
    }

    // This would be the actual WebView widget when properly configured
    return _buildErrorView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'WebView Error',
            style: TextStyle(fontSize: 18, color: Colors.orange),
          ),
          SizedBox(height: 8),
          Text(
            'URL: ${widget.url}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// AdminPage removed

// HabitHistoryPage
class HabitHistoryPage extends StatefulWidget {
  final String habitId;
  final String habitTitle;
  const HabitHistoryPage({super.key, required this.habitId, required this.habitTitle});

  @override
  _HabitHistoryPageState createState() => _HabitHistoryPageState();
}

class _HabitHistoryPageState extends State<HabitHistoryPage> {
  // Map from dateKey to list of user entries: {username: String, status: int}
  Map<String, List<Map<String, dynamic>>> habitMap = {};
  Set<String> allMembersSet = {}; // Store all members (from habit and history)
  bool isLoading = true;
  int centerOffset = 0;
  String? _loadingDateKey; // Add this to track which date is being updated
  String? _loadingUsername; // Track which username is being updated

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    // First, get the habit data to find owner and member
    final habitUrl = Uri.parse('$apiBase/readhabit?token=${Uri.encodeQueryComponent(token)}');
    final habitResponse = await safeHttpGet(habitUrl);
    
    Set<String> membersFromHabit = {};
    if (habitResponse != null && habitResponse.statusCode == 200) {
      final habitData = jsonDecode(habitResponse.body);
      if (habitData['status'] == 'ok') {
        final List<dynamic> habits = (habitData['data'] ?? []) as List<dynamic>;
        for (final habit in habits) {
          final h = habit as Map<String, dynamic>;
          if (h['id']?.toString() == widget.habitId) {
            // Add owner
            final owner = h['username']?.toString() ?? '';
            if (owner.isNotEmpty) {
              membersFromHabit.add(owner);
            }
            // Add member
            final member = h['member']?.toString() ?? '';
            if (member.isNotEmpty) {
              membersFromHabit.add(member);
            }
            break;
          }
        }
      }
    }
    
    // Then get history
    final url = Uri.parse('$apiBase/readhistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&token=${Uri.encodeQueryComponent(token)}');
    final response = await safeHttpGet(url);
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        // Group all entries by date (not filtered by username)
        final Map<String, List<Map<String, dynamic>>> map = {};
        final Set<String> membersFromHistory = {};
        
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final dateKey = m['historydate']?.toString() ?? '';
          final username = m['username']?.toString() ?? '';
          final status = int.tryParse(m['historystatus']?.toString() ?? '0') ?? 0;
          if (dateKey.isNotEmpty && username.isNotEmpty) {
            membersFromHistory.add(username);
            if (!map.containsKey(dateKey)) {
              map[dateKey] = [];
            }
            map[dateKey]!.add({
              'username': username,
              'status': status,
            });
          }
        }
        
        // Combine members from habit and history
        final allMembers = {...membersFromHabit, ...membersFromHistory};
        
        setState(() {
          habitMap = map;
          allMembersSet = allMembers;
          isLoading = false;
        });
      } else {
        setState(() {
          allMembersSet = membersFromHabit;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        allMembersSet = membersFromHabit;
        isLoading = false;
      });
    }
  }

  List<DateTime> getSevenDays() {
    final today = DateTime.now();
    final center = today.add(Duration(days: centerOffset));
    return List.generate(7, (i) => center.add(Duration(days: i - 3)));
  }

  static const List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Future<void> _setHabitStateForDate(DateTime date, int newState) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Find current user's existing state
    final currentEntries = habitMap[dateKey] ?? [];
    final currentUserEntry = currentEntries.firstWhere(
      (e) => e['username'] == username,
      orElse: () => {},
    );
    final previousState = currentUserEntry['status'] ?? 0;
    
    // Update the state immediately in the UI
    setState(() {
      if (!habitMap.containsKey(dateKey)) {
        habitMap[dateKey] = [];
      }
      // Update or add current user's entry
      final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
      if (index >= 0) {
        habitMap[dateKey]![index]['status'] = newState;
      } else {
        habitMap[dateKey]!.add({'username': username, 'status': newState});
      }
      _loadingDateKey = dateKey;
      _loadingUsername = username;
    });

    try {
      final url = Uri.parse(
        '$apiBase/updatehistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&historydate=$dateKey&historystatus=$newState&token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await safeHttpGet(url);
      if (response == null) {
        // Revert on network error
        final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
        if (index >= 0) {
          habitMap[dateKey]![index]['status'] = previousState;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _loadingDateKey = null;
          _loadingUsername = null;
        });
        return;
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 'ok') {
          // Revert on API error
          final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
          if (index >= 0) {
            habitMap[dateKey]![index]['status'] = previousState;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${data['message']?.toString() ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Reload to get latest data from server
          await _fetchHistory();
        }
      } else {
        // Revert on HTTP error
        final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
        if (index >= 0) {
          habitMap[dateKey]![index]['status'] = previousState;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit state. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Revert on exception
      final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
      if (index >= 0) {
        habitMap[dateKey]![index]['status'] = previousState;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state
      setState(() {
        _loadingDateKey = null;
        _loadingUsername = null;
      });
    }
  }
  
  // Get all unique usernames (from habit and history)
  List<String> _getAllMembers() {
    return allMembersSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('loggedInUsername') ?? 'guest'),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data ?? 'guest';
        final allMembers = _getAllMembers();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.habitTitle} - History',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _fetchHistory();
                },
                tooltip: 'Refresh History',
              ),
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    centerOffset -= 7;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    centerOffset += 7;
                  });
                },
              ),
            ],
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
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : allMembers.isEmpty
                    ? Center(
                        child: Text(
                          'No members yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: allMembers.map<Widget>((member) {
                            final isCurrentUser = member == currentUsername;
                            return Column(
                              children: [
                                // Member name section
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                                      SizedBox(width: 8),
                                      Text(
                                        member,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrentUser ? Colors.blue : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // History calendar for this member
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: getSevenDays().map((date) {
                                        int weekday = date.weekday % 7;
                                        final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                                        final entries = habitMap[dateKey] ?? [];
                                        final memberEntry = entries.firstWhere(
                                          (e) => e['username'] == member,
                                          orElse: () => {'username': member, 'status': 0},
                                        );
                                        final memberState = memberEntry['status'] ?? 0;
                                        
                                        final now = DateTime.now();
                                        final today = DateTime(now.year, now.month, now.day + 1);
                                        final isFuture = date.isAfter(today);
                                        final isLoading = _loadingDateKey == dateKey && _loadingUsername == member && isCurrentUser;
                                        
                                        IconData icon;
                                        Color color;
                                        if (memberState == 1) {
                                          icon = Icons.check_box;
                                          color = Colors.green;
                                        } else if (memberState == -1) {
                                          icon = Icons.close;
                                          color = Colors.red;
                                        } else {
                                          icon = Icons.check_box_outline_blank;
                                          color = Colors.grey;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          child: GestureDetector(
                                            onTap: (isFuture || isLoading || !isCurrentUser) ? null : () {
                                              // Cycle current user's state (only if it's the current user)
                                              int newState;
                                              if (memberState == 0) {
                                                newState = 1;
                                              } else if (memberState == 1) {
                                                newState = -1;
                                              } else {
                                                newState = 0;
                                              }
                                              _setHabitStateForDate(date, newState);
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(weekDays[weekday], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                SizedBox(height: 4),
                                                Text('${date.day}/${date.month}', style: TextStyle(fontSize: 14)),
                                                SizedBox(height: 8),
                                                isLoading
                                                    ? SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                                        ),
                                                      )
                                                    : Icon(
                                                        icon,
                                                        color: isFuture ? Colors.grey[300] : color,
                                                        size: 24,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Divider(height: 1, thickness: 1),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        );
      },
    );
  }
}

class HtmlContentPage extends StatelessWidget {
  final String htmlData;
  const HtmlContentPage({super.key, required this.htmlData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HTML Content')),
      body: SingleChildScrollView(
        child: Html(
          data: htmlData,
        ),
      ),
    );
  }
}

// Add new EditHabitPage class
class EditHabitPage extends StatefulWidget {
  final String habitId;
  final String currentTitle;
  final String currentLink;

  const EditHabitPage({
    super.key,
    required this.habitId,
    required this.currentTitle,
    required this.currentLink,
  });

  @override
  _EditHabitPageState createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  bool _isLoading = false;
  bool _isLinkValid = true;
  bool _isTitleValid = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _linkController = TextEditingController(text: widget.currentLink);
    _isLinkValid = DialogUtils.isValidUrl(widget.currentLink);
    _isTitleValid = widget.currentTitle.isNotEmpty;
  }

  bool get _canSave {
    return _isTitleValid && 
           (_linkController.text.isEmpty || _isLinkValid) && 
           !_isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Habit',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _isLoading ? null : _deleteHabit,
            tooltip: 'Delete Habit',
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g., Read Books',
                  border: OutlineInputBorder(),
                  errorText: !_isTitleValid ? 'Please enter a title' : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _isTitleValid = value.isNotEmpty;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Habit Link (Optional)',
                  hintText: 'e.g., https://example.com',
                  border: OutlineInputBorder(),
                  errorText: _linkController.text.isNotEmpty && !_isLinkValid
                      ? 'Please enter a valid URL with proper domain (e.g., https://example.com)'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _isLinkValid = DialogUtils.isValidUrl(value);
                  });
                },
              ),
              SizedBox(height: 32),
              _isLoading 
                ? Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Saving changes...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomButton(
                    text: 'Save Changes',
                    onPressed: _canSave ? () => _saveChanges() : null,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate title
    if (!_isTitleValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate URL
    if (_linkController.text.isNotEmpty && !_isLinkValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL with proper domain (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If link is empty, show confirmation dialog
    if (_linkController.text.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Update title
    final updateNameUrl = Uri.parse(
      '$apiBase/updatehabit?id=${Uri.encodeQueryComponent(widget.habitId)}&newname=name&newdata=${Uri.encodeQueryComponent(_titleController.text)}&token=${Uri.encodeQueryComponent(token)}',
    );
    final updateNameResp = await safeHttpGet(updateNameUrl);
    if (updateNameResp == null || updateNameResp.statusCode != 200) {
      final errorMsg = updateNameResp != null
          ? (jsonDecode(updateNameResp.body)['message']?.toString() ?? 'Failed to update title')
          : 'Network error. Please check your connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final updateNameData = jsonDecode(updateNameResp.body);
    if (updateNameData['status'] != 'ok') {
      final errorMsg = updateNameData['message']?.toString() ?? 'Failed to update title';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Update URL if not empty
    if (_linkController.text.isNotEmpty) {
      final updateUrlUrl = Uri.parse(
        '$apiBase/updatehabit?id=${Uri.encodeQueryComponent(widget.habitId)}&newname=url&newdata=${Uri.encodeQueryComponent(_linkController.text)}&token=${Uri.encodeQueryComponent(token)}',
      );
      final updateUrlResp = await safeHttpGet(updateUrlUrl);
      if (updateUrlResp == null || updateUrlResp.statusCode != 200) {
        final errorMsg = updateUrlResp != null
            ? (jsonDecode(updateUrlResp.body)['message']?.toString() ?? 'Failed to update link')
            : 'Network error. Please check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final updateUrlData = jsonDecode(updateUrlResp.body);
      if (updateUrlData['status'] != 'ok') {
        final errorMsg = updateUrlData['message']?.toString() ?? 'Failed to update link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

      // Pop back to previous page with updated data
      Navigator.of(context).pop({
        'title': _titleController.text,
        'link': _linkController.text,
      });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteHabit() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habit'),
        content: Text('Are you sure you want to delete this habit? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/deletehabit?id=${Uri.encodeQueryComponent(widget.habitId)}&token=$token');
    await safeHttpGet(url);

    // Pop back to previous page with delete flag
    Navigator.of(context).pop({'deleted': true});

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}

// Add this class after imports
class DialogUtils {
  static bool isValidUrl(String url) {
    if (url.isEmpty) return true; // Allow empty URLs
    try {
      final uri = Uri.parse(url);
      // Check for valid scheme (http or https)
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      
      // Check for valid domain (must have at least one dot and valid TLD)
      if (!uri.host.contains('.')) return false;
      
      // Check for valid path (optional)
      // Check for valid authority (domain)
      if (uri.authority.isEmpty) return false;
      
      // Additional check for common invalid patterns
      if (uri.host.endsWith('.') || uri.host.startsWith('.')) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> showLinkValidationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Link'),
          content: Text('Please enter a valid URL with proper domain (e.g., https://example.com)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Continue Anyway'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
