import 'package:book_voyage_demo/discover.dart';
import 'package:book_voyage_demo/drawer.dart';
import 'package:book_voyage_demo/homescreen.dart';
import 'package:book_voyage_demo/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget{
  final String uid;
  const HomePage({super.key, required this.uid});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user=FirebaseAuth.instance.currentUser;
  int _selectedIndex=1;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive=false;
  String _searchQuery='';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearchActive=false;
      _searchQuery='';
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFE8A391),
        child: SingleChildScrollView(
          child: const Scaffold(
            drawer: ,
            backgroundColor: Colors.transparent,
            body:
          ),
        ),
          child: Scaffold(
            key:  _scaffoldKey,
            appBar: AppBar(
              iconTheme: const IconThemeData(
                size: 30,
              color: Color(0xFFECE2D0),
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black45,
                    offset: Offset(1.0, 1.0),
                  ),
                ]// Changes the color of the leading/back icon
            ),
              backgroundColor: Colors.transparent,
              title: Row(
                children: [
                  if (_selectedIndex==0)
                    _isSearchActive ? Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top:10.0, bottom: 10),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (query){
                              setState(() {
                                _searchQuery=query;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: "Search Books",
                              prefixIcon: Icon(Icons.search_sharp),
                              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        )
                    )
                        : const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10,bottom: 2),
                            child: Text('Explore Books', style: TextStyle(
                              fontSize:25, color: Color(0xFFF8F0E3),
                              fontWeight: FontWeight.bold,
                              shadows: [
                              Shadow(
                              blurRadius: 8.0,
                              color: Colors.black45,
                              offset: Offset(2.0, 2.0),
                            ),]),),
                          ),
                        ),
                    ),
                ],
              ),
              actions: _selectedIndex==0 ? [
                IconButton(
                  icon: Icon(_isSearchActive?Icons.close:Icons.search),
                  onPressed: (){
                    setState(() {
                      _isSearchActive=!_isSearchActive;
                      if(_isSearchActive){
                        _searchQuery='';
                      }
                    });
                  },
                )
              ]
                :null
              ),
            bottomNavigationBar: BottomNavigationBar(
                backgroundColor: Color(0xFFF8F0E3),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.search),label: 'Discover'),
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.book),label: 'Book Clubs')
                ],
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              showUnselectedLabels: true,
              unselectedItemColor: Color(0xFFE8A391),
              unselectedLabelStyle: const TextStyle(color: Color(0xFFE8A391),fontWeight: FontWeight.bold),
              selectedItemColor: const Color(0xFF9B2226),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFFE8A391)
              ),
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
            drawer: SideNavigation(),
            backgroundColor: Colors.transparent,
            body: _selectedIndex==0
              ? DiscoverPage(searchQuery: _searchQuery)
                :_selectedIndex==1
              ?HomeScreen(uid: widget.uid)
                :Center(child: Text("Book CLubs Page"),),
          ),
>>>>>>> recommendation
      ),
    );
  }
}