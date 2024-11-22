import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/customer_homescreen.dart';
import 'package:g_g/screens/subscription/subscription_history_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class StandardMealSelectionScreen extends StatefulWidget {
  @override
  _StandardMealSelectionScreenState createState() => _StandardMealSelectionScreenState();
}

class _StandardMealSelectionScreenState extends State<StandardMealSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 30));
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _walletBalance = 0;

  Map<String, MealDay> _mealSelections = {}; // key: 'YYYY-MM-DD'
  int _remainingPauses = 15;
  final int _maxMeals = 30;
  int _usedMeals = 0;
  int _purchasedPauses = 0;

  bool _isLoading = true;
  List<Restaurant> _restaurants = [];


  @override
  void initState() {
    super.initState();
    _initializeMealSelection();
    _focusedDay = DateTime.now().isBefore(_startDate) ? _startDate : DateTime.now();
  }

  Future<void> _initializeMealSelection() async {
    await _fetchSubscriptionData();
    await _fetchRestaurantsAndMenuItems();
    _initializeDefaultMealSelections();
    setState(() {
      _isLoading = false;
    });
  }

  void _initializeDefaultMealSelections() {
    for (int i = 0; i < 30; i++) {
      DateTime day = _startDate.add(Duration(days: i));
      String dateKey = _formatDate(day);
      _mealSelections.putIfAbsent(
        dateKey,
            () => MealDay(
          meal: "Regular Meal",
          paused: false,
          date: day,
        ),
      );
    }
  }

  Future<void> _fetchSubscriptionData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        throw Exception('Subscription document does not exist.');
      }

      DocumentSnapshot subscriptionDoc = subscriptionQuery.docs.first;
      final data = subscriptionDoc.data() as Map<String, dynamic>;

      Timestamp? startTimestamp = data['startDate'];
      Timestamp? endTimestamp = data['endDate'];
      _purchasedPauses = data['purchasedPauses'] ?? 0;

      if (startTimestamp != null && endTimestamp != null) {
        _startDate = startTimestamp.toDate();
        _endDate = endTimestamp.toDate();
      }

      DateTime newFocusedDay = DateTime.now();
      if (newFocusedDay.isBefore(_startDate)) {
        newFocusedDay = _startDate;
      }

      setState(() {
        _remainingPauses = data['remainingPauses'] ?? 15;
        Map<String, dynamic> mealSelections = data['mealSelections'] ?? {};
        _mealSelections = mealSelections.map((key, value) => MapEntry(
          key,
          MealDay(
            meal: value['meal'],
            paused: value['paused'] ?? false,
            date: (value['date'] as Timestamp?)?.toDate(),
          ),
        ));
        _usedMeals = _mealSelections.values.where((md) => !md.paused).length;
        _focusedDay = newFocusedDay;
      });
    } catch (e) {
      print('Error fetching subscription data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subscription data: $e')),
      );
    }
  }

  Future<void> _fetchRestaurantsAndMenuItems() async {
    try {
      final restaurantSnapshot = await _firestore.collection('restaurants').get();
      List<Restaurant> restaurants = [];

      for (var restaurantDoc in restaurantSnapshot.docs) {
        final menuSnapshot = await restaurantDoc.reference.collection('menuItems').get();
        List<MenuItem> menuItems = menuSnapshot.docs.map((doc) {
          return MenuItem(
            name: doc['name'],
            restaurantName: restaurantDoc['name'],
            price: doc['price'] ?? 200.0, // Add price here with a default value
          );
        }).toList();

        restaurants.add(Restaurant(
          name: restaurantDoc['name'],
          menuItems: menuItems,
        ));
      }

      setState(() {
        _restaurants = restaurants;
      });
    } catch (e) {
      print('Error fetching restaurants and menu items: $e');
    }
  }

  // Fetch wallet details for the current user
  Future<Map<String, dynamic>> _fetchWalletDetails() async {
    final user = _auth.currentUser;
    if (user == null) return {'points': 0.0, 'transactions': []};

    try {
      DocumentSnapshot walletDoc =
      await _firestore.collection('wallets').doc(user.uid).get();

      if (walletDoc.exists) {
        int points = walletDoc['points'] ?? 0;
        List<dynamic> transactions =
            walletDoc['transactions'] ?? [];

        return {'points': points, 'transactions': transactions};
      } else {
        return {'points': 0, 'transactions': []};
      }
    } catch (e) {
      print('Error fetching wallet details: $e');
      return {'points': 0, 'transactions': []};
    }
  }

