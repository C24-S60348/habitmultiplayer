import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class Habit {
  String name;
  String description;
  String imagePath;
  Map<DateTime, int> dateStates = {};

  Habit(this.name, this.description, this.imagePath);
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Habit> habits = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(onComplete: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => HomePage(
                  habits: habits,
                  onAddHabit: (habit) => setState(() => habits.add(habit)),
                )));
      }),
    );
  }
}

// Splash with loading percent
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  SplashScreen({required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        progress += 0.05;
        if (progress >= 1.0) {
          timer.cancel();
          widget.onComplete();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(value: progress),
          SizedBox(height: 20),
          Text("${(progress * 100).toInt()}%"),
        ]),
      ),
    );
  }
}

// Home Page with ADD button and list of habits
class HomePage extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit) onAddHabit;

  HomePage({required this.habits, required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Habits')),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (_, index) {
          return ListTile(
            leading: Image.asset(habits[index].imagePath, width: 40, height: 40),
            title: Text(habits[index].name),
            subtitle: Text(habits[index].description),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HabitDetailPage(habit: habits[index])));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Habit? newHabit = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => AddHabitPage()));
          if (newHabit != null) onAddHabit(newHabit);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// Add Habit Page
class AddHabitPage extends StatefulWidget {
  @override
  _AddHabitPageState createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String imagePath = 'assets/sample.png'; // default or sample

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
          TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
          SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: Text("Select Image (Default Used)")),
          Spacer(),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(
                    context,
                    Habit(nameController.text, descriptionController.text, imagePath));
              },
              child: Text('Save'))
        ]),
      ),
    );
  }
}

// Habit Detail Page
class HabitDetailPage extends StatefulWidget {
  final Habit habit;

  HabitDetailPage({required this.habit});

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  DateTime today = DateTime.now();

  int getDateState(DateTime date) => widget.habit.dateStates[date] ?? 0;

  void toggleState(DateTime date) {
    setState(() {
      int state = getDateState(date);
      widget.habit.dateStates[date] = (state + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime center = DateTime(today.year, today.month, today.day);
    List<DateTime> days = List.generate(5, (i) => center.add(Duration(days: i - 2)));

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.name)),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text("${_monthName(today.month)}", style: TextStyle(fontSize: 20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: days.map((d) {
              int state = getDateState(d);
              Color color = [Colors.grey, Colors.green, Colors.red][state];
              return GestureDetector(
                onTap: () => toggleState(d),
                child: Container(
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(), color: color),
                  child: Text('${d.day}'),
                ),
              );
            }).toList(),
          ),
          Spacer(),
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HabitActionPage(habit: widget.habit, date: today)));
              },
              child: Text("LET'S DO IT"))
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month];
  }
}

// Habit Action Page
class HabitActionPage extends StatefulWidget {
  final Habit habit;
  final DateTime date;

  HabitActionPage({required this.habit, required this.date});

  @override
  State<HabitActionPage> createState() => _HabitActionPageState();
}

class _HabitActionPageState extends State<HabitActionPage> {
  String note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Do ${widget.habit.name}")),
      body: Column(
        children: [
          SizedBox(height: 20),
          Image.asset(widget.habit.imagePath, height: 200),
          Text('Your Notes: $note'),
          Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FloatingActionButton(
                child: Icon(Icons.note_add),
                onPressed: () async {
                  String? result = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: Text("Add Note"),
                            content: TextField(
                              autofocus: true,
                              onChanged: (val) => note = val,
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, note),
                                  child: Text("Save"))
                            ],
                          ));
                  if (result != null) setState(() => note = result);
                },
              ),
            ),
          ),
          GestureDetector(
            onLongPress: () {
              setState(() {
                widget.habit.dateStates[widget.date] = 1;
              });
              Navigator.pop(context);
            },
            child: Container(
              margin: EdgeInsets.all(20),
              width: double.infinity,
              height: 60,
              alignment: Alignment.center,
              color: Colors.green,
              child: Text("Done", style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          )
        ],
      ),
    );
  }
}