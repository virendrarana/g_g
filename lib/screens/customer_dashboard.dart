// customer_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:g_g/screens/cart_screen.dart';
import 'package:g_g/screens/location_selection_page.dart';
import 'package:g_g/screens/wallet_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../widgets/restaurant_tile.dart';
import 'package:badges/badges.dart' as badges; // Prefixed import

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with WidgetsBindingObserver {
  String _currentLocation = "Fetching location...";
  bool _isLoading = true;
  List<DocumentSnapshot> _restaurants = [];
  int _currentCarouselIndex = 0; // For tracking the current slide
  final CarouselSliderController _carouselController = CarouselSliderController();
  // Add a new variable to store the address label
  String _addressLabel = "home"; // Default label
  //String label = addressDoc.data()?['label'] ?? 'Others';


  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);


  final List<String> imgList = [
    'images/restaurant1.jpg',
    'images/restaurant2.jpg',
    'images/restaurant3.jpg',
    'images/restaurant4.jpg',
  ];

  bool _isPremium = false; // To track premium status
  bool _showSubscriptionBanner = false; // To control banner visibility

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLocation();
    _fetchRestaurants();
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Lifecycle changes to handle app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if banner should be shown when app is resumed
      _checkBannerVisibility();
    }
  }


  void backfillLabels() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    final users = await usersCollection.get();
    for (var user in users.docs) {
      final addresses = await usersCollection
          .doc(user.id)
          .collection('saved_addresses')
          .get();

      for (var address in addresses.docs) {
        if (!address.data().containsKey('label')) {
          await usersCollection
              .doc(user.id)
              .collection('saved_addresses')
              .doc(address.id)
              .update({'label': 'Others'}); // Default label
        }
      }
    }
  }


  // Fetch user's current location and address
  Future<void> _fetchLocation() async {
    setState(() {
      _currentLocation = "Please choose a location"; // Initial message
    });
  }

  void _showEditAddressDialog() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to log in to select an address.')),
      );
      return;
    }

    final addressesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_addresses')
        .get();

    final addresses = addressesSnapshot.docs;

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No saved addresses found. Please add one.')),
      );
      return;
    }

    // Show a selection dialog
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final addressData = addresses[index].data();
            final String address = addressData['address'] ?? 'Unknown Address';
            final String label = addressData['label'] ?? 'Others';

            return ListTile(
              title: Text(label.toUpperCase()),
              subtitle: Text(address),
              onTap: () {
                setState(() {
                  _currentLocation = address;
                  _addressLabel = label;
                });
                Navigator.pop(context); // Close the modal
              },
            );
          },
        );
      },
    );
  }


  // Fetch restaurants from Firestore
  Future<void> _fetchRestaurants() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('restaurants').get();
      setState(() {
        _restaurants = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load restaurants: $e")),
      );
    }
  }

  // Check if the user is a premium member
  Future<void> _checkPremiumStatus() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User is not logged in, handle accordingly
      return;
    }

    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isPremium = userDoc['isPremium'] ?? false;
        });

        if (!_isPremium) {
          _checkBannerVisibility();
        }
      }
    } catch (e) {
      // Handle errors if necessary
      print("Error fetching premium status: $e");
    }
  }

  // Check if the subscription banner should be shown
  Future<void> _checkBannerVisibility() async {
    setState(() {
      _showSubscriptionBanner = true;
    });
  }

  // Build wallet points display in the AppBar
  Widget _buildWalletPointsDisplay(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('wallets').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container();
        }

        final walletData = snapshot.data!.data() as Map<String, dynamic>;
        final int points = walletData['points'];

        return Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletPage(),
                ),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.4),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: Offset(0, 3), // Change position of shadow
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: badges.Badge(
                      badgeContent: Text(
                        '$points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      badgeColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // Build the main UI
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55), // Adjust height as needed
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Disable default back button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Section
              GestureDetector(
                onTap: () async {
                  // Navigate to LocationSelectionPage
                  final selectedAddress = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionPage(),
                    ),
                  );
                  // Handle the selected address after returning from LocationSelectionPage
                  if (selectedAddress != null &&
                      selectedAddress is Map<String, dynamic>) {
                    final String address =
                        selectedAddress['address'] ?? 'Unknown Address';
                    final String label =
                        selectedAddress['label'] ?? 'Others'; // Default to 'Others' if no label provided

                    setState(() {
                      _currentLocation = address;
                      _addressLabel = label;
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 30),
                    SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _addressLabel.isNotEmpty
                              ? _addressLabel.toUpperCase()
                              : '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _currentLocation.isNotEmpty
                              ? _currentLocation
                              : 'Please choose a location', // Default message
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Cart Icon with Item Count
              Consumer<Cart>(
                builder: (context, cart, child) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartPage()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: button_color,
                            size: 28,
                          ),
                          SizedBox(width: 4),
                          if (cart.itemCount > 0)
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 5),
            _buildCarousel(),
            SizedBox(height: 10),
            _buildSecondCarousel(),
            SizedBox(height: 10),
            _buildRestaurantGrid(),
          ],
        ),
      ),
    );
  }







  Widget _buildCartIconWithCount(BuildContext context) {
    final cart = Provider.of<Cart>(context); // Access cart to get item count

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(), // Navigate to CartPage
            ),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.4),
                spreadRadius: 3,
                blurRadius: 10,
                offset: Offset(0, 3), // Adjust shadow position
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 28,
              ),
              if (cart.itemCount > 0) // Show badge only if items are in the cart
                Positioned(
                  top: 5,
                  right: 5,
                  child: badges.Badge(
                    badgeContent: Text(
                      '${cart.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    badgeColor: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  // Build the first carousel (e.g., featured restaurants)
  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduce padding slightly
      child: Column(
        children: [
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
              viewportFraction: 0.75, // Adjusted for showing part of the next/previous image
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            items: imgList.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0), // Spacing between items
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    item,
                    fit: BoxFit.cover,
                    width: 1000,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imgList.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                        .withOpacity(_currentCarouselIndex == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  // Build the second carousel (e.g., promotions)
  Widget _buildSecondCarousel() {
    final List<String> promoImages = [
      'images/promo_code.jpg',
      'images/promo_code_2.jpg',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: promoImages.length,
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 3.0,
              viewportFraction: 0.75, // Allows only the next image to peek
              enlargeCenterPage: true,
              enlargeStrategy: CenterPageEnlargeStrategy.height,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == promoImages.length - 1 ? 0 : 10.0,
                ), // Right padding to allow peeking effect
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    promoImages[index],
                    fit: BoxFit.cover,
                    width: 1000,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Dots Indicator for Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: promoImages.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                        .withOpacity(_currentCarouselIndex == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }




  // Build the restaurant grid
  Widget _buildRestaurantGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _restaurants.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2 / 2,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemBuilder: (context, index) {
          var restaurant = _restaurants[index];
          return RestaurantTile(
            imageUrl: restaurant['imageUrl'],
            // name: restaurant['name'],
            // description: restaurant['description'],
            restaurantId: restaurant.id,
          );
        },
      ),
    );
  }

  // Show a dialog to edit the address manually
  // void _showEditAddressDialog() async {
  //   final selectedAddress = await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => LocationSelectionPage()),
  //   );
  //
  //   if (selectedAddress != null && selectedAddress is Map<String, dynamic>) {
  //     final String address = selectedAddress['address'] ?? '';
  //     final String label = selectedAddress['label'] ?? 'Others'; // Provide default if label is missing
  //
  //     setState(() {
  //       _currentLocation = address;
  //       _addressLabel = label;
  //     });
  //   }
  // }



  Widget _buildPremiumOptionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.grey.shade100,
    );
  }

  void _showManualAddressInputDialog() {
    TextEditingController _addressController = TextEditingController(text: _currentLocation);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Delivery Address'),
          content: TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter your delivery address",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              onPressed: () {
                setState(() {
                  _currentLocation = _addressController.text.trim();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
