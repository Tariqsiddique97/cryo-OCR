import 'package:airgas/constant/assets_image.dart';
import 'package:airgas/dashboard/dashboard.dart';
import 'package:flutter/material.dart';

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({super.key});

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MessengerScreen(),

    Container(
      child: Center(
        child: Text(
          "Coming Soon ",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    ),
    Container(
      child: Center(
        child: Text(
          "Coming Soon ",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    ),
    Container(
      child: Center(
        child: Text(
          "Coming Soon ",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    ),
  ];

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(AssetsScreen.iconsHome),
            label: "",
          ),
          // BottomNavigationBarItem(
          //   icon: Image.asset(AssetsScreen.iconsTankSite),
          //   label: '',
          // ),
          BottomNavigationBarItem(
            icon: Image.asset(AssetsScreen.iconsSearch),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(AssetsScreen.iconsSwitch),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(AssetsScreen.iconsAddress),
            label: '',
          ),
        ],
      ),
    );
  }
}
