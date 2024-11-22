// subscription_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:g_g/screens/subscription/deluxe_meal_selection_screen.dart';
import 'standard_meal_selection_screen.dart';

class SubscriptionSetupScreen extends StatefulWidget {
  @override
  _SubscriptionSetupScreenState createState() => _SubscriptionSetupScreenState();
}

class _SubscriptionSetupScreenState extends State<SubscriptionSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedStartDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSubscription();
  }

  // Check if subscription exists
  Future<void> _checkExistingSubscription() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Handle unauthenticated user
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final QuerySnapshot subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (subscriptionQuery.docs.isNotEmpty) {
        final subscriptionData = subscriptionQuery.docs.first.data() as Map<String, dynamic>;
        final String planType = subscriptionData['planType'] ?? '';

        // Navigate to the appropriate screen based on the plan type
        if (planType == 'Standard') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => StandardMealSelectionScreen()),
          );
        } else if (planType == 'Deluxe') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DeluxeMealSelectionScreen()),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subscription: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create a new subscription
  // Create a new subscription
  Future<void> _createSubscription({required String planType}) async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      // Handle unauthenticated user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = user.uid;
    final subscriptionId = _firestore.collection('subscriptions').doc().id; // Generate subscription ID
    final subscriptionRef = _firestore.collection('subscriptions').doc(subscriptionId);

    // Set plan-specific attributes
    int totalMeals = planType == 'Standard' ? 30 : 60;
    int remainingPauses = planType == 'Standard' ? 15 : 30;

    // Initialize meal selections for the subscription duration
    Map<String, dynamic> initialMealSelections = {};
    for (int i = 0; i < totalMeals; i++) {
      DateTime day = _selectedStartDate!.add(Duration(days: i));
      String dateKey = _formatDate(day);

      if (planType == 'Standard') {
        // Standard plan: 1 meal per day, 1 pause allowed
        initialMealSelections[dateKey] = {
          'afternoonMeal': 'Regular Meal',
          'pausedAfternoon': false,
          'eveningMeal': null,
          'pausedEvening': null,
          'date': Timestamp.fromDate(day),
        };
      } else if (planType == 'Deluxe') {
        // Deluxe plan: 2 meals per day, 2 pauses allowed
        initialMealSelections[dateKey] = {
          'afternoonMeal': 'Regular Meal',
          'pausedAfternoon': false,
          'eveningMeal': 'Regular Meal',
          'pausedEvening': false,
          'date': Timestamp.fromDate(day),
        };
      }
    }

    try {
      await subscriptionRef.set({
        'subscriptionId': subscriptionId, // Add subscription ID
        'userId': userId,
        'startDate': Timestamp.fromDate(_selectedStartDate!),
        'endDate': Timestamp.fromDate(_selectedStartDate!.add(Duration(days: totalMeals - 1))),
        'createdAt': Timestamp.now(),
        'mealSelections': initialMealSelections,
        'totalMeals': totalMeals,
        'remainingPauses': remainingPauses,
        'purchasedPauses': 0,
        'planType': planType, // Add plan type
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription created successfully!')),
      );

      // Navigate to the appropriate MealSelectionScreen based on plan type
      if (planType == 'Standard') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => StandardMealSelectionScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DeluxeMealSelectionScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating subscription: $e')),
      );
    }
  }


  // Format Date to 'YYYY-MM-DD'
  String _formatDate(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Subscription Setup', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Your Subscription Start Date',
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        _selectedStartDate == null
                            ? 'Select Start Date'
                            : 'Start Date: ${_formatDateDisplay(_selectedStartDate!)}',
                        style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedStartDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => _createSubscription(planType: 'Standard'),
                      child: Text(
                        'Start Standard Subscription',
                        style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _createSubscription(planType: 'Deluxe'),
                      child: Text(
                        'Start Deluxe Subscription',
                        style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Format Date for display 'DD/MM/YYYY'
  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}

