import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firefly Airlines',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const FlightSearchPage(),
    );
  }
}

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _bannerSlider(),
          _topMenu(),
        ],
      ),
    );
  }

  Widget _bannerSlider() {
    return 
    SizedBox(
      width: double.infinity,
      height: 300,
      child:
        PageView(
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

  // Widget _sideMenu() {
  //   //sidemenu slide out
  //   return Drawer(
  //     child: Column(
  //       children: [
  //         Text("Side Menu"),
  //       ],
  //     ),
  //   );
  // }

  Widget _topMenu() {
    return 
    Column(
      children: [
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                //open side menu
                // _scaffoldKey.currentState?.openDrawer();
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
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.account_circle_rounded,
                    color: FYTheme.primaryOrange),
                onPressed: () {
                  //Navigator.of(context).pop();
                },
              ),
              Text(
                "Hello, guest! Login or register",
                style: TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  //Navigator.of(context).pop();
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}