// Handle the price difference logic with wallet usage
  Future<bool> _handlePriceDifference(int priceDifference) async {
    final walletDetails = await _fetchWalletDetails();
    int walletPoints = walletDetails['points'];

    if (priceDifference > 0) {
      // Cost is above 200, use points if available
      if (walletPoints >= priceDifference) {
        await _updateWallet(-priceDifference, 'Meal upgrade');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('₹$priceDifference deducted from wallet for meal upgrade.')),
        );
        return true;
      } else {
        // Prompt for additional payment
        bool proceedWithPayment = await _promptForAdditionalPayment(priceDifference - walletPoints);
        if (proceedWithPayment) {
          await _updateWallet(-walletPoints, 'Partial wallet payment');
          return true;
        } else {
          return false;
        }
      }
    } else {
      // Cost is below 200, refund the difference
      int refundAmount = priceDifference.abs();
      bool confirmRefund = await _promptForRefundConfirmation(refundAmount);
      if (confirmRefund) {
        await _updateWallet(refundAmount, 'Refund for meal change');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('₹$refundAmount credited to wallet.')),
        );
        return true;
      } else {
        return false;
      }
    }
  }

// Update wallet points and add a transaction record
  Future<void> _updateWallet(int amount, String description) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update the wallet points
      await _firestore.collection('wallets').doc(user.uid).update({
        'points': FieldValue.increment(amount),
        'transactionHistory': FieldValue.arrayUnion([
          {
            'description': description,
            'pointsadded': amount,
            'timestamp': Timestamp.now(),
          }
        ]),
      });
    } catch (e) {
      print("Error updating wallet: $e");
    }
  }

// Prompt the user for additional payment if points are insufficient
  Future<bool> _promptForAdditionalPayment(int amountRequired) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Insufficient Balance"),
          content: Text(
            "You need an additional ₹${amountRequired.toStringAsFixed(2)}. Would you like to proceed with the payment?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement the payment logic here
                Navigator.of(context).pop(true);
              },
              child: Text("Proceed to Pay"),
            ),
          ],
        );
      },
    ) ?? false;
  }

