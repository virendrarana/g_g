import 'package:flutter/material.dart';

class CustomSearchVegModeRow extends StatefulWidget {
  final bool isVeg;
  final ValueChanged<bool> onVegModeChanged;
  final ValueChanged<String> onSearchChanged;

  const CustomSearchVegModeRow({
    Key? key,
    required this.isVeg,
    required this.onVegModeChanged,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  _CustomSearchVegModeRowState createState() => _CustomSearchVegModeRowState();
}

class _CustomSearchVegModeRowState extends State<CustomSearchVegModeRow> {
  late bool isVeg;
  final FocusNode _searchFocusNode = FocusNode(); // Focus node for search bar

  @override
  void initState() {
    super.initState();
    isVeg = widget.isVeg;
  }

  @override
  void dispose() {
    _searchFocusNode.dispose(); // Dispose focus node to avoid memory leaks
    super.dispose();
  }

  void _toggleVegMode(bool value) {
    setState(() {
      isVeg = value;
      widget.onVegModeChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),

          // Search Bar
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Positioning shadow
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      focusNode: _searchFocusNode,
                      onChanged: widget.onSearchChanged,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Search for items...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Veg Mode Label and Switch
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'VEG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Transform.scale(
                scale: 0.8, // Adjust this value to make the switch smaller
                child: Switch(
                  value: isVeg,
                  onChanged: _toggleVegMode,
                  activeColor: button_color,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
}
