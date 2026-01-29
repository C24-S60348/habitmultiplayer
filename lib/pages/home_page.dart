import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/dialog_utils.dart';
import 'inside_page.dart';

// Shared button data - could be moved to a model/service later
final List<Map<String, String>> buttonData = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String loggedInUser = '';
  final TextEditingController _habitTitleController = TextEditingController();
  final TextEditingController _habitLinkController = TextEditingController();
  bool _isLoading = true;
  bool _hasShownNoInternetDialog = false;
  bool _isLoadingHabits = false; // Guard to prevent concurrent loads
  List<Map<String, dynamic>> _top3Habits = []; // Store top 3 habits

  Color _colorFromThirdLetterLightMode(String title) {
    if (title.length < 3) return Colors.blueGrey;
    
    final thirdLetter = title[2].toLowerCase();
    final colors = {
      'a': Color(0xFFE57373), // Light Red
      'b': Color(0xFF81C784), // Light Green
      'c': Color(0xFF64B5F6), // Light Blue
      'd': Color(0xFFFFB74D), // Light Orange
      'e': Color(0xFFBA68C8), // Light Purple
      'f': Color(0xFF4DB6AC), // Teal
      'g': Color(0xFFFFD54F), // Yellow
      'h': Color(0xFF7986CB), // Indigo
      'i': Color(0xFFF06292), // Pink
      'j': Color(0xFF4DD0E1), // Cyan
      'k': Color(0xFFFF8A65), // Deep Orange
      'l': Color(0xFF9575CD), // Deep Purple
      'm': Color(0xFF4FC3F7), // Light Blue
      'n': Color(0xFFFFB74D), // Orange
      'o': Color(0xFF81C784), // Green
      'p': Color(0xFFBA68C8), // Purple
      'q': Color(0xFF4DB6AC), // Teal
      'r': Color(0xFFE57373), // Red
      's': Color(0xFF64B5F6), // Blue
      't': Color(0xFFFFD54F), // Yellow
      'u': Color(0xFF7986CB), // Indigo
      'v': Color(0xFFF06292), // Pink
      'w': Color(0xFF4DD0E1), // Cyan
      'x': Color(0xFFFF8A65), // Deep Orange
      'y': Color(0xFF9575CD), // Deep Purple
      'z': Color(0xFF4FC3F7), // Light Blue
    };
    
    return colors[thirdLetter] ?? Colors.blueGrey;
  }

  Color _colorFromThirdLetterDarkMode(String title) {
    if (title.length < 3) return Colors.blueGrey.shade800;
    
    final thirdLetter = title[2].toLowerCase();
    final colors = {
      'a': Color(0xFFB71C1C), // Dark Red
      'b': Color(0xFF1B5E20), // Dark Green
      'c': Color(0xFF0D47A1), // Dark Blue
      'd': Color(0xFFE65100), // Dark Orange
      'e': Color(0xFF4A148C), // Dark Purple
      'f': Color(0xFF004D40), // Dark Teal
      'g': Color(0xFFF57F17), // Dark Yellow
      'h': Color(0xFF1A237E), // Dark Indigo
      'i': Color(0xFF880E4F), // Dark Pink
      'j': Color(0xFF006064), // Dark Cyan
      'k': Color(0xFFBF360C), // Dark Deep Orange
      'l': Color(0xFF4A148C), // Dark Deep Purple
      'm': Color(0xFF01579B), // Dark Light Blue
      'n': Color(0xFFE65100), // Dark Orange
      'o': Color(0xFF1B5E20), // Dark Green
      'p': Color(0xFF4A148C), // Dark Purple
      'q': Color(0xFF004D40), // Dark Teal
      'r': Color(0xFFB71C1C), // Dark Red
      's': Color(0xFF0D47A1), // Dark Blue
      't': Color(0xFFF57F17), // Dark Yellow
      'u': Color(0xFF1A237E), // Dark Indigo
      'v': Color(0xFF880E4F), // Dark Pink
      'w': Color(0xFF006064), // Dark Cyan
      'x': Color(0xFFBF360C), // Dark Deep Orange
      'y': Color(0xFF4A148C), // Dark Deep Purple
      'z': Color(0xFF01579B), // Dark Light Blue
    };
    
    return colors[thirdLetter] ?? Colors.blueGrey.shade800;
  }

  final bool _isDarkMode = true; // Add this state variable

  Color _colorFromThirdLetter(String title) {
    return _isDarkMode ? _colorFromThirdLetterDarkMode(title) : _colorFromThirdLetterLightMode(title);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getLoggedInUser();
    _loadHabits();
    _loadTop3Habits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed && !_isLoadingHabits) {
  //     // Add small delay to prevent rapid-fire calls
  //     Future.delayed(Duration(milliseconds: 300), () {
  //       if (mounted && !_isLoadingHabits) {
  //         _loadHabits(); // Reload habits when app is resumed
  //       }
  //     });
  //   }
  // }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadHabits(),
      _loadTop3Habits(),
    ]);
  }

  Future<void> _showNoInternetDialog() async {
    if (_hasShownNoInternetDialog || !mounted) return;
    setState(() {
      _hasShownNoInternetDialog = true;
    });
    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
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
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadHabits();
                },
                child: Text('Retry'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _hasShownNoInternetDialog = false;
        });
      } else {
        _hasShownNoInternetDialog = false;
      }
    }
  }

  Future<void> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUser = prefs.getString('loggedInUsername') ?? 'guest';
    });
  }

  Future<void> _loadTop3Habits() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/top3habits');
    final body = {'token': token};

    try {
      final response = await safeHttpPost(url, body: body);

      if (response != null && response.statusCode == 200) {
        await Future.delayed(Duration.zero);
        final data = safeJsonDecode(response.body);
        if (data != null && data['status'] == 'ok') {
          final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _top3Habits = list.map((item) => item as Map<String, dynamic>).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Error loading top 3 habits: $e');
    }
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    bool _isAddingHabit = false;
    
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add New Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _habitTitleController,
                    decoration: InputDecoration(
                      labelText: 'Habit Title',
                      hintText: 'e.g., Read Books',
                    ),
                    enabled: !_isAddingHabit,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _habitLinkController,
                    decoration: InputDecoration(
                      labelText: 'Habit Link (Optional)',
                      hintText: 'e.g., https://example.com',
                      errorText: _habitLinkController.text.isNotEmpty && !DialogUtils.isValidUrl(_habitLinkController.text)
                          ? 'Please enter a valid URL (e.g., https://example.com)'
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // Trigger rebuild to show/hide error
                    },
                    enabled: !_isAddingHabit,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isAddingHabit ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isAddingHabit ? null : () async {
                    if (_habitTitleController.text.isNotEmpty) {
                      setDialogState(() {
                        _isAddingHabit = true;
                      });
                      
                      final success = await _addNewHabit(
                        _habitTitleController.text,
                        _habitLinkController.text,
                      );
                      
                      setDialogState(() {
                        _isAddingHabit = false;
                      });
                      
                      // Only close dialog and clear fields if habit was successfully added
                      if (success) {
                        Navigator.of(context).pop();
                        _habitTitleController.clear();
                        _habitLinkController.clear();
                      }
                      // If not successful, keep dialog open so user can fix the error
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shadowColor: Colors.black.withOpacity(0.5),
                    elevation: 10,
                  ),
                  child: _isAddingHabit
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Adding...',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Add Habit',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _addNewHabit(String title, String link) async {
    if (link.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return false;
    } else if (!DialogUtils.isValidUrl(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return false; // Return false to keep dialog open
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final createUrl = Uri.parse('$apiBase/createhabit');
    final body = {
      'name': title,
      'url': link.isEmpty ? 'https://example.com' : link,
      'token': token,
    };
    final createResp = await safeHttpPost(createUrl, body: body);
    if (createResp == null || createResp.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create habit'), backgroundColor: Colors.red),
      );
      return false; // Return false to keep dialog open
    }
    final respData = jsonDecode(createResp.body);
    if (respData['status'] != 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(respData['message']?.toString() ?? 'Failed to create habit'), backgroundColor: Colors.red),
      );
      return false; // Return false to keep dialog open
    }
    
    // Handle both Map and List responses from the API
    Map<String, dynamic>? createdHabit;
    final data = respData['data'];
    if (data != null) {
      if (data is List && data.isNotEmpty) {
        // If it's a list, take the first element
        createdHabit = data.first as Map<String, dynamic>?;
      } else if (data is Map) {
        // If it's already a Map, use it directly
        createdHabit = data as Map<String, dynamic>?;
      }
    }

    // Update the local buttonData
    setState(() {
      if (createdHabit != null) {
        buttonData.add({
          'id': createdHabit['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'title': createdHabit['name']?.toString() ?? title,
          'link': createdHabit['url']?.toString() ?? (link.isEmpty ? 'https://example.com' : link),
        });
      } else {
        // If we couldn't parse the response, still add the habit with generated ID
        buttonData.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'link': link.isEmpty ? 'https://example.com' : link,
        });
      }
    });
    
    // Reload habits from server to ensure we have the latest data
    _loadHabits();
    return true; // Return true to indicate success
  }

  Future<void> _editHabit(String habitId, String newTitle, String newLink) async {
    if (newLink.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return;
    } else if (!DialogUtils.isValidUrl(newLink)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Update title (name)
    final updateNameUrl = Uri.parse('$apiBase/updatehabit');
    final updateNameBody = {
      'id': habitId,
      'newname': 'name',
      'newdata': newTitle,
      'token': token,
    };
    final updateNameResp = await safeHttpPost(updateNameUrl, body: updateNameBody);
    if (updateNameResp == null || updateNameResp.statusCode != 200) {
      final errorMsg = updateNameResp != null 
          ? (jsonDecode(updateNameResp.body)['message']?.toString() ?? 'Failed to update title')
          : 'Network error. Please check your connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }
    final updateNameData = jsonDecode(updateNameResp.body);
    if (updateNameData['status'] != 'ok') {
      final errorMsg = updateNameData['message']?.toString() ?? 'Failed to update title';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }

    // Update link (url) if provided, else keep old (server disallows empty)
    if (newLink.isNotEmpty) {
      final updateUrlUrl = Uri.parse('$apiBase/updatehabit');
      final updateUrlBody = {
        'id': habitId,
        'newname': 'url',
        'newdata': newLink,
        'token': token,
      };
      final updateUrlResp = await safeHttpPost(updateUrlUrl, body: updateUrlBody);
      if (updateUrlResp == null || updateUrlResp.statusCode != 200) {
        final errorMsg = updateUrlResp != null
            ? (jsonDecode(updateUrlResp.body)['message']?.toString() ?? 'Failed to update link')
            : 'Network error. Please check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }
      final updateUrlData = jsonDecode(updateUrlResp.body);
      if (updateUrlData['status'] != 'ok') {
        final errorMsg = updateUrlData['message']?.toString() ?? 'Failed to update link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        return;
      }
    }

      // Update the local buttonData
      setState(() {
        final index = buttonData.indexWhere((item) => item['id'] == habitId);
        if (index != -1) {
          buttonData[index]['title'] = newTitle;
        if (newLink.isNotEmpty) {
          buttonData[index]['link'] = newLink;
        }
        }
      });
  }

  Future<void> _showEditHabitDialog(BuildContext context, String habitId, String currentTitle, String currentLink) async {
    final TextEditingController titleController = TextEditingController(text: currentTitle);
    final TextEditingController linkController = TextEditingController(text: currentLink);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g., Read Books',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'Habit Link (Optional)',
                  hintText: 'e.g., https://example.com',
                  errorText: linkController.text.isNotEmpty && !DialogUtils.isValidUrl(linkController.text)
                      ? 'Please enter a valid URL (e.g., https://example.com)'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show/hide error
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            CustomButton(
              text: 'Save Changes',
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await _editHabit(
                    habitId,
                    titleController.text,
                    linkController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadHabits() async {
    if (!mounted || _isLoadingHabits) return; // Prevent concurrent loads
    
    setState(() {
      _isLoading = true;
      _isLoadingHabits = true;
    });
    
    // Yield control to UI thread
    await Future.delayed(Duration.zero);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/readhabit');
    final body = {'token': token};

    try {
      final response = await safeHttpPost(url, body: body);

      if (response != null && response.statusCode == 200) {
        // Yield before parsing JSON
        await Future.delayed(Duration.zero);
        final data = safeJsonDecode(response.body);
        if (data != null && data['status'] == 'ok') {
          final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              buttonData.clear();
              for (final item in list) {
                final m = item as Map<String, dynamic>;
                buttonData.add({
                  'id': m['id']?.toString() ?? '',
                  'title': m['name']?.toString() ?? '',
                  'link': m['url']?.toString() ?? 'https://example.com',
                });
              }
            });
          }
        } else {
          // Server responded but status not ok; optionally notify
        }
      } else {
        if (mounted) {
          await _showNoInternetDialog();
        }
      }
    } catch (e) {
      print('Error loading habits: $e');
      if (mounted) {
        await _showNoInternetDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingHabits = false;
        });
      } else {
        _isLoadingHabits = false;
      }
    }
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 6, // Show 6 shimmer items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: _loadHabits,
        //     tooltip: 'Refresh Habits',
        //   ),
        // ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/skywallpaper.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.softLight,
            ),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top 3 Habits Section
                if (_top3Habits.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Top 3 Habits (Last 5 Days)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ..._top3Habits.asMap().entries.map((entry) {
                          final index = entry.key;
                          final habit = entry.value;
                          final medals = ['🥇', '🥈', '🥉'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  medals[index],
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    habit['name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${habit['count']} ✓',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _isLoading
                            ? _buildShimmerGrid()
                            : buttonData.isEmpty
                                ? Center(
                                    child: Text(
                                      'No habits yet. Add some!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: buttonData.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.all(8.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final result = await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => InsidePage(
                                                  title: buttonData[index]['title']!,
                                                  link: buttonData[index]['link']!,
                                                  habitId: buttonData[index]['id']!,
                                                ),
                                              ),
                                            );
                                            if (result != null && result == true) {
                                              _loadHabits(); // Refresh the habits list
                                            }
                                          },
                                          onLongPress: () {
                                            _showEditHabitDialog(
                                              context,
                                              buttonData[index]['id']!,
                                              buttonData[index]['title']!,
                                              buttonData[index]['link']!,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _colorFromThirdLetter(buttonData[index]['title']!),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(50),
                                            ),
                                          ),
                                          child: Text(
                                            buttonData[index]['title']!,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: CustomButton(
                    text: 'Add New Habit',
                    onPressed: () async {
                      await _showAddHabitDialog(context);
                      _loadHabits(); // Reload habits after adding new one
                    },
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