// Prompt the user for a refund confirmation
  Future<bool> _promptForRefundConfirmation(int refundAmount) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Refund Confirmation"),
          content: Text(
            "Would you like to add ₹${refundAmount.toStringAsFixed(2)} back to your wallet?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("No", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    ) ?? false;
  }














  int _getMealPrice(String mealName) {
    for (var restaurant in _restaurants) {
      for (var menuItem in restaurant.menuItems) {
        if (menuItem.name == mealName) {
          return menuItem.price;
        }
      }
    }
    return 200; // Default base price
  }



  Future<void> _changeMeal(DateTime day) async {
    String? selectedMeal = await showDialog<String>(
      context: context,
      builder: (context) {
        return MealSelectionDialog(restaurants: _restaurants, day: day);
      },
    );

    if (selectedMeal != null) {
      String dateKey = _formatDate(day);
      int selectedMealPrice = _getMealPrice(selectedMeal);
      int basePrice = 200;
      int priceDifference = selectedMealPrice - basePrice;

      if (priceDifference != 0) {
        bool proceed = await _handlePriceDifference(priceDifference);
        if (!proceed) return; // Do not proceed if wallet balance is insufficient
      }
      // Update Firestore
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isEmpty) {
          throw Exception('Subscription document does not exist.');
        }

        final subscriptionRef = subscriptionQuery.docs.first.reference;

        await subscriptionRef.update({
          'mealSelections.$dateKey.meal': selectedMeal,
          'mealSelections.$dateKey.paused': false,
          'walletBalance': _walletBalance,
        });

        setState(() {
          _mealSelections[dateKey]?.meal = selectedMeal;
          _mealSelections[dateKey]?.paused = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal changed to "$selectedMeal" for ${_formatDateDisplay(day)}'),
          ),
        );
      } catch (e) {
        print('Error changing meal selection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing meal selection: $e')),
        );
      }
    }
  }


  Future<void> _pauseDay(DateTime day) async {
    if (_remainingPauses <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more pauses available.')),
      );
      return;
    }

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return PauseConfirmationDialog(day: day);
      },
    ) ?? false;

    if (confirm) {
      String dateKey = _formatDate(day);

      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isEmpty) {
          throw Exception('Subscription document does not exist.');
        }

        final subscriptionRef = subscriptionQuery.docs.first.reference;

        await subscriptionRef.update({
          'mealSelections.$dateKey.paused': true,
          'mealSelections.$dateKey.meal': null,
          'remainingPauses': FieldValue.increment(-1),
        });

        setState(() {
          _mealSelections[dateKey]?.paused = true;
          _mealSelections[dateKey]?.meal = null;
          _remainingPauses -= 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paused meal for ${_formatDateDisplay(day)}'),
          ),
        );
      } catch (e) {
        print('Error pausing day: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pausing day: $e')),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        throw Exception('No active subscription found.');
      }

      final subscriptionRef = subscriptionQuery.docs.first.reference;

      bool confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Cancel Subscription',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to cancel your subscription?',
              style: GoogleFonts.lato(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: GoogleFonts.lato(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes', style: GoogleFonts.lato()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ],
          );
        },
      ) ?? false;

      if (confirm) {
        await subscriptionRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription cancelled successfully!')),
        );

        // Navigate back to the customer home screen after cancellation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        );
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling subscription: $e')),
      );
    }
  }

  // Build the calendar widget
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: _startDate,
      lastDay: _endDate,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (selectedDay.isBefore(_startDate) || selectedDay.isAfter(_endDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected day is outside the subscription period.')),
          );
          return;
        }

        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });

        _selectDayOption(selectedDay);
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          String dateKey = _formatDate(day);
          if (_mealSelections.containsKey(dateKey)) {
            MealDay mealDay = _mealSelections[dateKey]!;
            if (mealDay.paused) {
              return _buildCalendarDay(
                day: day,
                color: Colors.redAccent.shade400,
                textColor: Colors.white,
                text: '${day.day}',
              );
            } else if (mealDay.meal != null) {
              return _buildCalendarDay(
                day: day,
                color: Colors.greenAccent.shade700,
                textColor: Colors.white,
                text: '${day.day}',
              );
            }
          }
          return null;
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildCalendarDay(
            day: day,
            color: Colors.amberAccent.shade400,
            textColor: Colors.white,
            text: '${day.day}',
          );
        },
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.amberAccent.shade400,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.purpleAccent.shade700,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: Colors.black87),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // Helper method to build a day in the calendar with specific styling
  Widget _buildCalendarDay({
    required DateTime day,
    required Color color,
    required Color textColor,
    required String text,
  }) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        width: 35,
        height: 35,
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Build the list of meal selections
  Widget _buildSelectionsList() {
    List<MapEntry<String, MealDay>> sortedSelections = _mealSelections.entries.toList()
      ..sort((a, b) {
        DateTime dateA = a.value.date ?? _startDate;
        DateTime dateB = b.value.date ?? _startDate;
        return dateA.compareTo(dateB);
      });

    List<Widget> selections = sortedSelections.map((entry) {
      DateTime day = entry.value.date ?? _startDate;
      String displayDate = _formatDateDisplay(day);
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: entry.value.paused ? Colors.red.shade100 : Colors.green.shade100,
        child: ListTile(
          leading: Icon(
            entry.value.paused ? Icons.pause_circle_filled : Icons.check_circle,
            color: entry.value.paused ? Colors.red : Colors.green,
          ),
          title: Text(
            displayDate,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: entry.value.paused
              ? Text(
            'Paused',
            style: TextStyle(color: Colors.redAccent.shade700, fontWeight: FontWeight.w600),
          )
              : Text(
            'Meal: ${entry.value.meal ?? "Regular Meal"}',
            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }).toList();

    return Expanded(
      child: ListView(
        children: selections,
      ),
    );
  }

  // Handle selecting a day option
  void _selectDayOption(DateTime day) {
    showDialog(
      context: context,
      builder: (context) {
        return OptionSelectionDialog(
          day: day,
          onMealSelected: _changeMeal,
          onPauseSelected: _pauseDay,
        );
      },
    );
  }

  // Format Date to 'YYYY-MM-DD'
  String _formatDate(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  // Format Date for display 'DD/MM/YYYY'
  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }

  // View Subscription History
  void _viewSubscriptionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionHistoryScreen(
          pastMeals: _mealSelections.entries
              .where((entry) => entry.value.date != null && entry.value.date!.isBefore(DateTime.now()))
              .toList(),
        ),
      ),
    );
  }

  // Handle purchasing extra pauses
  Future<void> _purchaseExtraPauses() async {
    // Implement payment gateway integration here
    // For demonstration, we'll assume the purchase is successful and add 5 pauses

    int extraPauses = 5;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        throw Exception('Subscription document does not exist.');
      }

      final subscriptionRef = subscriptionQuery.docs.first.reference;

      await subscriptionRef.update({
        'remainingPauses': FieldValue.increment(extraPauses),
        'purchasedPauses': FieldValue.increment(extraPauses),
      });

      setState(() {
        _remainingPauses += extraPauses;
        _purchasedPauses += extraPauses;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased $extraPauses extra pauses successfully!'),
        ),
      );
    } catch (e) {
      print('Error purchasing extra pauses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error purchasing extra pauses.')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Select Meals or Pause Days',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select Meals or Pause Days',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepPurple,
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              onPressed: _viewSubscriptionHistory,
              tooltip: 'Subscription History',
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.white),
              onPressed: _purchaseExtraPauses,
              tooltip: 'Purchase Extra Pauses',
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.white),
              onPressed: _cancelSubscription,
              tooltip: 'Cancel Subscription',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildCalendar(),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining Pauses: $_remainingPauses',
                    style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  Text(
                    'Used Meals: $_usedMeals / $_maxMeals',
                    style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            _buildSelectionsList(),
          ],
        ),
      ),
    );
  }
}

