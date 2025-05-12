import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer
import 'package:http/http.dart' as http;
import 'dart:convert';

//------------ Conditional imports
import 'platform_mobile.dart' if (dart.library.html) 'platform_web.dart';

void main() {
  //runAppEntry();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
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
                    color: Colors.blueGrey[900],
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
                    backgroundColor: Colors.blueGrey,
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      backgroundColor: Colors.blueGrey,
                      shadowColor: Colors.black.withOpacity(0.5),
                      elevation: 10,
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                if (loggedInUser != 'guest')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('loggedInUsername'); // Clear the logged-in user
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => SplashScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        backgroundColor: Colors.blueGrey,
                        shadowColor: Colors.black.withOpacity(0.5),
                        elevation: 10,
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.5,
                        ),
                      ),
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
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.5,
                        ),
                      ),
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

    // Proceed with signup
    final signupResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': '''
          INSERT INTO habitmultiplayer (username, password, notes)
          VALUES ('$username', '$password', '{}')
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        backgroundColor: Colors.blueGrey,
                        shadowColor: Colors.black.withOpacity(0.5),
                        elevation: 10,
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 22,
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

class _HomePageState extends State<HomePage> {
  String loggedInUser = '';

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

  bool _isDarkMode = true; // Add this state variable

  Color _colorFromThirdLetter(String title) {
    return _isDarkMode ? _colorFromThirdLetterDarkMode(title) : _colorFromThirdLetterLightMode(title);
  }

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getLoggedInUser(); // Reload username every time dependencies change
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUser = prefs.getString('loggedInUsername') ?? 'guest';
    });
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
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
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
          ),
        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding to the grid
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of columns
                          crossAxisSpacing: 20, // Horizontal spacing
                          mainAxisSpacing: 20, // Vertical spacing
                        ),
                        itemCount: buttonData.length, // Dynamically set based on buttonData
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.all(8.0), // Add margin around each button
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => InsidePage(
                                      title: buttonData[index]['title']!,
                                      link: buttonData[index]['link']!,
                                    ),
                                  ),
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
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(
              //         builder: (context) => HtmlContentPage(
              //           htmlData: '''
              //             <h1>Hello World</h1>
              //             <p>This is <b>HTML</b> rendered in Flutter!</p>
              //             <ul>
              //               <li>Item 1</li>
              //               <li>Item 2</li>
              //             </ul>
              //           '''.replaceAll("\n", ""),
              //         ),
              //       ),
              //     );
              //   },
              //   child: Text('Try HTML Content'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

//--------- InsidePage with Tab Navigation
class InsidePage extends StatefulWidget {
  final String title;
  final String link;

  const InsidePage({super.key, required this.title, required this.link});

  @override
  _InsidePageState createState() => _InsidePageState();
}

class _InsidePageState extends State<InsidePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final WebIframeView _webIframeView;
  bool _showNotes = false;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7), // Change background color to a whity orange
      
        actions: [
          IconButton(
            icon: Icon(Icons.note),
            tooltip: 'Open Notes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotesPage(title: widget.title),
                ),
              );
              // if (kIsWeb) {
              //   setState(() {
              //     _showNotes = true;
              //   });
              //   showModalBottomSheet(
              //     context: context,
              //     isScrollControlled: true,
              //     builder: (context) => FractionallySizedBox(
              //       heightFactor: 0.85,
              //       child: NotesPage(title: widget.title, onClose: () {
              //         setState(() {
              //           _showNotes = false;
              //         });
              //         Navigator.of(context).pop();
              //       }),
              //     ),
              //   ).whenComplete(() {
              //     setState(() {
              //       _showNotes = false;
              //     });
              //   });
              // } else {
              //   showModalBottomSheet(
              //     context: context,
              //     isScrollControlled: true,
              //     builder: (context) => FractionallySizedBox(
              //       heightFactor: 0.85,
              //       child: NotesPage(title: widget.title),
              //     ),
              //   );
              // }
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
  final VoidCallback? onClose;

  const NotesPage({super.key, required this.title, this.onClose});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late TextEditingController _notesController;
  bool _isNotesChanged = false; // Flag to track unsaved changes
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    // Load saved notes
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
        SELECT notes FROM habitmultiplayer
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

      // Update the specific note for the current habit title
      notesMap[widget.title] = newNote;

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
        SELECT notes FROM habitmultiplayer
        WHERE username = '$username'
      ''',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final notesJson = results[0]['notes'] ?? '{}';

        try {
          final decoded = jsonDecode(notesJson);
          _notesController.text = decoded[widget.title] ?? '';
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

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final notes = _notesController.text;

    await prefs.setString('notes_${username}_${widget.title}', notes);
    await _updateNotesOnServer(notes); // Save the notes to server
    setState(() {
      _isNotesChanged = false; // Reset the flag after saving
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
                      onPressed: _isLoading ? null : _saveNotes,
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

  const WebIframeView({Key? key, required this.url}) : super(key: key);

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
  const HabitHistoryPage({Key? key, required this.habitTitle}) : super(key: key);

  @override
  _HabitHistoryPageState createState() => _HabitHistoryPageState();
}

class _HabitHistoryPageState extends State<HabitHistoryPage> {
  Map<String, int> habitMap = {};
  bool isLoading = true;
  int centerOffset = 0; // 0 = today, -1 = previous, +1 = next, etc.

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
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

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

    setState(() {
      habitMap[dateKey] = newState;
    });
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(weekDays[weekday], style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: isFuture ? null : () {
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
                              child: Icon(icon, color: isFuture ? Colors.grey[300] : color, size: 40),
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
