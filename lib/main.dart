import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports
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

//splash screen
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

//home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

final buttonData = [
  {'title': 'Baca Al-quran', 'link': 'https://quran.com'},
  {'title': 'Buat app', 'link': 'https://flutter.dev'},
  {'title': 'Workout', 'link': 'https://www.workout.com'},
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
                            builder: (context) => InsidePage(
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

//look webview page
class InsidePage extends StatefulWidget {
  final String title;
  final String link;

  const InsidePage({super.key, required this.title, required this.link});

  @override
  _InsidePageState createState() => _InsidePageState();
}

class _InsidePageState extends State<InsidePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _notesController = TextEditingController();
  late final WebIframeView _webIframeView; // Persist WebIframeView

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize WebIframeView
    _webIframeView = WebIframeView(url: widget.link);

    // Load saved notes
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getString('notes_${widget.title}') ?? '';
    setState(() {
      _notesController.text = savedNotes;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_${widget.title}', _notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.web), text: 'Web View'),
            Tab(icon: Icon(Icons.note), text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable sliding
        children: [
          _webIframeView, // Reuse the WebIframeView
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notes',
                hintText: 'Write your notes here...',
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _saveNotes(); // Save the notes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notes saved successfully!')),
          );
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class WebIframeView extends StatelessWidget {
  final String url;

  iframeMatcher() {
    return (context, element) => element.localName == 'iframe';
  }

  const WebIframeView({Key? key, required this.url}) : super(key: key);

  @override
  // Widget build(BuildContext context) {
  //   return Html(
  //     data: '''
  //       <iframe
  //         src="$url"
  //         width="100%"
  //         height="100%"
  //         style="border:none;">
  //       </iframe>
  //     ''',
  //     style: {
  //       "iframe": Style(
  //         width: Width(double.infinity),
  //         height: Height(double.infinity),
  //       ),
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final String viewId = 'iframe-${url.hashCode}';
      registerIframe(viewId, url);
      return HtmlElementView(viewType: viewId);
    } else {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url));
      return WebViewWidget(controller: controller);
    }
  }
}
