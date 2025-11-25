import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:book_voyage_demo/home.dart';
import 'package:fluttertoast/fluttertoast.dart';

class InterestsPage extends StatefulWidget{
  final String uid;
  InterestsPage({required this.uid});
  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final List<String>allInterests=['Mystery','Romance','Sci-Fi','Self Help','Adventure','Suspense','Psychological Thriller','Educational','Information Technology'];
  final Set<String> selectedInterests = {};
  bool isLoading = false;
  Future<void> fetchInterests() async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        // Check if 'interests' field exists and is not null
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData != null && userData['interests'] != null) {
          List<dynamic> interestsFromFirestore = userData['interests'] ?? [];
          setState(() {
            selectedInterests.addAll(interestsFromFirestore.map((e) => e.toString()));
          });
        } else {
          // Handle case where 'interests' field doesn't exist or is empty
          print('No interests field found or field is empty for user: ${widget.uid}');
        }
      }
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching interests: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }
  Icon _getInterestIcon(String interest) {
    switch (interest) {
      case 'Mystery':
        return Icon(Icons.search); // Magnifying glass for Mystery
      case 'Romance':
        return Icon(Icons.favorite); // Heart for Romance
      case 'Sci-Fi':
        return Icon(Icons.rocket_launch); // Rocket for Sci-Fi
      case 'Self Help':
        return Icon(Icons.lightbulb); // Lightbulb for Self Help
      case 'Adventure':
        return Icon(Icons.terrain); // Mountain for Adventure
      case 'Suspense':
        return Icon(Icons.movie); // Film reel for Suspense
      case 'Psychological Thriller':
        return Icon(Icons.psychology); // Brain for Psychological Thriller
      case 'Educational':
        return Icon(Icons.school); // School for Educational
      case 'Information Technology':
        return Icon(Icons.laptop_mac); // Laptop for IT
      default:
        return Icon(Icons.help_outline); // Default icon if unknown interest
    }
  }
  Future<void>saveInterests() async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      await _firestore.collection('users').doc(widget.uid).update({
        'interests': selectedInterests.toList(),
      });
      Fluttertoast.showToast(
        msg: "Interests saved successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor:Color(0xFFECE2D0).withOpacity(0.9),
        textColor: Colors.black,
        fontSize: 16.0,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(uid: widget.uid)),
      );
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving interests: $e')),
      );
    }
    finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }
  @override
  void initState() {
    super.initState();
    fetchInterests(); // Fetch interests when the page is initialized
  }
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECE2D0),Color(0xFFE07A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("Select your Interests",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0XFF9B2226),shadows:[Shadow(offset: Offset(1.0, 1.0),blurRadius: 2.0,color: Color(0xFFE07A5F))] ),
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height*6,
                            child: ListView(
                              children: allInterests.asMap().entries.map((entry){
                                int index=entry.key;
                                String interest=entry.value;
                                return Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Card(
                                      shadowColor: Color(0xFFEFC9BF),
                                      elevation: 5,
                                      color: Color(0xFFECE2D0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: ListTile(
                                              splashColor: Color(0xFFEDA38F),
                                              title: Row(
                                                children: [
                                                  _getInterestIcon(interest),
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(interest, style: TextStyle(fontSize: 16, ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              leading: Checkbox(
                                                activeColor: const Color(0xFF9B2226),
                                                  value: selectedInterests.contains(interest),
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        selectedInterests.add(interest);
                                                      } else {
                                                        selectedInterests.remove(interest);
                                                      }
                                                    });
                                                  },
                                              ),
                                              onTap: () {
                                                // Toggle the checkbox state when the ListTile is tapped
                                                setState(() {
                                                  if (selectedInterests.contains(interest)) {
                                                    selectedInterests.remove(interest);
                                                  } else {
                                                    selectedInterests.add(interest);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                    ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top:20, bottom: 40,left:20, right: 20),
                child: Container(
                  width: double.infinity,
                  child: isLoading
                      ?Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                      onPressed: (){
                        saveInterests();
                      },
                      child:const Text("Save Interest", style: TextStyle(fontSize: 18, color: Colors.white), ),
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        backgroundColor: Color(0xFF9B2226),
                        foregroundColor: Colors.white
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Color(0xFFE07A5F).withOpacity(0.2); // Splash effect color
                            }
                            return null; // Default splash color
                          },
                        ),
                      ),
                  ),
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}