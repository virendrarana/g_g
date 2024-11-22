import 'dart:async';
import 'dart:math';
import 'package:g_g/widgets/app_bar_restaurant_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:g_g/screens/premium_member_screen.dart';
import 'package:g_g/services/cart_service.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/menu_item_model.dart';
import '../services/menu_item_service.dart';
import 'cart_screen.dart';

class RestaurantMenuPage extends StatefulWidget {
  final String restaurantId;

  RestaurantMenuPage({required this.restaurantId});

  @override
  _RestaurantMenuPageState createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MenuItemService _menuItemService = MenuItemService();
  late AnimationController _cartAnimationController;
  bool _isPremiumUser = false; // Track if the user is premium
  String? _restaurantImageUrl; // Store the restaurant image URL
  String _filterType = 'All'; // Filter type state variable
  double _averageRating = 0.0;
  int _totalRatings = 0;
  String _userName = "";
  bool _isLoadingCategories = true;
  String _searchQuery = "";
  bool _isVegOnly = false; // Track if Veg-Only filter is enabled
  final FocusNode _searchFocusNode = FocusNode(); // Initialize FocusNode
  bool _isSearching = false; // Track if the search bar is active
  final ValueNotifier<bool> _isCartVisible = ValueNotifier<bool>(false);
  final ValueNotifier<int> _totalCartItems = ValueNotifier<int>(0);
  final ValueNotifier<double> _totalCartAmount = ValueNotifier<double>(0.0);
  late Animation<double> _pulseAnimation;
  String? _selectedPortionSize; // Keeps track of the selected portion size
  late VideoPlayerController? _videoController;
  String? _videoUrl; // Store the video URL from Firestore
  List<String> _categories = [];



  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
    // Listen to cart changes
    final cart = Provider.of<Cart>(context, listen: false);
    cart.addListener(_updateCartVisibility);
    _videoController = null;
    _checkPremiumStatus();
    _fetchRestaurantDetails();
    _fetchRatingData(widget.restaurantId);
    _fetchUserName();
    _fetchCategoriesFromMenuItems();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _isCartVisible.dispose();
    _totalCartItems.dispose();
    _totalCartAmount.dispose();
    _videoController?.dispose();
    _cartAnimationController.dispose();

    // Remove cart listener
    Provider.of<Cart>(context, listen: false)
        .removeListener(_updateCartVisibility);

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // If no user is logged in, return early

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['fullName'] ??
              'Guest'; // Default to 'Guest' if name not found
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  void _updateCartVisibility() {
    final cart = Provider.of<Cart>(context, listen: false);
    setState(() {
      _isCartVisible.value =
          cart.itemCount > 0; // Toggle visibility based on cart count
      _totalCartItems.value = cart.itemCount;
      _totalCartAmount.value = cart.totalAmount;
    });
  }

  Future<void> _fetchRatingData(String menuItemId) async {
    try {
      DocumentSnapshot menuItemDoc = await FirebaseFirestore.instance
          .collection('menuItems')
          .doc(menuItemId)
          .get();

      if (menuItemDoc.exists) {
        setState(() {
          _totalRatings = menuItemDoc['totalRatings'] ?? 0;
          _averageRating = menuItemDoc['averageRating'] ?? 0.0;
        });
      }
    } catch (e) {
      print("Error fetching rating data: $e");
    }
  }

