import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

//------------ Conditional imports
import 'platform_mobile.dart' if (dart.library.html) 'platform_web.dart';

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

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
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
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AdminPage()),
                        );
                      },
                      child: Text('Admin Page'),
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

    final url = Uri.parse(
      'https://afwanproductions.pythonanywhere.com/api/executejsonv2',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
        SELECT * FROM habitmultiplayer 
        WHERE username = '$username' AND password = '$password'
      ''',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];

      if (results != null && results.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInUsername', username);

        setState(() {
          _response = 'Login successful! Welcome, $username.';
        });

        // Navigate to AdminPage if admin, else SplashScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
        
      } else {
        setState(() {
          _response = 'Invalid username or password.';
        });
      }
    } else {
      setState(() {
        _response = 'Server Error: ${response.statusCode}';
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

    final url = Uri.parse(
      'https://afwanproductions.pythonanywhere.com/api/executejsonv2',
    );

    // Check if user already exists
    final checkResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT * FROM habitmultiplayer WHERE username = '$username'
        ''',
      }),
    );

    final checkData = jsonDecode(checkResponse.body);
    final existingUsers = checkData['results'];

    if (existingUsers != null && existingUsers.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _response = 'Username already exists. Try a different one.';
      });
      return;
    }

    // Create default habits map
    final defaultHabits = {
      DateTime.now().millisecondsSinceEpoch.toString(): {
        'title': 'Baca Al-quran',
        'link': 'https://quran.com',
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      (DateTime.now().millisecondsSinceEpoch + 1).toString(): {
        'title': 'Buat app',
        'link': 'https://flutter.dev',
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      (DateTime.now().millisecondsSinceEpoch + 2).toString(): {
        'title': 'Workout',
        'link': 'https://www.nerdfitness.com/wp-content/uploads/2021/02/Beginner-Bodyweight-Workout-Infographic-scaled.jpg',
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      (DateTime.now().millisecondsSinceEpoch + 3).toString(): {
        'title': 'Jog',
        'link': 'https://www.finishline.com/',
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      (DateTime.now().millisecondsSinceEpoch + 4).toString(): {
        'title': 'Meditasi',
        'link': 'https://www.meditation.com',
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
    };

    // Convert habits to JSON string and escape for SQL
    final habitsJson = jsonEncode(defaultHabits)
        .replaceAll(r'\', r'\\')
        .replaceAll("'", "''");

    // Proceed with signup including default habits
    final signupResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          INSERT INTO habitmultiplayer (username, password, notes, habits)
          VALUES ('$username', '$password', '{}', '$habitsJson')
        ''',
      }),
    );

    if (signupResponse.statusCode == 200) {
      setState(() {
        _response = 'Signup successful! You can now log in.';
      });

      // Optional: Navigate to login after short delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Go back to LoginPage
      });
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
    if (state == AppLifecycleState.resumed) {
      _loadHabits(); // Reload habits when app is resumed
    }
  }

  Future<void> _onRefresh() async {
    await _loadHabits();
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
                  await _addNewHabit(
                    _habitTitleController.text,
                    _habitLinkController.text,
                  );
                  Navigator.of(context).pop();
                  _habitTitleController.clear();
                  _habitLinkController.clear();
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

  Future<void> _addNewHabit(String title, String link) async {
    if (link.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return;
    } else if (!DialogUtils.isValidUrl(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    // First, get the current habits
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT habits FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    Map<String, dynamic> habitsMap = {};
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        try {
          final habitsText = results[0]['habits'];
          if (habitsText != null && habitsText.isNotEmpty) {
            habitsMap = jsonDecode(habitsText);
          }
        } catch (_) {
          habitsMap = {};
        }
      }
    }

    // Generate a unique ID for the new habit
    final habitId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add the new habit with ID
    habitsMap[habitId] = {
      'title': title,
      'link': link,
      'created_at': DateTime.now().toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
    };

    // Convert to string and escape for SQL
    final habitsText = jsonEncode(habitsMap)
        .replaceAll(r'\', r'\\')
        .replaceAll("'", "''");

    // Save to server
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          UPDATE habitmultiplayer
          SET habits = '$habitsText'
          WHERE username = '$username'
        ''',
      }),
    );

    // Update the local buttonData
    setState(() {
      buttonData.add({
        'id': habitId,
        'title': title,
        'link': link.isEmpty ? 'https://example.com' : link,
      });
    });
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
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    // First, get the current habits
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT habits FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    Map<String, dynamic> habitsMap = {};
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        try {
          final habitsText = results[0]['habits'];
          if (habitsText != null && habitsText.isNotEmpty) {
            habitsMap = jsonDecode(habitsText);
          }
        } catch (_) {
          habitsMap = {};
        }
      }
    }

    // Update the habit
    if (habitsMap.containsKey(habitId)) {
      final habit = habitsMap[habitId];
      habit['title'] = newTitle;
      habit['link'] = newLink;
      habit['last_updated'] = DateTime.now().toIso8601String();

      // Convert to string and escape for SQL
      final habitsText = jsonEncode(habitsMap)
          .replaceAll(r'\', r'\\')
          .replaceAll("'", "''");

      // Save to server
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
            UPDATE habitmultiplayer
            SET habits = '$habitsText'
            WHERE username = '$username'
          ''',
        }),
      );

      // Update the local buttonData
      setState(() {
        final index = buttonData.indexWhere((item) => item['id'] == habitId);
        if (index != -1) {
          buttonData[index]['title'] = newTitle;
          buttonData[index]['link'] = newLink.isEmpty ? 'https://example.com' : newLink;
        }
      });
    }
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
            SELECT habits FROM habitmultiplayer
            WHERE username = '$username'
          ''',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          try {
            final habitsText = results[0]['habits'];
            if (habitsText != null && habitsText.isNotEmpty) {
              final habitsMap = jsonDecode(habitsText);
              if (mounted) {
                setState(() {
                  buttonData.clear();
                  habitsMap.forEach((id, data) {
                    buttonData.add({
                      'id': id,
                      'title': data['title'] ?? '',
                      'link': data['link'] ?? 'https://example.com',
                    });
                  });
                });
              }
            }
          } catch (e) {
            print('Error parsing habits: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading habits: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                  padding: const EdgeInsets.only(bottom: 32.0),
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WebIframeView _webIframeView;
  final bool _showNotes = false;
  int _habitState = 0; // 0: blank, 1: ticked, 2: X

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webIframeView = WebIframeView(url: widget.link);
    _loadHabitState();
  }

  Future<void> _loadHabitState() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT calendar_tick FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final tickJson = results[0]['calendar_tick'] ?? '{}';
        try {
          final decoded = jsonDecode(tickJson);
          setState(() {
            _habitState = decoded[widget.title]?[dateKey] ?? 0;
          });
        } catch (_) {
          setState(() {
            _habitState = 0;
          });
        }
      }
    }
  }

  Future<void> _cycleHabitState() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Get current calendar_tick JSON
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT calendar_tick FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    Map<String, dynamic> tickMap = {};
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        try {
          tickMap = jsonDecode(results[0]['calendar_tick'] ?? '{}');
        } catch (_) {
          tickMap = {};
        }
      }
    }

    // Update the tick state for this habit and date
    int newState;
    if (_habitState == 0) {
      newState = 1;
    } else if (_habitState == 1) {
      newState = -1;
    } else {
      newState = 0;
    }
    if (!tickMap.containsKey(widget.title)) tickMap[widget.title] = {};
    tickMap[widget.title][dateKey] = newState;

    // Save to server
    final updatedJson = jsonEncode(tickMap).replaceAll(r'\', r'\\').replaceAll("'", "''");
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          UPDATE habitmultiplayer
          SET calendar_tick = '$updatedJson'
          WHERE username = '$username'
        ''',
      }),
    );

    setState(() {
      _habitState = newState;
    });
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
                  builder: (context) => HabitHistoryPage(habitTitle: widget.title),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_habitIcon),
            tooltip: _habitTooltip,
            onPressed: _cycleHabitState,
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
  late TextEditingController _notesController;
  bool _isNotesChanged = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateNotesOnServer(String newNote) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';

    final url = Uri.parse(
      'https://afwanproductions.pythonanywhere.com/api/executejsonv2',
    );

    // First, get the existing notes JSON
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
        SELECT notes, habits FROM habitmultiplayer
        WHERE username = '$username'
      ''',
      }),
    );

    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      Map<String, dynamic> notesMap = {};

      if (results != null && results.isNotEmpty) {
        try {
          notesMap = jsonDecode(results[0]['notes'] ?? '{}');
        } catch (_) {
          notesMap = {};
        }
      }

      // Check if there are notes under the old title-based key
      final oldNotes = notesMap[widget.title];
      
      // Update notes using the habit ID as the key
      notesMap[widget.habitId] = newNote;
      
      // If there were old notes and they're different from the new notes,
      // keep them for backward compatibility
      if (oldNotes != null && oldNotes != newNote) {
        notesMap[widget.title] = oldNotes;
      }

      // Encode the updated map as a valid JSON string
      final updatedJson = jsonEncode(notesMap);

      // Escape the backslashes and other special characters in the JSON string
      final escapedJson = updatedJson
          .replaceAll(r'\', r'\\')
          .replaceAll("'", "''");

      // Now update the full JSON back to the server
      final updateResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
          UPDATE habitmultiplayer
          SET notes = '$escapedJson'
          WHERE username = '$username'
        ''',
        }),
      );

      if (updateResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes uploaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Failed to update notes on server: ${updateResponse.body}');
      }
    } else {
      print('Failed to load notes before updating: ${getResponse.body}');
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';

    final url = Uri.parse(
      'https://afwanproductions.pythonanywhere.com/api/executejsonv2',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
        SELECT notes, habits FROM habitmultiplayer
        WHERE username = '$username'
      ''',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final notesJson = results[0]['notes'] ?? '{}';
        final habitsJson = results[0]['habits'] ?? '{}';

        try {
          final decodedNotes = jsonDecode(notesJson);
          final decodedHabits = jsonDecode(habitsJson);
          Map<String, dynamic> newNotesMap = {};

          // First try to get notes by ID
          if (decodedNotes.containsKey(widget.habitId)) {
            _notesController.text = decodedNotes[widget.habitId];
          } 
          // If no ID-based notes, check for title-based notes and migrate them
          else if (decodedNotes.containsKey(widget.title)) {
            final titleBasedNote = decodedNotes[widget.title];
            _notesController.text = titleBasedNote;
            
            // Migrate the note to ID-based storage
            newNotesMap = Map<String, dynamic>.from(decodedNotes);
            newNotesMap[widget.habitId] = titleBasedNote;
            
            // Update the server with the migrated notes
            final updatedJson = jsonEncode(newNotesMap)
                .replaceAll(r'\', r'\\')
                .replaceAll("'", "''");
                
            await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'password': 'afwan',
                'query': '''
                  UPDATE habitmultiplayer
                  SET notes = '$updatedJson'
                  WHERE username = '$username'
                ''',
              }),
            );
          } else {
            _notesController.text = '';
          }
        } catch (e) {
          print('Failed to parse notes JSON: $e');
          _notesController.text = '';
        }
      }
    } else {
      print('Failed to fetch notes from server: ${response.body}');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _onWillPop() async {
    if (_isNotesChanged) {
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
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back navigation
      child: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${widget.title} - Notes',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7), // Change background color to a whity orange
      
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
                Colors.white.withOpacity(0.8), // Adjust opacity here (0.0 to 1.0)
                BlendMode.softLight, // Try different blend modes: overlay, softLight, hardLight, etc.
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16), // Spacing
               Expanded(
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Notes',
                      hintText: 'Write your notes here...',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isNotesChanged = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16), // Spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateNotesOnServer(_notesController.text),
                      child: const Text('Save Notes'),
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
}

//Webview
class WebIframeView extends StatelessWidget {
  final String url;

  iframeMatcher() {
    return (context, element) => element.localName == 'iframe';
  }

  const WebIframeView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final String viewId = 'iframe-${url.hashCode}';
      registerIframe(viewId, url);
      return HtmlElementView(viewType: viewId);
    } else {
      final controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(url));
      return WebViewWidget(controller: controller);
    }
  }
}

