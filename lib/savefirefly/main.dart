import 'package:flutter/material.dart';

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
  String _tripType = 'Round-trip';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _adults = 1; // Move counters here to persist state
  int _infants = 0; // Move counters here to persist state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/firefly_logo.png', height: 32),
        ),
        actions: [
          const Icon(Icons.search),
          const SizedBox(width: 16),
          const Icon(Icons.person),
          const SizedBox(width: 16),
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
          ),
        ],
        backgroundColor: Colors.orange.shade700,
      ),
      endDrawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text("Menu")),
            ListTile(title: Text("Flight Search")),
            ListTile(title: Text("Air Cargo")),
            ListTile(title: Text("My Booking")),
            ListTile(title: Text("Check-in")),
            ListTile(title: Text("Enrich with Firefly")),
            ListTile(title: Text("CONNECT WITH US")),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _tripType == 'Round-trip'
                        ? Colors.orange
                        : Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text("Round-trip"),
            ),

            // Trip type toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Round-trip"),
                  selected: _tripType == "Round-trip",
                  onSelected: (selected) {
                    setState(() => _tripType = "Round-trip");
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("One-way"),
                  selected: _tripType == "One-way",
                  onSelected: (selected) {
                    setState(() => _tripType = "One-way");
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // From and To dropdowns
            _buildDropdownField("From"),
            _buildDropdownField("To"),

            // Departure and Return
            _buildDatePicker("Depart"),
            if (_tripType == "Round-trip") _buildDatePicker("Return"),

            // Passengers
            _buildPassengerSelector(),

            // Currency
            _buildDropdownField("Currency"),

            // Promo code
            const TextField(
              decoration: InputDecoration(
                labelText: "Promo Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Find Flights button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade700,
              ),
              child: const Text(
                "Find Me Flight Now",
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),

            // Footer
            const Center(
              child: Text("© 2025 Firefly Airlines. All rights reserved."),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: "KUL", child: Text("Kuala Lumpur")),
          DropdownMenuItem(value: "PEN", child: Text("Penang")),
          DropdownMenuItem(value: "LGK", child: Text("Langkawi")),
        ],
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
          );
        },
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Passengers"),
          Row(
            children: [
              const Text("Adults: "),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  // Decrease adult count if greater than 1
                  if (_adults > 1) {
                    setState(() {
                      _adults--;
                    });
                  }
                },
              ),
              Text('$_adults'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _adults++;
                  });
                },
              ),
              const SizedBox(width: 16),
              const Text("Infants: "),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  // Decrease infant count if greater than 0
                  if (_infants > 0) {
                    setState(() {
                      _infants--;
                    });
                  }
                },
              ),
              Text('$_infants'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _infants++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
