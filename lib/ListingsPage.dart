import 'package:flutter/material.dart';
import 'AddListingPage.dart';
import 'AppDrawer.dart';
import 'Listing.dart';
import 'ListingsModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NotificationHandler.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  ListingsPageState createState() => ListingsPageState();
}

class ListingsPageState extends State<ListingsPage> {

  NotificationHandler notificationHandler = NotificationHandler();

  @override
  void initState() {
    super.initState();
    notificationHandler.initializeNotifications();
  }

  ListingsModel listingsModel = ListingsModel();

  String _searchQuery = '';
  String _decorationLabelText = 'Search Address';

  @override
  void didChangeDependencies() {
    print("void ran");
    super.didChangeDependencies();
    final String? searchQuery = ModalRoute.of(context)!.settings.arguments as String?;
    if(searchQuery != null){
      setState((){
        _searchQuery = searchQuery;
        _decorationLabelText = searchQuery;
        _handleSearch(searchQuery);
      });
    }
  }

  Future<void> _saveSearch(String searchQuery) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('searchHistory') ?? [];
    searches.add(searchQuery);
    await prefs.setStringList('searchHistory', searches);
  }

  void _handleSearch(String searchQuery) {
    setState(() {
      _searchQuery = searchQuery.toLowerCase().trim();
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAddListingPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddListingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text("Realty"),
      ),
      drawer: AppDrawer(notificationHandler: notificationHandler),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              children: [
                const SizedBox(width: 55),
                Expanded(
                  child: TextField(
                    // Removed on account of the onSubmitted() being useless otherwise.
                    // To re-add, just uncomment below and comment out _handleSearch in onSubmitted below.
                    // onChanged: (value) {
                    //   if (value.isNotEmpty) {
                    //     _handleSearch(value);
                    //   } else {
                    //     setState(() {});
                    //   }
                    // },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _decorationLabelText = value;
                        _showSnackbar("Search results updated for: $value");
                        _saveSearch(value);
                        _handleSearch(value);
                      }
                      if(value.isEmpty || value.trim() == ''){
                        _decorationLabelText = 'Search Address';
                        _showSnackbar("Search Bar Cleared.");
                        _handleSearch('');
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: _decorationLabelText,
                      // labelText: 'Search Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      fillColor: Colors.grey.shade300,
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: IconButton(
                      onPressed: () => _openAddListingPage(),
                      icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: listingsModel.getListings(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final listing = Listing.fromMap(
                        doc.data() as Map<String, dynamic>,
                        reference: doc.reference,
                      );
                      return listing.address!
                          .toLowerCase()
                          .contains(_searchQuery);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text('No matching results'));
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: filteredDocs
                          .map((DocumentSnapshot document) =>
                          _buildListing(context, document))
                          .toList(),
                    );
                  }
                },
              )
          ),
        ],
      ),
    );
  }

  Widget _buildListing(BuildContext context, DocumentSnapshot productData) {
    final listing = Listing.fromMap(productData.data() as Map<String, dynamic>, reference: productData.reference);
    return ListingWidget(listing: listing);
  }
}