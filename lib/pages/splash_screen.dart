import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../fy/main.dart';
import '../test/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String loggedInUser = '';
  bool _isLoading = true;
  bool _isCheckingInternet = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getLoggedInUser();
    _loadAppVersion();
    // Check internet after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndPrompt();
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'v1.0.0'; // Fallback version
      });
    }
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
                        // blurRadius: 8,
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
                SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _appVersion.isEmpty ? 'Loading...' : _appVersion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
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