// Helper Classes and Dialogs

class MealDay {
  String? meal;
  bool paused;
  final DateTime? date;

  MealDay({
    required this.meal,
    required this.paused,
    this.date,
  });
}

class Restaurant {
  final String name;
  final List<MenuItem> menuItems;

  Restaurant({
    required this.name,
    required this.menuItems,
  });
}

class MenuItem {
  final String name;
  final String restaurantName;
  final int price;

  MenuItem({
    required this.name,
    required this.restaurantName,
    required this.price,
  });
}

class MealSelectionDialog extends StatefulWidget {
  final List<Restaurant> restaurants;
  final DateTime day;

  MealSelectionDialog({required this.restaurants, required this.day});

  @override
  _MealSelectionDialogState createState() => _MealSelectionDialogState();
}

class _MealSelectionDialogState extends State<MealSelectionDialog> {
  String? _selectedMeal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Meal for ${_formatDateDisplay(widget.day)}',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      content: widget.restaurants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: widget.restaurants.map((restaurant) {
            return ExpansionTile(
              title: Text(
                restaurant.name,
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600, color: Colors.deepPurple),
              ),
              children: restaurant.menuItems.map((menuItem) {
                return ListTile(
                  title: Text(menuItem.name, style: GoogleFonts.lato()),
                  onTap: () {
                    setState(() {
                      _selectedMeal = menuItem.name;
                    });
                  },
                  trailing: _selectedMeal == menuItem.name
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.lato(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _selectedMeal != null
              ? () {
            Navigator.of(context).pop(_selectedMeal);
          }
              : null,
          child: Text('Confirm', style: GoogleFonts.lato()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}

class PauseConfirmationDialog extends StatelessWidget {
  final DateTime day;

  PauseConfirmationDialog({required this.day});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pause ${_formatDateDisplay(day)}',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      content: Text('Do you want to pause this day?', style: GoogleFonts.lato()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.lato(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Pause', style: GoogleFonts.lato()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}

class OptionSelectionDialog extends StatelessWidget {
  final DateTime day;
  final Function(DateTime) onMealSelected;
  final Function(DateTime) onPauseSelected;

  OptionSelectionDialog({
    required this.day,
    required this.onMealSelected,
    required this.onPauseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Options for ${_formatDateDisplay(day)}',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      content: Text('Choose to change the meal or pause this day.',
          style: GoogleFonts.lato()),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onMealSelected(day);
          },
          child: Text('Change Meal',
              style: GoogleFonts.lato(color: Colors.deepPurple)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onPauseSelected(day);
          },
          child: Text('Pause Day',
              style: GoogleFonts.lato(color: Colors.red)),
        ),
      ],
    );
  }

  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}


