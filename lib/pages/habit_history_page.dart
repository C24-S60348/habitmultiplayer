import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_helpers.dart';

class HabitHistoryPage extends StatefulWidget {
  final String habitId;
  final String habitTitle;
  const HabitHistoryPage({super.key, required this.habitId, required this.habitTitle});

  @override
  _HabitHistoryPageState createState() => _HabitHistoryPageState();
}

class _HabitHistoryPageState extends State<HabitHistoryPage> {
  // Map from dateKey to list of user entries: {username: String, status: int}
  Map<String, List<Map<String, dynamic>>> habitMap = {};
  Set<String> allMembersSet = {}; // Store all members (from habit and history)
  bool isLoading = true;
  int centerOffset = 0;
  String? _loadingDateKey; // Add this to track which date is being updated
  String? _loadingUsername; // Track which username is being updated

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    // First, get the habit data to find owner and member
    final habitUrl = Uri.parse('$apiBase/readhabit');
    final habitBody = {'token': token};
    final habitResponse = await safeHttpPost(habitUrl, body: habitBody);
    
    Set<String> membersFromHabit = {};
    if (habitResponse != null && habitResponse.statusCode == 200) {
      final habitData = jsonDecode(habitResponse.body);
      if (habitData['status'] == 'ok') {
        final List<dynamic> habits = (habitData['data'] ?? []) as List<dynamic>;
        for (final habit in habits) {
          final h = habit as Map<String, dynamic>;
          if (h['id']?.toString() == widget.habitId) {
            // Extract owner (username) from the habit data
            final owner = h['username']?.toString() ?? '';
            if (owner.isNotEmpty) {
              membersFromHabit.add(owner);
            }
            
            // Extract members from the members array
            final membersData = h['members'];
            if (membersData != null && membersData is List) {
              for (final member in membersData) {
                if (member is Map) {
                  final memberName = member['member']?.toString() ?? '';
                  if (memberName.isNotEmpty && memberName != owner) {
                    if (!membersFromHabit.contains(memberName)) {
                      membersFromHabit.add(memberName);
                    }
                  }
                } else if (member is String) {
                  if (member.isNotEmpty && member != owner) {
                    if (!membersFromHabit.contains(member)) {
                      membersFromHabit.add(member);
                    }
                  }
                }
              }
            }
            break;
          }
        }
      }
    }
    
