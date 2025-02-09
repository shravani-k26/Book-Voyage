import 'package:book_voyage_demo/drawer.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget{
  final String searchQuery;
  const DiscoverPage({super.key, required this.searchQuery});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFE8A391),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body:SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.only(top:15,bottom:8,right: 8, left: 8),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF8F0E3),
                          width: 5, // Border width
                        ),
                      ),
                      child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.75, // Adjust the opacity value to control transparency (0.0 to 1.0)
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/images/mystery.jpg",
                                  fit: BoxFit.cover, // Make the image cover the container
                                ),
                              ),
                            ),
                            const Center(child: Text("Mystery", style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(3.0, 3.0),
                                  )
                                ]
                            ),
                            ),
                            ),
                          ]
                    ),
                  )
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF8F0E3), // White border
                          width: 5, // Border width
                        ),
                      ),
                      child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.75, // Adjust the opacity value to control transparency (0.0 to 1.0)
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/images/romantic.jpg",
                                  fit: BoxFit.cover, // Make the image cover the container
                                ),
                              ),
                            ),
                            const Center(child: Text("Romantic", style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(3.0, 3.0),
                                  )
                                ]
                            ),
                            ),
                            ),
                          ]
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF8F0E3), // White border
                          width: 5, // Border width
                        ),
                      ),
                      child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.75, // Adjust the opacity value to control transparency (0.0 to 1.0)
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/images/self.jpg",
                                  fit: BoxFit.cover, // Make the image cover the container
                                ),
                              ),
                            ),
                            const Center(child: Text("Self Help", style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(3.0, 3.0),
                                  )
                                ]
                            ),
                            ),
                            ),
                          ]
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF8F0E3), // White border
                          width: 5, // Border width
                        ),
                      ),
                      child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.75, // Adjust the opacity value to control transparency (0.0 to 1.0)
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/images/educational.jpg",
                                  fit: BoxFit.cover, // Make the image cover the container
                                ),
                              ),
                            ),
                            const Center(child: Text("Educational", style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(3.0, 3.0),
                                  )
                                ]
                            ),
                            ),
                            ),
                          ]
                      ),
                    )
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFFF8F0E3), // White border
                          width: 5, // Border width
                        ),
                      ),
                      child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.75, // Adjust the opacity value to control transparency (0.0 to 1.0)
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/images/adventure.jpg",
                                  fit: BoxFit.cover, // Make the image cover the container
                                ),
                              ),
                            ),
                            const Center(child: Text("Adventure", style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(3.0, 3.0),
                                  )
                                ]
                            ),
                            ),
                            ),
                          ]
                      ),
                    )
                ),
              ],
            ),
          ),
           ),
          ),
    );
  }
}