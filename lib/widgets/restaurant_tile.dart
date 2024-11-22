import 'package:flutter/material.dart';
import '../screens/restaurant_menu_screen.dart';

class RestaurantTile extends StatelessWidget {
  final String imageUrl;
  final String restaurantId;

  RestaurantTile({
    required this.imageUrl,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to RestaurantMenuPage with the correct restaurantId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantMenuPage(restaurantId: restaurantId),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.all(8),
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageUrl,
            height: 200, // Set a fixed height for each tile
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.teal,
                ),
              );
            },
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 40,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
