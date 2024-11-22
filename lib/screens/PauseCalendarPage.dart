import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';



class PauseCalendarPage extends StatefulWidget {
  final Map<String, dynamic> subscriptionData;

  PauseCalendarPage(this.subscriptionData);

  @override
  _PauseCalendarPageState createState() => _PauseCalendarPageState();
}

class _PauseCalendarPageState extends State<PauseCalendarPage> {
  List<DateTime> _pausedDays = [];
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.subscriptionData['subscriptionStartDate'];
    _firstDay = widget.subscriptionData['subscriptionStartDate'];
    _lastDay = widget.subscriptionData['subscriptionEndDate'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Your Subscription'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _pausedDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                if (_pausedDays.contains(selectedDay)) {
                  _pausedDays.remove(selectedDay);
                } else if (_pausedDays.length < widget.subscriptionData['pauseLimit']) {
                  _pausedDays.add(selectedDay);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You have reached the pause limit!')),
                  );
                }
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmPausedDays(),
            child: Text("Confirm Paused Days"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPausedDays() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final CollectionReference subscriptionCollection =
    FirebaseFirestore.instance.collection('subscriptions');

    // Update the paused days in Firestore
    await subscriptionCollection
        .where('userId', isEqualTo: userId)
        .where('subscriptionStartDate', isEqualTo: Timestamp.fromDate(_firstDay))
        .get()
        .then((snapshot) {
      snapshot.docs.first.reference.update({
        'pausedDays': _pausedDays.map((day) => Timestamp.fromDate(day)).toList(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paused days confirmed!')),
    );
  }
}
