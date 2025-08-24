import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Page',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const TestPageContent(),
    );
  }
}

// Standalone page that can be used within the main app
class TestPageContent extends StatefulWidget {
  const TestPageContent({super.key});

  @override
  _TestPageContentState createState() => _TestPageContentState();
}

class _TestPageContentState extends State<TestPageContent> {
  final PageController _pageController = PageController();
  int _pageViewIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(Icons.home),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Center(
              child: Text("Tutorial / Cara penggunaan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _pageViewIndex = index;
                });
              },
              children: [
                Image.asset("assets/test/tutorial1.png", fit: BoxFit.contain),
                Image.asset("assets/test/tutorial2.png", fit: BoxFit.contain),
                Image.asset("assets/test/tutorial3.png", fit: BoxFit.contain),
              ],
            ),
          ),
          if (_pageViewIndex != 2) // Assuming last page index is 2
          SizedBox(
            width: double.infinity,
            child: Center(
              child: Text("Swipe / Geser ----->", style: TextStyle(fontSize: 20),),
            ),
          )
          else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Selesai"),
            ),
          )
        ],
      ),
    );
  }
}
