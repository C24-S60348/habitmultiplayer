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
  @override
  void initState() {
    super.initState();
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
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => HomePage()));
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(120),
                ),
                child: Text('Start', style: TextStyle(fontSize: 30)),
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
  bool _isLoading = false;
  String _response = '';

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://afwanproductions.pythonanywhere.com/api/executejsonv2');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': 'afwan',
        'query': 'select * from pointercalculatoradmin',
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _response = response.body;
      });
    } else {
      setState(() {
        _response = 'Failed to load data';
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
        title: Text('Login Page'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: Text('Fetch Data'),
                  ),
                  SizedBox(height: 20),
                  Text(_response),
                ],
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
  {'title': 'Workout', 'link': 'https://www.nerdfitness.com/wp-content/uploads/2021/02/Beginner-Bodyweight-Workout-Infographic-scaled.jpg'},
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
    _webIframeView = WebIframeView(url: widget.link); // Initialize WebIframeView
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
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        toolbarHeight: 70.0, // Increase the height of the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0), // Smaller height
          child: TabBar(
            controller: _tabController,
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
        children: [
          InteractiveViewer(
            child: _webIframeView, // Wrap WebIframeView with InteractiveViewer
            boundaryMargin: EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 1.0,
          ),
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

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getString('notes_${widget.title}') ?? '';
    _notesController.text = savedNotes;
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_${widget.title}', _notesController.text);
  }

  void _startTimer() {
    _timerNotifier.value = 1;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timerNotifier.value++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              onChanged: (value) async {
                await _saveNotes(); // Autosave the notes on every change
              },
            ),
          ),
          const SizedBox(height: 16), // Spacing
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