    // Then get history
    final url = Uri.parse('$apiBase/readhistory');
    final body = {
      'habitid': widget.habitId,
      'token': token,
    };
    final response = await safeHttpPost(url, body: body);
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        // Group all entries by date (not filtered by username)
        final Map<String, List<Map<String, dynamic>>> map = {};
        final Set<String> membersFromHistory = {};
        
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final dateKey = m['historydate']?.toString() ?? '';
          final username = m['username']?.toString() ?? '';
          final status = int.tryParse(m['historystatus']?.toString() ?? '0') ?? 0;
          if (dateKey.isNotEmpty && username.isNotEmpty) {
            membersFromHistory.add(username);
            if (!map.containsKey(dateKey)) {
              map[dateKey] = [];
            }
            map[dateKey]!.add({
              'username': username,
              'status': status,
            });
          }
        }
        
        // Combine members from habit and history
        final allMembers = {...membersFromHabit, ...membersFromHistory};
        
        setState(() {
          habitMap = map;
          allMembersSet = allMembers;
          isLoading = false;
        });
      } else {
        setState(() {
          allMembersSet = membersFromHabit;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        allMembersSet = membersFromHabit;
        isLoading = false;
      });
    }
  }

  List<DateTime> getSevenDays() {
    final today = DateTime.now();
    final center = today.add(Duration(days: centerOffset));
    return List.generate(7, (i) => center.add(Duration(days: i - 3)));
  }

  static const List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Future<void> _setHabitStateForDate(DateTime date, int newState) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername') ?? 'guest';
    final token = prefs.getString('token') ?? '';
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Find current user's existing state
    final currentEntries = habitMap[dateKey] ?? [];
    final currentUserEntry = currentEntries.firstWhere(
      (e) => e['username'] == username,
      orElse: () => {},
    );
    final previousState = currentUserEntry['status'] ?? 0;
    
    // Update the state immediately in the UI
    setState(() {
      if (!habitMap.containsKey(dateKey)) {
        habitMap[dateKey] = [];
      }
      // Update or add current user's entry
      final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
      if (index >= 0) {
        habitMap[dateKey]![index]['status'] = newState;
      } else {
        habitMap[dateKey]!.add({'username': username, 'status': newState});
      }
      _loadingDateKey = dateKey;
      _loadingUsername = username;
    });

    try {
      final url = Uri.parse('$apiBase/updatehistory');
      final body = {
        'habitid': widget.habitId,
        'historydate': dateKey,
        'historystatus': newState.toString(),
        'token': token,
      };
      final response = await safeHttpPost(url, body: body);
      if (response == null) {
        // Revert on network error
        final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
        if (index >= 0) {
          habitMap[dateKey]![index]['status'] = previousState;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _loadingDateKey = null;
          _loadingUsername = null;
        });
        return;
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 'ok') {
          // Revert on API error
          final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
          if (index >= 0) {
            habitMap[dateKey]![index]['status'] = previousState;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${data['message']?.toString() ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Reload to get latest data from server
          await _fetchHistory();
        }
      } else {
        // Revert on HTTP error
        final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
        if (index >= 0) {
          habitMap[dateKey]![index]['status'] = previousState;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit state. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Revert on exception
      final index = habitMap[dateKey]!.indexWhere((e) => e['username'] == username);
      if (index >= 0) {
        habitMap[dateKey]![index]['status'] = previousState;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state
      setState(() {
        _loadingDateKey = null;
        _loadingUsername = null;
      });
    }
  }
  
  // Get all unique usernames (from habit and history)
  List<String> _getAllMembers() {
    return allMembersSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('loggedInUsername') ?? 'guest'),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data ?? 'guest';
        final allMembers = _getAllMembers();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.habitTitle} - History',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _fetchHistory();
                },
                tooltip: 'Refresh History',
              ),
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    centerOffset -= 7;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    centerOffset += 7;
                  });
                },
              ),
            ],
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
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : allMembers.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchHistory,
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'No members yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        child: SingleChildScrollView(
                          child: Column(
                            children: allMembers.map<Widget>((member) {
                            final isCurrentUser = member == currentUsername;
                            return Column(
                              children: [
                                // Member name section
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                                      SizedBox(width: 8),
                                      Text(
                                        member,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrentUser ? Colors.blue : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // History calendar for this member
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: getSevenDays().map((date) {
                                        int weekday = date.weekday % 7;
                                        final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                                        final entries = habitMap[dateKey] ?? [];
                                        final memberEntry = entries.firstWhere(
                                          (e) => e['username'] == member,
                                          orElse: () => {'username': member, 'status': 0},
                                        );
                                        final memberState = memberEntry['status'] ?? 0;
                                        
                                        final now = DateTime.now();
                                        final today = DateTime(now.year, now.month, now.day + 1);
                                        final isFuture = date.isAfter(today);
                                        final isLoading = _loadingDateKey == dateKey && _loadingUsername == member && isCurrentUser;
                                        
                                        IconData icon;
                                        Color color;
                                        if (memberState == 1) {
                                          icon = Icons.check_box;
                                          color = Colors.green;
                                        } else if (memberState == -1) {
                                          icon = Icons.close;
                                          color = Colors.red;
                                        } else {
                                          icon = Icons.check_box_outline_blank;
                                          color = Colors.grey;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          child: GestureDetector(
                                            onTap: (isFuture || isLoading || !isCurrentUser) ? null : () {
                                              // Cycle current user's state (only if it's the current user)
                                              int newState;
                                              if (memberState == 0) {
                                                newState = 1;
                                              } else if (memberState == 1) {
                                                newState = -1;
                                              } else {
                                                newState = 0;
                                              }
                                              _setHabitStateForDate(date, newState);
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(weekDays[weekday], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                SizedBox(height: 4),
                                                Text('${date.day}/${date.month}', style: TextStyle(fontSize: 14)),
                                                SizedBox(height: 8),
                                                isLoading
                                                    ? SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                                        ),
                                                      )
                                                    : Icon(
                                                        icon,
                                                        color: isFuture ? Colors.grey[300] : color,
                                                        size: 24,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Divider(height: 1, thickness: 1),
                              ],
                            );
                          }).toList(),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }
}