import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:g_g/screens/subscription/standard_meal_selection_screen.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  final List<MapEntry<String, MealDay>> pastMeals;

  SubscriptionHistoryScreen({required this.pastMeals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subscription History',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: pastMeals.isEmpty
          ? Center(
        child: Text(
          'No past meals to display.',
          style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: pastMeals.length,
        itemBuilder: (context, index) {
          final entry = pastMeals[index];
          DateTime day = entry.value.date ?? DateTime.now();
          String displayDate = _formatDateDisplay(day);
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            color: entry.value.paused
                ? Colors.red.shade100
                : Colors.green.shade100,
            child: ListTile(
              leading: Icon(
                entry.value.paused
                    ? Icons.pause_circle_filled
                    : Icons.check_circle,
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
                style: TextStyle(
                    color: Colors.redAccent.shade700,
                    fontWeight: FontWeight.w600),
              )
                  : Text(
                'Meal: ${entry.value.meal}',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }

  // Format Date for display 'DD/MM/YYYY'
  String _formatDateDisplay(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }
}