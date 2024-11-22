import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _selectedRole = 'All'; // Default role filter set to 'All'
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        actions: [
          _buildRoleFilterDropdown(),
          _buildSortDropdown(),
        ],
      ),
      body: _buildUserList(),
    );
  }

  // Role Filter Dropdown Widget
  Widget _buildRoleFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DropdownButton<String>(
        value: _selectedRole,
        icon: Icon(Icons.filter_list, color: Colors.white),
        dropdownColor: Colors.white,
        onChanged: (String? newRole) {
          setState(() {
            _selectedRole = newRole!;
          });
        },
        items: ['All', 'Admin', 'Customer', 'DeliveryPartner', 'Promoter']
            .map<DropdownMenuItem<String>>((String role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(
              role,
              style: TextStyle(color: Colors.black),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Sort Dropdown Widget
  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Colors.white),
      onSelected: (String value) {
        setState(() {
          if (value == 'Sort Ascending') {
            _isAscending = true;
          } else if (value == 'Sort Descending') {
            _isAscending = false;
          }
        });
      },
      itemBuilder: (BuildContext context) {
        return {'Sort Ascending', 'Sort Descending'}.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  // User List Builder with Filter and Sort functionality
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;

        // Apply role filter
        List<DocumentSnapshot> filteredUsers = users.where((user) {
          var role = user['role'] ?? 'Unknown';
          return (_selectedRole == 'All' || role == _selectedRole);
        }).toList();

        // Sort users by name
        filteredUsers.sort((a, b) {
          var nameA = a['fullName']?.toLowerCase() ?? '';
          var nameB = b['fullName']?.toLowerCase() ?? '';
          return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            var user = filteredUsers[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(user['fullName'] ?? 'No Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? 'No Email'),
                    SizedBox(height: 5),
                    Text('Role: ${user['role'] ?? 'Unknown'}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'Edit Role') {
                      _editUserRole(user);
                    } else if (value == 'Delete') {
                      _confirmDeleteUser(user.id);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return {'Edit Role', 'Delete'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to edit user role
  void _editUserRole(DocumentSnapshot user) {
    String selectedRole = user['role'] ?? 'Customer'; // Default to Customer if no role
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Role for ${user['fullName']}'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            onChanged: (String? newRole) {
              setState(() {
                selectedRole = newRole!;
              });
            },
            items: ['Admin', 'Customer', 'DeliveryPartner', 'Promoter']
                .map<DropdownMenuItem<String>>((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              );
            }).toList(),
            decoration: InputDecoration(labelText: 'Select Role'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .update({'role': selectedRole});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User role updated to $selectedRole')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update role: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Confirmation dialog before deleting a user
  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteUser(userId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to delete user
  void _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }
}