  Future<void> _saveRatingToFirestore(String menuItemId, double rating) async {
    try {
      DocumentReference menuItemRef =
          FirebaseFirestore.instance.collection('menuItems').doc(menuItemId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot menuItemDoc = await transaction.get(menuItemRef);

        if (menuItemDoc.exists) {
          int currentTotalRatings = menuItemDoc['totalRatings'] ?? 0;
          double currentAverageRating = menuItemDoc['averageRating'] ?? 0.0;

          // Calculate the new average rating
          double newAverageRating =
              ((currentAverageRating * currentTotalRatings) + rating) /
                  (currentTotalRatings + 1);

          // Update Firestore with new values
          transaction.update(menuItemRef, {
            'totalRatings': currentTotalRatings + 1,
            'averageRating': newAverageRating,
          });
        }
      });
    } catch (e) {
      print("Error saving rating: $e");
    }
  }

  // Check if the user is a premium member
  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _isPremiumUser = userDoc['isPremium'] ??
            false; // Assuming 'isPremium' is a boolean field in the user's document
      });
    } catch (e) {
      print("Error fetching user premium status: $e");
    }
  }

  // Fetch restaurant details, including the image URL
  Future<void> _fetchRestaurantDetails() async {
    print("Starting to fetch restaurant details...");  // Debugging point

    try {
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (restaurantDoc.exists) {
        print("Restaurant document exists.");
        print("Restaurant document data: ${restaurantDoc.data()}");

        setState(() {
          _videoUrl = restaurantDoc['videoUrl'];
        });

        print("Fetched video URL: $_videoUrl");

        if (_videoUrl != null && _videoUrl!.isNotEmpty) {
          try {
            _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!))
              ..initialize().then((_) {
                print("Video initialized successfully.");
                setState(() {});
                _videoController?.play();
                _videoController?.setLooping(true);
              }).catchError((error) {
                print("Error initializing video: $error");
              });
          } catch (e) {
            print("Unexpected error during video initialization: $e");
          }
        } else {
          print("Video URL is null or empty.");
        }
      } else {
        print("Restaurant document does not exist.");
      }
    } catch (e) {
      print("Error fetching restaurant details: $e");
    }
  }




  Widget _buildSearchBar() {
    return Container(
      height: 45,
      //margin: const EdgeInsets.symmetric(horizontal: 16.0), // Expand margin for wider appearance
      //padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding for inner content
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10), // Slightly rounder corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _searchFocusNode, // Manage focus with FocusNode
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '  Search for items...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = false; // Exit search mode
                _searchQuery = ''; // Clear search query
              });
              _searchFocusNode.unfocus(); // Remove focus
            },
            child: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
    );
  }


  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);

  final List<String> portionSizes = ['Small', 'Medium', 'Large'];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          SizedBox(height: 40),
          CustomSearchVegModeRow(
            isVeg: _isVegOnly,
            onVegModeChanged: (value) {
              setState(() {
                _isVegOnly = value;
              });
            },
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),

          Expanded(
            child: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 210,
                        floating: false,
                        automaticallyImplyLeading: false,
                        pinned: false,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildRestaurantMedia(),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          child: Container(
                            color: Colors.white,
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                    child: _buildFilterButtons(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: _buildMenuList(),
                ),
                _buildCartPopup(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _fetchCategoriesFromMenuItems() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Query menuItems subcollection of the specific restaurant
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menuItems')
          .get();

      // Extract unique categories from menuItems
      final categories = snapshot.docs
          .map((doc) => doc['category'] as String) // Extract 'category' field
          .toSet() // Convert to Set to ensure uniqueness
          .toList();

      setState(() {
        _categories = ['All', ...categories]; // Add "All" as the default option
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      print("Error fetching categories: $e");
    }
  }




  Widget _buildFilterButtons() {
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          // Dynamic Category Buttons
          ..._categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _filterType = category; // Set category filter
                  });
                },
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: _filterType == category ? Colors.green : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.green, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: _filterType == category ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }





