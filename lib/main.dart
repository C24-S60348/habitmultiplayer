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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Habit Multiplayer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32), // Spacing
                Text(
                  'Logged in as: $loggedInUser',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              SizedBox(height: 32), // Spacing
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomePage()));
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(120),
                ),
                child: Text('Start', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoginPage(), // Assuming LoginPage is defined
                    ),
                  );
                },
                child: Text('Go to Login Page'),
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('loggedInUsername'); // Clear the logged-in user
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
              ),
            ],
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

        // Navigate to HomePage or next screen
        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        });
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
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child:
            _isLoading
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
                        onPressed: _fetchData,
                        child: Text('Login'),
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
      appBar: AppBar(title: Text('Signup Page')),
      body: Center(
        child:
            _isLoading
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
                        child: Text('Sign Up'),
                      ),
                      SizedBox(height: 20),
                      Text(_response),
                    ],
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
  {'title': 'Jog', 'link': 'https://www.jogging.com'},
  {'title': 'Meditasi', 'link': 'https://www.meditation.com'},
];

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete All',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ), // Padding left and right
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    crossAxisSpacing: 20, // Horizontal spacing
                    mainAxisSpacing: 20, // Vertical spacing
                  ),
                  itemCount:
                      buttonData.length, // Dynamically set based on buttonData
                  itemBuilder: (context, index) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => InsidePage(
                                  title: buttonData[index]['title']!,
                                  link: buttonData[index]['link']!,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(40),
                      ),
                      child: Text(
                        buttonData[index]['title']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webIframeView = WebIframeView(
      url: widget.link,
    ); // Initialize WebIframeView
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
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        toolbarHeight: 70.0, // Increase the height of the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0), // Smaller height
          child: TabBar(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.web),
                    SizedBox(width: 8.0),
                    Text('Web'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note),
                    SizedBox(width: 8.0),
                    Text('Notes'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _webIframeView,

          NotesPage(title: widget.title), // NotesPage for the second tab
        ],
      ),
    );
  }
}

//--------note page
class NotesPage extends StatefulWidget {
  final String title;

  const NotesPage({super.key, required this.title});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late TextEditingController _notesController;
  late ValueNotifier<int> _timerNotifier;
  Timer? _timer;
  bool _isNotesChanged = false; // Flag to track unsaved changes

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _timerNotifier = ValueNotifier<int>(0);

    // Load saved notes
    _loadNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timerNotifier.dispose();
    _timer?.cancel();
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

  void _startTimer() {
    _timerNotifier.value = 1;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timerNotifier.value++;
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
        // appBar: AppBar(title: const Text('Notes Page')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Timer display
              ValueListenableBuilder<int>(
                valueListenable: _timerNotifier,
                builder: (context, seconds, child) {
                  final minutes = seconds ~/ 60;
                  final remainingSeconds = seconds % 60;
                  return Text(
                    '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16), // Spacing
              Expanded(
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Notes',
                    hintText: 'Write your notes here...',
                  ),
                  onChanged: (value) {
                    // Track changes to notes
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
                    onPressed: _saveNotes,
                    child: const Text('Save Notes'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_timerNotifier.value == 0) {
                        _startTimer(); // Start the timer
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Timelapse Started'),
                              content: const Text(
                                'Your timelapse has started.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        _timer?.cancel(); // Stop the timer
                        _timerNotifier.value = 0; // Reset the timer
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Timelapse Stopped'),
                              content: const Text(
                                'Your timelapse has stopped.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text(
                      _timerNotifier.value == 0
                          ? 'Start Timelapse'
                          : 'Stop Timelapse',
                    ),
                  ),
                ],
              ),
            ],
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
