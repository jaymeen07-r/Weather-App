import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCityPage extends StatefulWidget {
  const AddCityPage({super.key});

  @override
  State<AddCityPage> createState() => _AddCityPageState();
}

class _AddCityPageState extends State<AddCityPage> {
  final TextEditingController _cityController = TextEditingController();
  List<String> savedCities = [];
  Set<int> selectedIndexes = {};
  bool selectionMode = false;
  final primaryColor = Color(0xFF0B132B);
  final secondColor = Colors.white.withOpacity(0.25);
  final accentColor = Color(0xFF5BC0BE);

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedCities = prefs.getStringList('cities') ?? [];
    });
  }

  Future<void> _saveCities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('cities', savedCities);
  }

  void _showAddCityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Add City",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter city name",
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.location_city,
                color: Colors.white70,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final cityName = _cityController.text.trim();
                if (cityName.isNotEmpty) {
                  setState(() {
                    savedCities.add(cityName);
                    _saveCities();
                  });
                  _cityController.clear();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Add",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedCities() {
    setState(() {
      savedCities.removeWhere(
        (city) => selectedIndexes.contains(savedCities.indexOf(city)),
      );
      selectedIndexes.clear();
      selectionMode = false;
      _saveCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2A2A72),
        title: const Text(
          "Your Cities",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCityDialog,
          ),
        ],
      ),
      body: savedCities.isEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2A2A72),
                    Color(0xFF009FFD),
                    Color(0xFF00C6FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, color: Colors.white70, size: 80),
                      SizedBox(height: 20),
                      Text(
                        "No cities added yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tap + to add one.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2A2A72),
                    Color(0xFF009FFD),
                    Color(0xFF00C6FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedCities.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedIndexes.contains(index);
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            selectionMode = true;
                            if (isSelected) {
                              selectedIndexes.remove(index);
                            } else {
                              selectedIndexes.add(index);
                            }
                          });
                        },
                        onTap: () {
                          if (selectionMode) {
                            setState(() {
                              if (isSelected) {
                                selectedIndexes.remove(index);
                              } else {
                                selectedIndexes.add(index);
                              }
                              if (selectedIndexes.isEmpty)
                                selectionMode = false;
                            });
                          } else {
                            Navigator.pop(context, savedCities[index]);
                          }
                        },
                        child: Card(
                          color: Colors.white.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(
                              Icons.location_city,
                              color: Colors.white,
                              size: 32,
                            ),
                            title: Text(
                              savedCities[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              "Tap to open",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (selectionMode)
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: _deleteSelectedCities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Delete Selected Cities",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// https://mobbin.com/apps/riot-mobile-ios-1c9df4d4-6153-4ca2-a5f5-b8f9c5677f0d/da23ee0d-5347-42b0-92b6-502e6363c8e5/screens
