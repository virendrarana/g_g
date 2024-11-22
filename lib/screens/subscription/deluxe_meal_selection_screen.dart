import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/customer_homescreen.dart';
import 'package:g_g/screens/subscription/standard_meal_selection_screen.dart';
import 'package:g_g/screens/subscription/subscription_history_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class DeluxeMealSelectionScreen extends StatefulWidget {
  @override
  _DeluxeMealSelectionScreenState createState() => _DeluxeMealSelectionScreenState();
}

class _DeluxeMealSelectionScreenState extends State<DeluxeMealSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late DateTime _startDate = DateTime.now(); // Set initial fallback value
  late DateTime _endDate = DateTime.now().add(Duration(days: 29)); // Set fallback end date

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, DeluxeMealDay> _mealSelections = {}; // key: 'YYYY-MM-DD'
  int _remainingPauses = 30;
  final int _maxMeals = 60;
  int _usedMeals = 0;
  int _purchasedPauses = 0;

  double _walletBalance = 0.0;

  bool _isLoading = true;
  List<Restaurant> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _initializeMealSelection();
    // Ensure focused day is initialized to be valid with respect to start date.
    _focusedDay = DateTime.now().isBefore(_startDate) ? _startDate : DateTime.now();
  }

  // Initialize meal selection by fetching subscription data and restaurants
  Future<void> _initializeMealSelection() async {
    await _fetchSubscriptionData();
    await _fetchRestaurantsAndMenuItems();
    _initializeDefaultMealSelections(); // Automatically pre-fill the 30 days
    setState(() {
      _isLoading = false;
    });
  }

  // Pre-fill the first 30 days with "Regular Meal" by default
  void _initializeDefaultMealSelections() {
    // Initialize the end date to 30 days from the start date
    _endDate = _startDate.add(Duration(days: 29)); // 30 days including the start day
    for (int i = 0; i < 30; i++) {
      DateTime day = _startDate.add(Duration(days: i));
      String dateKey = _formatDate(day);
      _mealSelections.putIfAbsent(
        dateKey,
            () => DeluxeMealDay(
          afternoonMeal: "Regular Meal",
          eveningMeal: "Regular Meal",
          pausedAfternoon: false,
          pausedEvening: false,
          date: day,
        ),
      );
    }
  }

  // Fetch subscription data from Firestore
  Future<void> _fetchSubscriptionData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Query the subscription document based on the user ID
      QuerySnapshot subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        throw Exception('Subscription document does not exist.');
      }

      // Get the first subscription document (assuming there is only one active subscription per user)
      DocumentSnapshot subscriptionDoc = subscriptionQuery.docs.first;
      final data = subscriptionDoc.data() as Map<String, dynamic>;

      Timestamp? startTimestamp = data['startDate'];
      Timestamp? endTimestamp = data['endDate'];
      _purchasedPauses = data['purchasedPauses'] ?? 0;

      if (startTimestamp != null && endTimestamp != null) {
        _startDate = startTimestamp.toDate();
        _endDate = endTimestamp.toDate();
      }

      // Ensure the focused day is not before the start date.
      DateTime newFocusedDay = DateTime.now();
      if (newFocusedDay.isBefore(_startDate)) {
        newFocusedDay = _startDate;
      }

      setState(() {
        _remainingPauses = data['remainingPauses'] ?? 30;
        Map<String, dynamic> mealSelections = data['mealSelections'] ?? {};
        _mealSelections = mealSelections.map((key, value) => MapEntry(
          key,
          DeluxeMealDay(
            afternoonMeal: value['afternoonMeal'],
            eveningMeal: value['eveningMeal'],
            pausedAfternoon: value['pausedAfternoon'] ?? false,
            pausedEvening: value['pausedEvening'] ?? false,
            date: (value['date'] as Timestamp?)?.toDate(),
          ),
        ));
        _usedMeals = _mealSelections.values
            .where((md) => !(md.pausedAfternoon && md.pausedEvening))
            .length;
        _focusedDay = newFocusedDay;  // Set the focused day correctly
      });
    } catch (e) {
      print('Error fetching subscription data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subscription data: $e')),
      );
    }
  }



  // Fetch restaurants and their menu items from Firestore
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

  // Pause Handling: Add a new day if both meals are paused
  // Pause Handling: Add a new day if both meals are paused
  Future<void> _pauseDay(DateTime day, {required bool isAfternoon}) async {
    // Ensure that the day being paused is within the valid subscription range.
    if (day.isBefore(_startDate) || day.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected day is outside the subscription period.')),
      );
      return;
    }

    if (_remainingPauses <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more pauses available.')),
      );
      return;
    }

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return PauseConfirmationDialog(day: day, isAfternoon: isAfternoon);
      },
    ) ??
        false;

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

        // Update Firestore for the paused day and set corresponding meal to null.
        if (isAfternoon) {
          await subscriptionRef.update({
            'mealSelections.$dateKey.pausedAfternoon': true,
            'mealSelections.$dateKey.afternoonMeal': null,
            'remainingPauses': FieldValue.increment(-1),
          });
          setState(() {
            _mealSelections[dateKey]?.pausedAfternoon = true;
            _mealSelections[dateKey]?.afternoonMeal = null;
          });
        } else {
          await subscriptionRef.update({
            'mealSelections.$dateKey.pausedEvening': true,
            'mealSelections.$dateKey.eveningMeal': null,
            'remainingPauses': FieldValue.increment(-1),
          });
          setState(() {
            _mealSelections[dateKey]?.pausedEvening = true;
            _mealSelections[dateKey]?.eveningMeal = null;
          });
        }

        // If both meals are paused for the day, extend the calendar range.
        if (_mealSelections[dateKey]!.pausedAfternoon && _mealSelections[dateKey]!.pausedEvening) {
          _endDate = _endDate.add(Duration(days: 1));
          String newDateKey = _formatDate(_endDate);
          _mealSelections[newDateKey] = DeluxeMealDay(
            afternoonMeal: "Regular Meal",
            eveningMeal: "Regular Meal",
            pausedAfternoon: false,
            pausedEvening: false,
            date: _endDate,
          );

          // Update Firestore for the new extended day.
          await subscriptionRef.update({
            'mealSelections.$newDateKey': {
              'afternoonMeal': 'Regular Meal',
              'eveningMeal': 'Regular Meal',
              'pausedAfternoon': false,
              'pausedEvening': false,
              'date': Timestamp.fromDate(_endDate),
            },
            'endDate': Timestamp.fromDate(_endDate),
          });
        }

        // Adjust focused day if it is now out of range.
        if (_focusedDay.isBefore(_startDate)) {
          setState(() {
            _focusedDay = _startDate;
          });
        }

        setState(() {
          _remainingPauses -= 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Paused ${isAfternoon ? 'afternoon' : 'evening'} meal for ${_formatDateDisplay(day)}'),
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





  // Update Meal Delivery Count
  int _calculateDeliveredMeals() {
    int count = 0;
    _mealSelections.values.forEach((mealDay) {
      if (!mealDay.pausedAfternoon) count++;
      if (!mealDay.pausedEvening) count++;
    });
    return count;
  }

  // Build the calendar using TableCalendar
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
            DeluxeMealDay mealDay = _mealSelections[dateKey]!;
            if (mealDay.pausedAfternoon && mealDay.pausedEvening) {
              return _buildCalendarDay(
                day: day,
                color: Colors.redAccent.shade400,
                textColor: Colors.white,
                text: '${day.day}',
              );
            } else if (mealDay.afternoonMeal != null || mealDay.eveningMeal != null) {
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
        selectedBuilder: (context, day, focusedDay) {
          return _buildCalendarDay(
            day: day,
            color: Colors.deepPurple,
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

  // Function to filter past meals
  List<MapEntry<String, DeluxeMealDay>> _getPastMeals() {
    DateTime today = DateTime.now();
    List<MapEntry<String, DeluxeMealDay>> pastMeals = _mealSelections.entries
        .where((entry) =>
    entry.value.date != null && entry.value.date!.isBefore(today))
        .toList();

    // Sort past meals in ascending order by date
    pastMeals.sort((a, b) => a.value.date!.compareTo(b.value.date!));

    return pastMeals;
  }


  // Helper method to build calendar day with specific styling
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

  // Build List of Selections in ascending order for future days
  Widget _buildSelectionsList() {
    List<MapEntry<String, DeluxeMealDay>> sortedSelections = _mealSelections.entries.toList()
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
        color: (entry.value.pausedAfternoon && entry.value.pausedEvening)
            ? Colors.red.shade100
            : Colors.green.shade100,
        child: ListTile(
          leading: Icon(
            (entry.value.pausedAfternoon && entry.value.pausedEvening)
                ? Icons.pause_circle_filled
                : Icons.check_circle,
            color: (entry.value.pausedAfternoon && entry.value.pausedEvening)
                ? Colors.red
                : Colors.green,
          ),
          title: Text(
            displayDate,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.value.pausedAfternoon)
                Text(
                  'Afternoon: Paused',
                  style: TextStyle(
                      color: Colors.redAccent.shade700, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  'Afternoon Meal: ${entry.value.afternoonMeal ?? "Regular Meal"}',
                  style: TextStyle(
                      color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              if (entry.value.pausedEvening)
                Text(
                  'Evening: Paused',
                  style: TextStyle(
                      color: Colors.redAccent.shade700, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  'Evening Meal: ${entry.value.eveningMeal ?? "Regular Meal"}',
                  style: TextStyle(
                      color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
            ],
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

  // Handle purchasing extra pauses
  Future<void> _purchaseExtraPauses() async {
    // Implement payment gateway integration here
    // For demonstration, we'll assume the purchase is successful and add 5 pauses

    int extraPauses = 5;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscriptionRef = _firestore.collection('subscriptions').doc(user.uid);

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
          pastMeals: _getPastMeals().map((entry) {
            return MapEntry(
              entry.key,
              MealDay(
                meal: entry.value.afternoonMeal ?? entry.value.eveningMeal ?? "No Meal",
                paused: entry.value.pausedAfternoon && entry.value.pausedEvening,
                date: entry.value.date,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Show dialog to choose between changing meal or pausing the day
  void _selectDayOption(DateTime day) {
    showDialog(
      context: context,
      builder: (context) {
        return DeluxeOptionSelectionDialog(
          day: day,
          onMealSelected: _changeMeal,
          onPauseSelected: _pauseDay,
        );
      },
    );
  }

  // Handle changing meal selection for afternoon or evening
  Future<void> _changeMeal(DateTime day, {required bool isAfternoon}) async {
    String? selectedMeal = await showDialog<String>(
      context: context,
      builder: (context) {
        return MealSelectionDialog(
          restaurants: _restaurants,
          day: day,
          mealTime: isAfternoon ? 'Afternoon' : 'Evening',
        );
      },
    );

    if (selectedMeal != null) {
      await _saveMealChange(day, selectedMeal, isAfternoon: isAfternoon);
    }
  }

  // Save meal change to Firestore
  Future<void> _saveMealChange(DateTime day, String meal, {required bool isAfternoon}) async {
    String dateKey = _formatDate(day);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Query the subscription document based on the user ID
      QuerySnapshot subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) {
        throw Exception('Subscription document does not exist.');
      }

      DocumentSnapshot subscriptionDoc = subscriptionQuery.docs.first;
      final subscriptionRef = subscriptionDoc.reference;

      await _firestore.runTransaction((transaction) async {
        // Retrieve the subscription document
        DocumentSnapshot snapshot = await transaction.get(subscriptionRef);

        if (!snapshot.exists) {
          throw Exception('Subscription document does not exist.');
        }

        // Update the meal selection
        Map<String, dynamic> mealSelections = snapshot.get('mealSelections') ?? {};

        if (isAfternoon) {
          mealSelections[dateKey]['afternoonMeal'] = meal;
        } else {
          mealSelections[dateKey]['eveningMeal'] = meal;
        }

        // Commit the update to Firestore
        transaction.update(subscriptionRef, {
          'mealSelections': mealSelections,
        });

        // Update the local state
        setState(() {
          if (isAfternoon) {
            _mealSelections[dateKey]?.afternoonMeal = meal;
          } else {
            _mealSelections[dateKey]?.eveningMeal = meal;
          }
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Meal changed to "$meal" for ${isAfternoon ? 'afternoon' : 'evening'} on ${_formatDateDisplay(day)}'),
        ),
      );
    } catch (e) {
      print('Error changing meal selection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing meal selection: $e')),
      );
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

      // Confirmation dialog before proceeding
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
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

        // Navigate back to home screen
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





  // Build the main screen UI
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
        return false; // Prevent the default back button behavior
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
                    'Delivered Meals: ${_calculateDeliveredMeals()} / $_maxMeals',
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

// Helper classes
class DeluxeMealDay {
  String? afternoonMeal;
  String? eveningMeal;
  bool pausedAfternoon;
  bool pausedEvening;
  DateTime? date;

  DeluxeMealDay({
    required this.afternoonMeal,
    required this.eveningMeal,
    required this.pausedAfternoon,
    required this.pausedEvening,
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

  MenuItem({
    required this.name,
    required this.restaurantName,
  });
}

// Dialog for selecting a meal
class MealSelectionDialog extends StatefulWidget {
  final List<Restaurant> restaurants;
  final DateTime day;
  final String mealTime; // "Afternoon" or "Evening"

  MealSelectionDialog({
    required this.restaurants,
    required this.day,
    required this.mealTime,
  });

  @override
  _MealSelectionDialogState createState() => _MealSelectionDialogState();
}

class _MealSelectionDialogState extends State<MealSelectionDialog> {
  String? _selectedMeal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select ${widget.mealTime} Meal for ${_formatDateDisplay(widget.day)}',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
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

// Dialog for pausing a day
class PauseConfirmationDialog extends StatelessWidget {
  final DateTime day;
  final bool isAfternoon;

  PauseConfirmationDialog({required this.day, required this.isAfternoon});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Pause ${isAfternoon ? 'Afternoon' : 'Evening'} for ${_formatDateDisplay(day)}',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Do you want to pause this ${isAfternoon ? 'afternoon' : 'evening'} meal?',
        style: GoogleFonts.lato(),
      ),
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

// Dialog for selecting between changing meal and pausing
class DeluxeOptionSelectionDialog extends StatelessWidget {
  final DateTime day;
  final Function(DateTime, {required bool isAfternoon}) onMealSelected;
  final Function(DateTime, {required bool isAfternoon}) onPauseSelected;

  DeluxeOptionSelectionDialog({
    required this.day,
    required this.onMealSelected,
    required this.onPauseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Options for ${_formatDateDisplay(day)}',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      content: Text('Choose to change the meal or pause either the afternoon or evening meal.',
          style: GoogleFonts.lato()),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onMealSelected(day, isAfternoon: true);
          },
          child: Text('Change Afternoon Meal',
              style: GoogleFonts.lato(color: Colors.deepPurple)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onMealSelected(day, isAfternoon: false);
          },
          child: Text('Change Evening Meal',
              style: GoogleFonts.lato(color: Colors.deepPurple)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onPauseSelected(day, isAfternoon: true);
          },
          child: Text('Pause Afternoon',
              style: GoogleFonts.lato(color: Colors.red)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onPauseSelected(day, isAfternoon: false);
          },
          child: Text('Pause Evening',
              style: GoogleFonts.lato(color: Colors.red)),
        ),
      ],
    );
  }

  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}



