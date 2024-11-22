import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _businessHoursEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();

      if (settingsDoc.exists) {
        setState(() {
          _businessHoursEnabled = settingsDoc['businessHoursEnabled'] ?? true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    }
  }

  Future<void> _toggleBusinessHours(bool isEnabled) async {
    try {
      await FirebaseFirestore.instance.collection('settings').doc('general').update({
        'businessHoursEnabled': isEnabled,
      });

      setState(() {
        _businessHoursEnabled = isEnabled;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    }
  }

  void _manageAdminAccounts() {
    // Implement manage admin accounts functionality
    // You can create a new screen or a dialog for managing admin accounts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Business Hours'),
            value: _businessHoursEnabled,
            onChanged: _toggleBusinessHours,
          ),
          ListTile(
            title: Text('Manage Admin Accounts'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _manageAdminAccounts,
          ),
        ],
      ),
    );
  }
}
