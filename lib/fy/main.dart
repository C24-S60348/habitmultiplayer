import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit_multiplayer/fy/api.dart';
import 'theme.dart';

void main() {
  runApp(const FYPage());
}

class FYPage extends StatelessWidget {
  const FYPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firefly Airlines',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const FlightSearchPage(),
    );
  }
}

// Standalone page that can be used within the main app
class FYPageContent extends StatelessWidget {
  const FYPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlightSearchPage();
  }
}

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //_loadSideMenu()
  List<String> _sideMenuNames = [];
  bool _isMenuLoading = false;
  String? _menuError;
  
  // Banner data
  List<String> _bannerImages = [];
  bool _isBannerLoading = false;

  //load api start ================================
  @override
  void initState() {
    super.initState();
    _loadSideMenu();
    _loadBanners();
  }

  Future<void> _loadSideMenu() async {
    setState(() {
      _isMenuLoading = true;
      _menuError = null;
    });
    try {
      final data = await FireflyApi.getLoading();
      final menuList = data['MenuList'];
      final firstData = menuList[0]['Data'];
      final names = firstData.map<String>((item) => item['Name'].toString()).toList();
      setState(() {
        _sideMenuNames = names;
        _isMenuLoading = false;
      });
    } catch (e) {
      setState(() {
        _menuError = 'Error loading menu';
        _isMenuLoading = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isBannerLoading = true;
    });
    try {
      final bannerData = await FireflyApi.getBanner();
      final bannerList = bannerData['BannerList'] as List;
      final images = bannerList.map<String>((element) => element['Banner'].toString()).toList();
      setState(() {
        _bannerImages = images;
        _isBannerLoading = false;
      });
    } catch (e) {
      print('Error loading banners: $e');
      setState(() {
        _isBannerLoading = false;
      });
    }
  }

  //load api end ================================

  Widget _sideMenu() {
    return 
    Drawer( 
      child: _isMenuLoading
      ? Center(child: CircularProgressIndicator())
      : _menuError != null
          ? Center(child: Text(_menuError!))
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Text("Side Menu"),
                  SizedBox(height: 10),
                  for (var name in _sideMenuNames)
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(name),
                    ),
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _sideMenu(),
      body: Stack(
        children: [
          _bannerSlider(),
          _topMenu(),
          _chooseFlight(),
        ],
      ),
    );
  }

  Widget _bannerSlider() {
    var bannerHeight = 280.0;
    if (_isBannerLoading) {
      return SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_bannerImages.isEmpty) {
      // Fallback to default images if no banners loaded
      return SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: PageView(
          controller: PageController(
            initialPage: 0,
            viewportFraction: 1.0,
          ),
          scrollDirection: Axis.horizontal,
          children: [
            Image.asset(
              'assets/fy/dubai-uae-featured.jpg',
              fit: BoxFit.cover,
            ),
            Image.asset(
              'assets/fy/dubai-uae-featured.jpg',
              fit: BoxFit.cover,
            ),
            Image.asset(
              'assets/fy/dubai-uae-featured.jpg',
              fit: BoxFit.cover,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: PageView(
        controller: PageController(
          initialPage: 0,
          viewportFraction: 1.0,
        ),
        scrollDirection: Axis.horizontal,
        children: _bannerImages.map((imageUrl) {
          return Image.network(
            imageUrl,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/fy/dubai-uae-featured.jpg',
                fit: BoxFit.fill,
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _topMenu() {
    return 
    Column(
      children: [
        kIsWeb ? SizedBox(height: 10) : SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                //open side menu
                _scaffoldKey.currentState?.openDrawer();
                // _sideMenu();
                //Navigator.of(context).pop();
              },
              padding: EdgeInsets.all(10),
            ),
            SvgPicture.asset(
              'assets/fy/fireflylogowhite.svg',
            ),
            IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                //Navigator.of(context).pop();
              },
              padding: EdgeInsets.all(10),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          height: 45,
          padding: EdgeInsets.only(left: 2),
          child: _helloLogin(),
        )
      ],
    );
  }

  Widget _chooseFlight() {
    final items = [
      DropdownMenuItem(child: Text("Flight 1"), value: "Flight 1"),
      DropdownMenuItem(child: Text("Flight 2"), value: "Flight 2"),
      DropdownMenuItem(child: Text("Flight 3"), value: "Flight 3"),
    ];

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 260),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 231, 230, 230),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("From"),
                      ),
                      SizedBox(width: 10),
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("To"),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("Date from"),
                      ),
                      SizedBox(width: 10),
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("Date to"),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("Passenger"),
                      ),
                      SizedBox(width: 10),
                      DropdownButton(
                        items: items, 
                        onChanged: (value) {
                          print('Selected: $value');
                        },
                        hint: Text("Currency"),
                      ),
                    ],
                  ),
                  Text("+ add promo code"),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FYTheme.primaryOrange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        print('Search Flight');
                      },
                      child: Text("Search flights", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _promoWhyFirefly(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoWhyFirefly() {
    return 
    Container(
      width: double.infinity,
      height: 100,
      child: Row(
        children: [
          Text("Promo Why Firefly"),
        ],
      ),
    );
  }

  Widget _helloLogin() {
    return GestureDetector(
      onTap: () {
        _showLoginDialog();
      },
      child: Container(
        width: double.infinity,
        height: 45,
        padding: EdgeInsets.only(left: 2),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.account_circle_rounded,
                  color: FYTheme.primaryOrange),
              onPressed: () {
              },
            ),
            Text(
              "Hello, guest! Login or register",
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: () {
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login / Register'),
          content: Text('Login or registration functionality would go here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your login/register logic here
                print('Login/Register action triggered');
              },
              child: Text('Login'),
            ),
          ],
        );
      },
    );
  }
}