// Modified _filterButton method
  Widget _filterButton(String filter, String? assetPath) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // Toggle the filter type
          _filterType = _filterType == filter ? 'All' : filter;
        });
      },
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: _filterType == filter ? Colors.green : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.green, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        filter,
        style: TextStyle(
          color: _filterType == filter ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildRestaurantMedia() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            // Video Player
            ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10),top:Radius.circular(10) ),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            // Play/Pause Button
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 30,
                    child: Icon(
                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_videoController != null && _videoController!.value.hasError) {
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            "Failed to load video",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    } else {
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(), // Show loading spinner
        ),
      );
    }
  }






  Widget _buildMenuList() {
    return StreamBuilder<List<MenuItem>>(
      stream: _menuItemService.streamMenuItemsByRestaurant(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading menu items.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var menuItems = snapshot.data ?? [];

        // Apply filters
        if (_isVegOnly) {
          menuItems = menuItems.where((item) => item.type == 'Veg').toList();
        }

        if (_searchQuery.isNotEmpty) {
          menuItems = menuItems
              .where((item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (menuItems.isEmpty) {
          return Center(child: Text('No menu items match your search.'));
        }

        return ListView.builder(
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            return _buildMenuItemCard(menuItems[index]);
          },
        );
      },
    );
  }





  void _incrementItemWithSize(MenuItem menuItem, String portionSize, Cart cart, {double? price}) {
    double priceToAdd = _isPremiumUser
        ? (price ?? menuItem.price) * 0.85
        : (price ?? menuItem.price);

    final cartItem = CartItem(
      id: '${menuItem.id}_$portionSize', // Unique ID for portion size
      name: '${menuItem.name} ($portionSize)', // Display portion size in name
      price: priceToAdd,
      quantity: 1,
      imageUrl: menuItem.imageUrl,
      portionSize: portionSize,
    );

    cart.addItem(cartItem);

    // Update cart state
    _totalCartItems.value = cart.itemCount;
    _totalCartAmount.value = cart.totalAmount;
    _isCartVisible.value = cart.itemCount > 0;

    _triggerCartAnimation();
  }


  // **Updated Cart Popup with Sparkle Animation**
  Widget _buildCartPopup() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isCartVisible,
      builder: (context, isVisible, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          // Elastic opening for premium feel
          bottom: isVisible ? 0 : -160,
          // Slide off-screen when hidden
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50), // Emerald Green
                    const Color(0xFF1B5E20), // Darker Green for depth
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildParticleEffect(), // Particle animation
                  _buildCartContent(), // Main cart content
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// **Particle Effect for Premium Look**
  Widget _buildParticleEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _cartAnimationController,
        builder: (context, child) {
          final progress = _cartAnimationController.value;
          return Stack(
            children: List.generate(10, (index) {
              final angle = (2 * pi / 10) * index;
              final radius = 50 * progress;
              final offset = Offset(
                radius * cos(angle),
                radius * sin(angle),
              );
              return Positioned(
                left: 50 + offset.dx,
                top: 50 + offset.dy,
                child: Opacity(
                  opacity: (1 - progress).clamp(0.0, 1.0),
                  child: Container(
                    width: 0,
                    height: 0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

// **Main Cart Content**
  Widget _buildCartContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildPulsingCartIcon(), // Pulsing cart icon
              const SizedBox(width: 15),
              _animatedCartItemsCount(), // Animated item count
              const SizedBox(width: 8),
              _animatedCartTotalAmount(), // Animated total amount
            ],
          ),
          Row(
            children: [
              _animatedViewCartText(), // Animated "View Cart" text
              const SizedBox(width: 8),
              _animatedArrowIcon(), // Animated arrow icon
            ],
          ),
        ],
      ),
    );
  }

// **Pulsing Cart Icon for Animation**
  Widget _buildPulsingCartIcon() {
    return AnimatedBuilder(
      animation: _cartAnimationController,
      builder: (context, child) {
        final scale = 1 + _cartAnimationController.value * 0.2;
        return Transform.scale(
          scale: scale,
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.white,
            size: 32,
          ),
        );
      },
    );
  }

// **Animated Cart Items Count with Scale Transition**
  Widget _animatedCartItemsCount() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: ValueListenableBuilder<int>(
        valueListenable: _totalCartItems,
        builder: (context, itemCount, child) {
          return Text(
            '$itemCount items',
            key: ValueKey(itemCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

// **Animated Total Cart Amount with Slide Effect**
  Widget _animatedCartTotalAmount() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: const Offset(0.0, 0.0),
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: ValueListenableBuilder<double>(
        valueListenable: _totalCartAmount,
        builder: (context, totalAmount, child) {
          return Text(
            '| ₹${totalAmount.toStringAsFixed(2)}',
            key: ValueKey(totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

// **Animated "View Cart" Text with Glow Effect**
  Widget _animatedViewCartText() {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: Colors.white70,
        end: Colors.white,
      ),
      duration: const Duration(milliseconds: 500),
      builder: (context, color, child) {
        return Text(
          'View Cart',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

// **Arrow Icon with Bounce Effect**
  Widget _animatedArrowIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: const Icon(
            Icons.arrow_circle_right_sharp,
            color: Colors.white,
            size: 25,
          ),
        );
      },
    );
  }

// **Trigger Animation on Cart Update**
  void _triggerCartAnimation() {
    _cartAnimationController.forward(from: 0.0).then((_) {
      _cartAnimationController.reverse();
    });
  }

  // Update _incrementItem to handle portion sizes


  void _decrementItem(MenuItem menuItem, Cart cart, {String? portionSize}) {
    // Remove item based on portion size if provided
    cart.removeItem(menuItem.id! + (portionSize ?? ""));

    // Update cart state using ValueNotifier
    _totalCartItems.value = cart.itemCount;
    _totalCartAmount.value = cart.totalAmount;
    _isCartVisible.value = cart.itemCount > 0;

    _cartAnimationController.forward().then((value) {
      _cartAnimationController.reverse();
    });
  }

  Widget _buildPortionTile(String portion, double? price, MenuItem menuItem,
      StateSetter localSetState) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.green.shade700,
          width: 1.5,
        ),
      ),
      elevation: 3,
      child: ListTile(
        title: Center(
          child: Text(
            '$portion - ₹${price?.toStringAsFixed(2) ?? 'N/A'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          _incrementItemWithSize(
            menuItem,
            portion,
            Provider.of<Cart>(context, listen: false),
            price: price,
          );

          // Update quantity in cart
          localSetState(() {});
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem menuItem) {
    // Determine the display price based on premium status
    double displayPrice = _isPremiumUser
        ? (menuItem.portionSizes != null && menuItem.portionSizes!.isNotEmpty
        ? menuItem.portionSizes!.values.first * 0.85
        : menuItem.price * 0.85)
        : (menuItem.portionSizes != null && menuItem.portionSizes!.isNotEmpty
        ? menuItem.portionSizes!.values.first
        : menuItem.price);

    double exclusivePrice = menuItem.portionSizes != null && menuItem.portionSizes!.isNotEmpty
        ? menuItem.portionSizes!.values.first * 0.85
        : menuItem.price * 0.85;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: IntrinsicHeight(
        child: Card(
          color: Tile_color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  menuItem.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Tile_color,
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
              // Title and Description Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          menuItem.type == 'Veg' ? 'images/veg_new.png' : 'images/non_veg.png',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      menuItem.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 20),
                    StatefulBuilder(
                      builder: (context, localSetState) {
                        int quantityInCart = Provider.of<Cart>(context, listen: false)
                            .getQuantity(menuItem.id! + (_selectedPortionSize ?? ""));

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${displayPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: quantityInCart > 0
                                  ? _buildQuantityControl(menuItem, quantityInCart, localSetState)
                                  : _buildAddButton(menuItem, localSetState),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Exclusive Pricing Section
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => PremiumMembershipPage()),
                        );
                      },
                      child: Container(
                        color: user_tile_color,
                        child: DottedBorder(
                          color: Colors.black,
                          strokeWidth: 1,
                          borderType: BorderType.RRect,
                          radius: Radius.circular(5),
                          dashPattern: [2, 2],
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(width: 10),
                                Text(
                                  ' ₹${exclusivePrice.toStringAsFixed(2)} ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Exclusively for '),
                                Image.asset(
                                  'images/border_image.png',
                                  width: 16,
                                  height: 16,
                                ),
                                const Text(' Users'),
                                SizedBox(width: 8),
                                Image.asset(
                                  'images/i_image_new.png',
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(MenuItem menuItem, int quantityInCart, StateSetter localSetState) {
    return Container(
      height: 35,
      width: 100,
      decoration: BoxDecoration(
        color: button_in_color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: button_color, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              if (quantityInCart > 0) {
                _decrementItem(
                  menuItem,
                  Provider.of<Cart>(context, listen: false),
                  portionSize: _selectedPortionSize,
                );
                localSetState(() {
                  quantityInCart = Provider.of<Cart>(context, listen: false)
                      .getQuantity(menuItem.id! + (_selectedPortionSize ?? ""));
                });
              }
            },
            child: const Icon(Icons.remove, size: 20, color: button_color),
          ),
          Text(
            quantityInCart.toString(),
            style: const TextStyle(
              color: button_color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              _incrementItem(menuItem, Provider.of<Cart>(context, listen: false), portionSize: _selectedPortionSize);
              localSetState(() {
                quantityInCart++;
              });
            },
            child: const Icon(Icons.add, size: 20, color: button_color),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(MenuItem menuItem, StateSetter localSetState) {
    return InkWell(
      onTap: () {
        if (menuItem.portionSizes != null && menuItem.portionSizes!.isNotEmpty) {
          _showPortionSizeDialog(menuItem, localSetState);
        } else {
          _incrementItem(menuItem, Provider.of<Cart>(context, listen: false));
          localSetState(() {});
        }
      },
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.green.withOpacity(0.2),
      child: Container(
        height: 35,
        width: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: button_in_color,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: button_color, width: 2),
        ),
        child: Text(
          'ADD',
          style: const TextStyle(
            color: button_color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _incrementItem(MenuItem menuItem, Cart cart, {String? portionSize}) {
    // Determine the price to add based on user's premium status and portion size
    double priceToAdd;

    if (_isPremiumUser) {
      if (portionSize != null && menuItem.portionSizes != null) {
        priceToAdd = (menuItem.portionSizes![portionSize] ?? menuItem.price) * 0.85; // Premium discount
      } else {
        priceToAdd = menuItem.price * 0.85; // Premium discount
      }
    } else {
      if (portionSize != null && menuItem.portionSizes != null) {
        priceToAdd = menuItem.portionSizes![portionSize] ?? menuItem.price; // Regular price
      } else {
        priceToAdd = menuItem.price; // Regular price
      }
    }

    // Create a unique cart item ID including portion size if applicable
    final cartItem = CartItem(
      id: menuItem.id! + (portionSize ?? ""),
      name: '${menuItem.name} (${portionSize ?? "Single"})',
      price: priceToAdd,
      quantity: 1,
      imageUrl: menuItem.imageUrl,
      portionSize: portionSize,
    );

    // Add the item to the cart
    cart.addItem(cartItem);

    // Update the cart state
    _totalCartItems.value = cart.itemCount;
    _totalCartAmount.value = cart.totalAmount;
    _isCartVisible.value = cart.itemCount > 0;

    _triggerCartAnimation(); // Optional: Adds animation for the cart
  }



  void _showPortionSizeDialog(MenuItem menuItem, StateSetter localSetState) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Select Portion Size",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
              SizedBox(height: 20),
              ...menuItem.portionSizes!.entries.map(
                    (entry) => ListTile(
                  title: Text(entry.key),
                  trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
                  onTap: () {
                    _incrementItem(menuItem, Provider.of<Cart>(context, listen: false), portionSize: entry.key);
                    Navigator.pop(context);
                    localSetState(() {});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

// Custom widget for cart icon with badge to avoid unnecessary rebuilds
class CartIconWithBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.shopping_cart, color: Colors.black, size: 28),

          // Use Consumer only for the badge
          Consumer<Cart>(
            builder: (context, cart, child) {
              if (cart.itemCount > 0) {
                return Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink(); // Return empty if itemCount is 0
              }
            },
          ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartPage()),
        );
      },
    );
  }

}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 65.0; // Adjust based on your content height
  @override
  double get maxExtent => 65.0; // Adjust based on your content height

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
