import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/web_iframe_view.dart';
import 'notes_page.dart';
import 'habit_history_page.dart';
import 'edit_habit_page.dart';

class InsidePage extends StatefulWidget {
  final String habitId;
  String title;
  String link;

  InsidePage({
    super.key, 
    required this.title, 
    required this.link,
    required this.habitId,
  });

  @override
  _InsidePageState createState() => _InsidePageState();
}

class _InsidePageState extends State<InsidePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late WebIframeView _webIframeView;
  final bool _showNotes = false;
  int _habitState = 0; // 0: blank, 1: ticked, 2: X
  bool _isLoadingHabitState = false; // Add loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _webIframeView = WebIframeView(url: widget.link);
    _loadHabitState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadHabitState(); // Reload habit state when app is resumed
    }
  }

  Future<void> _loadHabitState() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingHabitState = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final url = Uri.parse('$apiBase/readhistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&token=${Uri.encodeQueryComponent(token)}');
      final response = await safeHttpGet(url);
      if (response == null) {
        setState(() {
          _isLoadingHabitState = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ReadHistory network error: Please check your connection'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          final List<dynamic> hist = (data['data'] ?? []) as List<dynamic>;
          
          // Debug: Show what we received
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('📖 Loaded ${hist.length} history entries for habit ${widget.habitId}'),
          //       duration: Duration(seconds: 2),
          //       backgroundColor: Colors.blue,
          //     ),
          //   );
          // }
          
          // Find the history entry for today for this user
          Map<String, dynamic>? mineToday;
          for (final item in hist) {
            final m = item as Map<String, dynamic>;
            final itemUsername = m['username']?.toString() ?? '';
            final itemDate = m['historydate']?.toString() ?? '';
            
            if (itemUsername == username && itemDate == dateKey) {
              mineToday = m;
              break;
            }
          }
          
          setState(() {
            if (mineToday != null && mineToday['historystatus'] != null) {
              _habitState = int.tryParse(mineToday['historystatus']?.toString() ?? '0') ?? 0;
              
              // Debug: Show what state was found
              // if (mounted) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text('✅ Found state: $_habitState for $username on $dateKey'),
              //       duration: Duration(seconds: 2),
              //       backgroundColor: Colors.green,
              //     ),
              //   );
              // }
            } else {
              _habitState = 0; // Default to unchecked if no entry found
              
              // Debug: Show that no entry was found
              // if (mounted) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text('⚠️ No history found for $username on $dateKey (Looking for: username="$username", date="$dateKey")'),
              //       duration: Duration(seconds: 3),
              //       backgroundColor: Colors.orange,
              //     ),
              //   );
              // }
            }
            _isLoadingHabitState = false;
          });
        } else {
          // API returned error status
          setState(() {
            _isLoadingHabitState = false;
          });
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('❌ ReadHistory failed: ${data['message']?.toString() ?? 'Unknown error'}'),
          //       duration: Duration(seconds: 3),
          //       backgroundColor: Colors.red,
          //     ),
          //   );
          // }
        }
      } else {
        // HTTP error
        setState(() {
          _isLoadingHabitState = false;
        });
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('❌ ReadHistory HTTP error: ${response.statusCode}'),
        //       duration: Duration(seconds: 3),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        // }
      }
    } catch (e) {
      print('Error loading habit state: $e');
      setState(() {
        _isLoadingHabitState = false;
      });
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('❌ ReadHistory exception: $e'),
      //       duration: Duration(seconds: 3),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
    }
  }

  Future<void> _cycleHabitState() async {
    // Store previous state for potential revert
    final previousState = _habitState;
    
    // Set loading state to true
    setState(() {
      _isLoadingHabitState = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Update the tick state for this habit and date
    int newState;
    if (_habitState == 0) {
      newState = 1;
    } else if (_habitState == 1) {
      newState = -1;
    } else {
      newState = 0;
    }
    
    // Update UI optimistically
    setState(() {
      _habitState = newState;
    });
    
    // Debug: Show what we're trying to save
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('💾 Saving: habitId=${widget.habitId}, date=$dateKey, status=$newState, username=$username'),
    //       duration: Duration(seconds: 2),
    //       backgroundColor: Colors.blue,
    //     ),
    //   );
    // }
    
    try {
      final url = Uri.parse(
        '$apiBase/updatehistory?habitid=${Uri.encodeQueryComponent(widget.habitId)}&historydate=$dateKey&historystatus=$newState&token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await safeHttpGet(url);
      if (response == null) {
        // Revert on network error
        setState(() {
          _habitState = previousState; // Revert to previous state
          _isLoadingHabitState = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Network error: Please check your connection'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          // Successfully saved
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('✅ UpdateHistory success! Message: ${data['message']?.toString() ?? 'Saved'}'),
          //       duration: Duration(seconds: 2),
          //       backgroundColor: Colors.green,
          //     ),
          //   );
          // }
          
          // Now reload from server to ensure we have the correct state
          await _loadHabitState();
        } else {
          // API returned error
          final errorMsg = data['message']?.toString() ?? 'Failed to update habit state';
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('❌ UpdateHistory failed: $errorMsg'),
          //       duration: Duration(seconds: 3),
          //       backgroundColor: Colors.red,
          //     ),
          //   );
          // }
          // Reload to get the actual state from server
          await _loadHabitState();
        }
      } else {
        // HTTP error
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('❌ UpdateHistory HTTP error: ${response.statusCode}\nResponse: ${response.body}'),
        //       duration: Duration(seconds: 4),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        // }
        // Reload to get actual state
        await _loadHabitState();
      }
    } catch (e) {
      print('Error updating habit state: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('❌ UpdateHistory exception: $e'),
      //       duration: Duration(seconds: 3),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
      // On error, reload to get actual state from server
      await _loadHabitState();
    } finally {
      setState(() {
        _isLoadingHabitState = false;
      });
    }
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

  void _navigateToEditPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditHabitPage(
          habitId: widget.habitId,
          currentTitle: widget.title,
          currentLink: widget.link,
        ),
      ),
    );

    if (result != null) {
      if (result['deleted'] == true) {
        // If habit was deleted, pop back to home page and trigger refresh
        Navigator.of(context).pop(true); // Pass true to indicate deletion
      } else {
        setState(() {
          widget.title = result['title'];
          widget.link = result['link'];
          _webIframeView = WebIframeView(url: widget.link);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _navigateToEditPage,
          child: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        actions: [
          IconButton(
            icon: Icon(Icons.note),
            tooltip: 'Open Notes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotesPage(
                    title: widget.title,
                    habitId: widget.habitId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View Habit History',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitHistoryPage(habitId: widget.habitId, habitTitle: widget.title),
                ),
              );
              // Reload habit state when coming back from history page
              if (mounted) {
                _loadHabitState();
              }
            },
          ),
          IconButton(
            icon: _isLoadingHabitState 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_habitIcon),
            tooltip: _habitTooltip,
            onPressed: _isLoadingHabitState ? null : _cycleHabitState,
          ),
        ],
      ),
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
        child: (kIsWeb && _showNotes) ? SizedBox.shrink() : _webIframeView,
      ),
    );
  }
}