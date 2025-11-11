import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/dialog_utils.dart';

class EditHabitPage extends StatefulWidget {
  final String habitId;
  final String currentTitle;
  final String currentLink;

  const EditHabitPage({
    super.key,
    required this.habitId,
    required this.currentTitle,
    required this.currentLink,
  });

  @override
  _EditHabitPageState createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  late TabController _tabController;
  bool _isLoading = false;
  bool _isLinkValid = true;
  bool _isTitleValid = true;
  
  // Members tab state
  List<String> _members = [];
  String? _owner; // Store the owner separately
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController(text: widget.currentTitle);
    _linkController = TextEditingController(text: widget.currentLink);
    _isLinkValid = DialogUtils.isValidUrl(widget.currentLink);
    _isTitleValid = widget.currentTitle.isNotEmpty;
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _isTitleValid && 
           (_linkController.text.isEmpty || _isLinkValid) && 
           !_isLoading;
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/readhabit');
    final body = {'token': token};
    final response = await safeHttpPost(url, body: body);

    if (response != null && response.statusCode == 200) {
      final data = safeJsonDecode(response.body);
      if (data != null && data['status'] == 'ok') {
        final List<dynamic> habits = (data['data'] ?? []) as List<dynamic>;
        for (final habit in habits) {
          final h = habit as Map<String, dynamic>;
          if (h['id']?.toString() == widget.habitId) {
            // Extract owner (username) from the habit data
            final owner = h['username']?.toString() ?? '';
            
            // Extract members from the habit data
            final membersData = h['members'];
            List<String> membersList = [];
            
            // Add owner first if exists
            if (owner.isNotEmpty) {
              membersList.add(owner);
            }
            
            // Add other members
            if (membersData != null && membersData is List) {
              for (final member in membersData) {
                if (member is Map) {
                  final memberName = member['member']?.toString() ?? '';
                  if (memberName.isNotEmpty && memberName != owner) {
                    // Don't add duplicate if owner is already in members
                    if (!membersList.contains(memberName)) {
                      membersList.add(memberName);
                    }
                  }
                } else if (member is String) {
                  if (member.isNotEmpty && member != owner) {
                    // Don't add duplicate if owner is already in members
                    if (!membersList.contains(member)) {
                      membersList.add(member);
                    }
                  }
                }
              }
            }
            
            setState(() {
              _owner = owner.isNotEmpty ? owner : null;
              _members = membersList;
              _isLoadingMembers = false;
            });
            return;
          }
        }
      }
    }
    
    setState(() {
      _isLoadingMembers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Habit',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 201, 184).withOpacity(0.7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _isLoading ? null : _deleteHabit,
            tooltip: 'Delete Habit',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEditTab(),
            _buildMembersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Habit Title',
              hintText: 'e.g., Read Books',
              border: OutlineInputBorder(),
              errorText: !_isTitleValid ? 'Please enter a title' : null,
            ),
            onChanged: (value) {
              setState(() {
                _isTitleValid = value.isNotEmpty;
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Habit Link (Optional)',
              hintText: 'e.g., https://example.com',
              border: OutlineInputBorder(),
              errorText: _linkController.text.isNotEmpty && !_isLinkValid
                  ? 'Please enter a valid URL with proper domain (e.g., https://example.com)'
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _isLinkValid = DialogUtils.isValidUrl(value);
              });
            },
          ),
          SizedBox(height: 32),
          _isLoading 
            ? Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Saving changes...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : CustomButton(
                text: 'Save Changes',
                onPressed: _canSave ? () => _saveChanges() : null,
              ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_isLoadingMembers) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _showAddMemberDialog,
                    tooltip: 'Add Member',
                    color: Theme.of(context).primaryColor,
                  ),
                  // IconButton(
                  //   icon: Icon(Icons.refresh),
                  //   onPressed: _loadMembers,
                  //   tooltip: 'Refresh Members',
                  // ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMembers,
            child: _members.isEmpty
                ? SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No members yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddMemberDialog,
                              icon: Icon(Icons.add),
                              label: Text('Add Member'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isOwner = member == _owner;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: isOwner ? Colors.blue[50] : null,
                        child: ListTile(
                          leading: Icon(
                            isOwner ? Icons.person : Icons.person_outline,
                            color: isOwner ? Colors.blue : Theme.of(context).primaryColor,
                          ),
                          title: Row(
                            children: [
                              Text(
                                member,
                                style: TextStyle(
                                  fontWeight: isOwner ? FontWeight.bold : FontWeight.w500,
                                  color: isOwner ? Colors.blue[900] : null,
                                ),
                              ),
                              if (isOwner)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Chip(
                                    label: Text(
                                      'Owner',
                                      style: TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          trailing: isOwner
                              ? Icon(Icons.star, color: Colors.amber, size: 20)
                              : IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _removeMember(member),
                                  tooltip: 'Remove Member',
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMemberDialog() async {
    final TextEditingController memberController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Member'),
          content: TextField(
            controller: memberController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final memberName = memberController.text.trim();
                if (memberName.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _addMember(memberName);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMember(String member) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/addmember');
    final body = {
      'habitid': widget.habitId,
      'member': member,
      'token': token,
    };
    final response = await safeHttpPost(url, body: body);

    if (response != null && response.statusCode == 200) {
      final data = safeJsonDecode(response.body);
      if (data != null && data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMembers(); // Reload members list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data?['message']?.toString() ?? 'Failed to add member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(String member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to remove $member from this habit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/deletemember');
    final body = {
      'habitid': widget.habitId,
      'member': member,
      'token': token,
    };
    final response = await safeHttpPost(url, body: body);

    if (response != null && response.statusCode == 200) {
      final data = safeJsonDecode(response.body);
      if (data != null && data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMembers(); // Reload members list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data?['message']?.toString() ?? 'Failed to remove member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate title
    if (!_isTitleValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate URL
    if (_linkController.text.isNotEmpty && !_isLinkValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL with proper domain (e.g., https://example.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If link is empty, show confirmation dialog
    if (_linkController.text.isEmpty) {
      final shouldContinue = await DialogUtils.showLinkValidationDialog(context);
      if (!shouldContinue) return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Update title
    final updateNameUrl = Uri.parse('$apiBase/updatehabit');
    final updateNameBody = {
      'id': widget.habitId,
      'newname': 'name',
      'newdata': _titleController.text,
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
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final updateNameData = jsonDecode(updateNameResp.body);
    if (updateNameData['status'] != 'ok') {
      final errorMsg = updateNameData['message']?.toString() ?? 'Failed to update title';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Update URL if not empty
    if (_linkController.text.isNotEmpty) {
      final updateUrlUrl = Uri.parse('$apiBase/updatehabit');
      final updateUrlBody = {
        'id': widget.habitId,
        'newname': 'url',
        'newdata': _linkController.text,
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
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final updateUrlData = jsonDecode(updateUrlResp.body);
      if (updateUrlData['status'] != 'ok') {
        final errorMsg = updateUrlData['message']?.toString() ?? 'Failed to update link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

      // Pop back to previous page with updated data
      Navigator.of(context).pop({
        'title': _titleController.text,
        'link': _linkController.text,
      });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteHabit() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habit'),
        content: Text('Are you sure you want to delete this habit? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('$apiBase/deletehabit');
    final body = {
      'id': widget.habitId,
      'token': token,
    };
    await safeHttpPost(url, body: body);

    // Pop back to previous page with delete flag
    Navigator.of(context).pop({'deleted': true});

    setState(() {
      _isLoading = false;
    });
  }
}