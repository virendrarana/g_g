import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSubscriptionTrackingScreen extends StatefulWidget {
  @override
  _AdminSubscriptionTrackingScreenState createState() =>
      _AdminSubscriptionTrackingScreenState();
}

class _AdminSubscriptionTrackingScreenState
    extends State<AdminSubscriptionTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<DocumentSnapshot> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  // Fetch all subscriptions from Firestore
  Future<void> _fetchSubscriptions() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection('subscriptions').get();
      setState(() {
        _subscriptions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching subscriptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subscriptions.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build each subscription's detailed card
  Widget _buildSubscriptionCard(DocumentSnapshot subscription) {
    final data = subscription.data() as Map<String, dynamic>;
    final String userId = data['userId'];
    final Timestamp startDate = data['startDate'];
    final Timestamp endDate = data['endDate'];
    final Map<String, dynamic> mealSelections = data['mealSelections'] ?? {};

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: ExpansionTile(
        title: Text(
          'Subscription: $userId',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.deepPurple,
          ),
        ),
        subtitle: Text(
          'Start Date: ${_formatDateDisplay(startDate.toDate())} - '
              'End Date: ${_formatDateDisplay(endDate.toDate())}',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        children: [
          _buildMealDetails(mealSelections),
        ],
      ),
    );
  }

  // Build meal details with paused and changed meals
  Widget _buildMealDetails(Map<String, dynamic> mealSelections) {
    List<Widget> mealWidgets = mealSelections.entries.map((entry) {
      final String date = entry.key;
      final Map<String, dynamic> mealData = entry.value;

      return ListTile(
        title: Text(
          _formatDateDisplay(DateTime.parse(date)),
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mealData['paused'] == true)
              Text(
                'Day Paused',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            if (mealData['afternoonMeal'] != null)
              Text(
                'Afternoon Meal: ${mealData['afternoonMeal']}',
                style: TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.w500),
              ),
            if (mealData['eveningMeal'] != null)
              Text(
                'Evening Meal: ${mealData['eveningMeal']}',
                style: TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      );
    }).toList();

    return Column(children: mealWidgets);
  }

  // Format Date for display 'DD/MM/YYYY'
  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Subscriptions',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          return _buildSubscriptionCard(_subscriptions[index]);
        },
      ),
    );
  }
}