// AdminPage
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': 'SELECT * FROM habitmultiplayer',
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      setState(() {
        users = results.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Admin Panel')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (users.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Admin Panel')),
        body: Center(child: Text('No data found.')),
      );
    }
    final columns = users[0].keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
            rows: users.map((row) {
              return DataRow(
                cells: columns.map((col) => DataCell(Text('${row[col]}'))).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// HabitHistoryPage
class HabitHistoryPage extends StatefulWidget {
  final String habitTitle;
  const HabitHistoryPage({super.key, required this.habitTitle});

  @override
  _HabitHistoryPageState createState() => _HabitHistoryPageState();
}

class _HabitHistoryPageState extends State<HabitHistoryPage> {
  Map<String, int> habitMap = {};
  bool isLoading = true;
  int centerOffset = 0;
  String? _loadingDateKey; // Add this to track which date is being updated

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT calendar_tick FROM habitmultiplayer
          WHERE username = '$username'
        '''
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final tickJson = results[0]['calendar_tick'] ?? '{}';
        try {
          final decoded = jsonDecode(tickJson);
          setState(() {
            habitMap = Map<String, int>.from(decoded[widget.habitTitle] ?? {});
            isLoading = false;
          });
        } catch (_) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  List<DateTime> getSevenDays() {
    final today = DateTime.now();
    final center = today.add(Duration(days: centerOffset));
    return List.generate(7, (i) => center.add(Duration(days: i - 3)));
  }

  static const List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Future<void> _setHabitStateForDate(DateTime date, int newState) async {
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final previousState = habitMap[dateKey] ?? 0;  // Store the previous state
    
    // Update the state immediately in the UI
    setState(() {
      habitMap[dateKey] = newState;
      _loadingDateKey = dateKey;
    });

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    try {
      // Get current calendar_tick JSON
      final getResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
            SELECT calendar_tick FROM habitmultiplayer
            WHERE username = '$username'
          '''
        }),
      );

      Map<String, dynamic> tickMap = {};
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          try {
            tickMap = jsonDecode(results[0]['calendar_tick'] ?? '{}');
          } catch (_) {
            tickMap = {};
          }
        }
      }

      if (!tickMap.containsKey(widget.habitTitle)) tickMap[widget.habitTitle] = {};
      tickMap[widget.habitTitle][dateKey] = newState;

      // Save to server
      final updatedJson = jsonEncode(tickMap).replaceAll(r'\', r'\\').replaceAll("'", "''");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
            UPDATE habitmultiplayer
            SET calendar_tick = '$updatedJson'
            WHERE username = '$username'
          '''
        }),
      );
    } catch (e) {
      // If there's an error, revert the state
      setState(() {
        habitMap[dateKey] = previousState; // Revert to previous state
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update habit state. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state regardless of success or failure
      setState(() {
        _loadingDateKey = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.habitTitle} - History',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7), // Change background color to a whity orange
      
        actions: [
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
              Colors.white.withOpacity(0.8), // Adjust opacity here (0.0 to 1.0)
              BlendMode.softLight, // Try different blend modes: overlay, softLight, hardLight, etc.
            ),
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: getSevenDays().map((date) {
                      int weekday = date.weekday % 7;
                      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      final state = habitMap[dateKey] ?? 0;
                      IconData icon;
                      Color color;
                      if (state == 1) {
                        icon = Icons.check_box;
                        color = Colors.green;
                      } else if (state == -1) {
                        icon = Icons.close;
                        color = Colors.red;
                      } else {
                        icon = Icons.check_box_outline_blank;
                        color = Colors.grey;
                      }
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day+1);
                      final isFuture = date.isAfter(today);
                      final isLoading = _loadingDateKey == dateKey;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(weekDays[weekday], style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: isFuture || isLoading ? null : () {
                                int newState;
                                if (state == 0) {
                                  newState = 1;
                                } else if (state == 1) {
                                  newState = -1;
                                } else {
                                  newState = 0;
                                }
                                _setHabitStateForDate(date, newState);
                              },
                              child: isLoading
                                  ? SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    )
                                  : Icon(icon, color: isFuture ? Colors.grey[300] : color, size: 40),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
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
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    // First, get the current habits
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT habits FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    Map<String, dynamic> habitsMap = {};
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        try {
          final habitsText = results[0]['habits'];
          if (habitsText != null && habitsText.isNotEmpty) {
            habitsMap = jsonDecode(habitsText);
          }
        } catch (_) {
          habitsMap = {};
        }
      }
    }

    // Update the habit
    if (habitsMap.containsKey(widget.habitId)) {
      final habit = habitsMap[widget.habitId];
      habit['title'] = _titleController.text;
      habit['link'] = _linkController.text;
      habit['last_updated'] = DateTime.now().toIso8601String();

      // Convert to string and escape for SQL
      final habitsText = jsonEncode(habitsMap)
          .replaceAll(r'\', r'\\')
          .replaceAll("'", "''");

      // Save to server
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': 'afwan',
          'query': '''
            UPDATE habitmultiplayer
            SET habits = '$habitsText'
            WHERE username = '$username'
          ''',
        }),
      );

      // Pop back to previous page with updated data
      Navigator.of(context).pop({
        'title': _titleController.text,
        'link': _linkController.text,
      });
    }

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
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');

    // First, get the current habits
    final getResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          SELECT habits FROM habitmultiplayer
          WHERE username = '$username'
        ''',
      }),
    );

    Map<String, dynamic> habitsMap = {};
    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        try {
          final habitsText = results[0]['habits'];
          if (habitsText != null && habitsText.isNotEmpty) {
            habitsMap = jsonDecode(habitsText);
          }
        } catch (_) {
          habitsMap = {};
        }
      }
    }

    // Remove the habit
    habitsMap.remove(widget.habitId);

    // Convert to string and escape for SQL
    final habitsText = jsonEncode(habitsMap)
        .replaceAll(r'\', r'\\')
        .replaceAll("'", "''");

    // Save to server
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          UPDATE habitmultiplayer
          SET habits = '$habitsText'
          WHERE username = '$username'
        ''',
      }),
    );

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
