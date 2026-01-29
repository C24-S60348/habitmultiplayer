import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_helpers.dart';

class NotesPage extends StatefulWidget {
  final String title;
  final String habitId;
  final VoidCallback? onClose;

  const NotesPage({
    super.key, 
    required this.title, 
    required this.habitId,
    this.onClose
  });

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Map<String, String> notesMap = {}; // Map from username to notes
  Set<String> allMembersSet = {}; // Store all members
  Map<String, TextEditingController> controllersMap = {}; // Controllers for each member
  Map<String, bool> notesChangedMap = {}; // Track changes for each member
  Map<String, String> memberNamesMap = {}; // Map from username to display name
  bool _isLoading = true;
  String? _savingUsername; // Track which user's notes are being saved
  String? _selectedMember; // Currently selected member to view/edit
  final TextEditingController _allUserController = TextEditingController();
  bool _allUserNoteChanged = false;
  bool _isSavingAllUserNote = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in controllersMap.values) {
      controller.dispose();
    }
    _allUserController.dispose();
    super.dispose();
  }

  Future<void> _updateAllUserNote() async {
    setState(() {
      _isSavingAllUserNote = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$apiBase/updatenote');
    final body = {
      'habitid': widget.habitId,
      'notes': _allUserController.text,
      'token': token,
      'alluser': 'yes', // This tells the API to save as "alluser" note
    };
    final resp = await safeHttpPost(url, body: body);
    
    if (resp != null && resp.statusCode == 200) {
      final data = safeJsonDecode(resp.body);
      if (data != null && data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All User note saved successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _allUserNoteChanged = false;
        });
      } else if (data != null && data['status'] == 'error') {
        final errorMsg = data['message']?.toString() ?? 'Failed to save All User note';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save All User note'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isSavingAllUserNote = false;
    });
  }

  Future<void> _updateNotesOnServer(String username, String newNote) async {
    setState(() {
      _savingUsername = username;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Use POST with JSON body instead of GET to avoid URL length limitations
    final url = Uri.parse('$apiBase/updatenote');
    final body = {
      'habitid': widget.habitId,
      'notes': newNote,
      'token': token,
    };
    final resp = await safeHttpPost(url, body: body);
    
    if (resp != null && resp.statusCode == 200) {
      final data = safeJsonDecode(resp.body);
      if (data != null && data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes saved successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          notesChangedMap[username] = false;
        });
      } else if (data != null && data['status'] == 'error') {
        // Show error message from API
        final errorMsg = data['message']?.toString() ?? 'Failed to save notes';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _savingUsername = null;
    });
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
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
                  final memberUsername = member['member']?.toString() ?? '';
                  if (memberUsername.isNotEmpty && memberUsername != owner) {
                    if (!membersFromHabit.contains(memberUsername)) {
                      membersFromHabit.add(memberUsername);
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

    // Then get all notes
    final url = Uri.parse('$apiBase/readnote');
    final body = {
      'habitid': widget.habitId,
      'token': token,
    };
    final response = await safeHttpPost(url, body: body);

    final Map<String, String> notes = {};
    final Set<String> membersFromNotes = {};
    
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final username = m['username']?.toString() ?? '';
          final note = m['notes']?.toString() ?? '';
          if (username.isNotEmpty) {
            if (username == 'alluser') {
              // Store the "All User" note separately
              _allUserController.text = note;
            } else {
              membersFromNotes.add(username);
              notes[username] = note;
            }
          }
        }
      }
    }

    // Combine members from habit and notes
    final allMembers = {...membersFromHabit, ...membersFromNotes};
    
    // Add "alluser" as a special member
    allMembers.add('alluser');
    
    // Fetch member names from /readprofile API
    Map<String, String> memberNamesMap = {};
    print('=== FETCHING MEMBER NAMES ===');
    print('Total members: ${allMembers.length}');
    print('Members list: $allMembers');
    print('Token is empty: ${token.isEmpty}');
    debugPrint('=== FETCHING MEMBER NAMES ===');
    debugPrint('Total members: ${allMembers.length}');
    debugPrint('Members list: $allMembers');
    debugPrint('Token is empty: ${token.isEmpty}');
    
    // Allow API call even for guest (readprofile now supports guest)
    if (allMembers.isNotEmpty) {
      try {
        final profileUrl = Uri.parse('$apiBase/readprofile');
        final usernamesList = allMembers.join(',');
        print('Calling /readprofile API with usernames: $usernamesList');
        debugPrint('Calling /readprofile API with usernames: $usernamesList');
        final profileBody = {
          'token': token,
          'usernames': usernamesList,
        };
        final profileResponse = await safeHttpPost(profileUrl, body: profileBody);
        print('Profile API response status: ${profileResponse?.statusCode}');
        debugPrint('Profile API response status: ${profileResponse?.statusCode}');
        
        if (profileResponse != null && profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          print('Profile API response: ${profileResponse.body}');
          debugPrint('Profile API response: ${profileResponse.body}');
          if (profileData['status'] == 'ok' && profileData['data'] != null) {
            final List<dynamic> profiles = profileData['data'] as List<dynamic>;
            print('Found ${profiles.length} profiles');
            debugPrint('Found ${profiles.length} profiles');
            for (final profile in profiles) {
              final p = profile as Map<String, dynamic>;
              final username = p['username']?.toString() ?? '';
              final name = p['name']?.toString() ?? '';
              print('Processing profile - username: $username, name: "$name"');
              debugPrint('Processing profile - username: $username, name: "$name"');
              if (username.isNotEmpty) {
                // Store name (even if empty, will fallback to username in display)
                memberNamesMap[username] = name;
                print('Stored name for $username: "${name.isEmpty ? "(empty)" : name}"');
                debugPrint('Profile for $username: name="${name.isEmpty ? "(empty)" : name}"');
              }
            }
            print('Final memberNamesMap: $memberNamesMap');
            debugPrint('Final memberNamesMap: $memberNamesMap');
          } else {
            print('Profile API error: ${profileData['status']} - ${profileData['message']}');
            debugPrint('Profile API error: ${profileData['status']} - ${profileData['message']}');
          }
        } else {
          print('Profile API call failed: ${profileResponse?.statusCode}');
          debugPrint('Profile API call failed: ${profileResponse?.statusCode}');
        }
      } catch (e) {
        // If API call fails, continue without names
        debugPrint('Error fetching member names: $e');
      }
    }
    
    // Create controllers for all members (including alluser)
    final Map<String, TextEditingController> controllers = {};
    final Map<String, bool> changedMap = {};
    for (final member in allMembers) {
      if (member == 'alluser') {
        // Use the existing _allUserController
        controllers[member] = _allUserController;
      } else {
        controllers[member] = TextEditingController(text: notes[member] ?? '');
      }
      changedMap[member] = false;
    }

    // Set selected member (default to current user, or first member)
    final currentUsername = prefs.getString('loggedInUsername') ?? 'guest';
    final selectedMember = allMembers.contains(currentUsername) ? currentUsername : (allMembers.isNotEmpty ? allMembers.first : null);
    
    setState(() {
      notesMap = notes;
      allMembersSet = allMembers;
      controllersMap = controllers;
      notesChangedMap = changedMap;
      this.memberNamesMap = memberNamesMap; // Store names from readprofile API
      _selectedMember = selectedMember;
      _isLoading = false;
    });
  }
  
  String _getDisplayName(String username) {
    // Special case for "alluser"
    if (username == 'alluser') {
      return '🌐 All Users';
    }
    // Return name if available and not empty, otherwise return username
    final name = memberNamesMap[username];
    return (name != null && name.isNotEmpty) ? name : username;
  }
  
  List<String> _getAllMembers() {
    final members = allMembersSet.toList();
    // Sort with "alluser" first, then alphabetically
    members.sort((a, b) {
      if (a == 'alluser') return -1;
      if (b == 'alluser') return 1;
      return a.compareTo(b);
    });
    return members;
  }

  Widget _buildNotesView(String member, String currentUsername) {
    final isAllUser = member == 'alluser';
    final isCurrentUser = member == currentUsername;
    final controller = controllersMap[member];
    final isSaving = isAllUser ? _isSavingAllUserNote : (_savingUsername == member);
    final hasChanges = isAllUser ? _allUserNoteChanged : (notesChangedMap[member] == true);
    
    if (controller == null) {
      return Center(
        child: Text(
          'Loading notes...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member name header
            Row(
              children: [
                Icon(
                  isAllUser ? Icons.public : Icons.person, 
                  color: isAllUser ? Colors.green : Theme.of(context).primaryColor
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(member),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: (isCurrentUser || isAllUser) ? FontWeight.bold : FontWeight.normal,
                          color: isAllUser ? Colors.green : (isCurrentUser ? Colors.blue : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                if ((isCurrentUser || isAllUser) && hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 8.0),
                    child: Text(
                      '(unsaved)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (isCurrentUser || isAllUser)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: (isSaving || !hasChanges) ? null : () {
                          _updateNotesOnServer(member, controller.text);
                        },
                        child: isSaving
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
                                  Text('Saving...'),
                                ],
                              )
                            : Text('Save Notes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Notes text field
            TextField(
              controller: controller,
              maxLines: null,
              enabled: (isCurrentUser || isAllUser) && !_isLoading && !isSaving,
              readOnly: !isCurrentUser && !isAllUser, // Read-only for other users
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: isAllUser ? 'All Users Note (Shared)' : 'Notes',
                hintText: (isCurrentUser || isAllUser)
                    ? (isAllUser ? 'Write a note visible to all members...' : 'Write your notes here...') 
                    : 'No notes yet',
                filled: !isCurrentUser && !isAllUser,
                fillColor: Colors.grey[100],
              ),
              onChanged: (isCurrentUser || isAllUser) ? (value) {
                setState(() {
                  if (isAllUser) {
                    _allUserNoteChanged = true;
                  } else {
                    notesChangedMap[member] = true;
                  }
                });
              } : null,
            ),
            // Save button (for current user or alluser)
            if (isCurrentUser || isAllUser)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: (isSaving || !hasChanges) ? null : () {
                        if (isAllUser) {
                          _updateAllUserNote();
                        } else {
                          _updateNotesOnServer(member, controller.text);
                        }
                      },
                      child: isSaving
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
                                Text('Saving...'),
                              ],
                            )
                          : Text('Save Notes'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if current user has unsaved changes or if All User note has unsaved changes
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('loggedInUsername') ?? 'guest';
    if (notesChangedMap[currentUsername] == true || _allUserNoteChanged) {
      // Show confirmation dialog if there are unsaved changes
      return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Are you sure you want to leave without saving?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Stay on the page
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Leave without saving
                    },
                    child: const Text('Leave'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              );
            },
          ) ??
          false; // Default to false if dialog is dismissed
    }
    return true; // Allow back navigation if no unsaved changes
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('loggedInUsername') ?? 'guest'),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data ?? 'guest';
        final allMembers = _getAllMembers();
        
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.title} - Notes',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadNotes();
                  },
                  tooltip: 'Refresh Notes',
                ),
              ],
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : allMembers.isEmpty
                      ? Center(
                          child: Text(
                            'No members yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Members list
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people, color: Theme.of(context).primaryColor),
                                      SizedBox(width: 8),
                                      Text(
                                        'Members',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: allMembers.map<Widget>((member) {
                                      final isAllUser = member == 'alluser';
                                      final isCurrentUser = member == currentUsername;
                                      final isSelected = member == _selectedMember;
                                      final hasChanges = isAllUser 
                                          ? _allUserNoteChanged 
                                          : (notesChangedMap[member] == true && isCurrentUser);
                                      final displayName = _getDisplayName(member);
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMember = member;
                                          });
                                        },
                                        child: Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: TextStyle(
                                                      fontWeight: (isCurrentUser || isAllUser) ? FontWeight.bold : FontWeight.normal,
                                                      color: isSelected 
                                                          ? (isAllUser ? Colors.green : (isCurrentUser ? Colors.blue : Colors.black87))
                                                          : (isAllUser ? Colors.green[300] : (isCurrentUser ? Colors.blue[300] : Colors.grey[600])),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (hasChanges)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4.0),
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: 8,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          backgroundColor: isSelected
                                              ? (isAllUser
                                                  ? Colors.green.withOpacity(0.2)
                                                  : (isCurrentUser 
                                                      ? Colors.blue.withOpacity(0.2)
                                                      : Colors.grey.withOpacity(0.2)))
                                              : Colors.transparent,
                                          side: BorderSide(
                                            color: isSelected
                                                ? (isAllUser ? Colors.green : (isCurrentUser ? Colors.blue : Colors.grey))
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, thickness: 1),
                            // Selected member's notes below
                            Expanded(
                                child: _selectedMember == null
                                    ? SingleChildScrollView(
                                        physics: AlwaysScrollableScrollPhysics(),
                                        child: Container(
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          child: Center(
                                            child: Text(
                                              'Select a member to view notes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildNotesView(_selectedMember!, currentUsername),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }
}