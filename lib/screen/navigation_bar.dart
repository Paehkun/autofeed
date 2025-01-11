import 'package:flutter/material.dart';

class NavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const NavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'H O M E'),
        BottomNavigationBarItem(
            icon: Icon(Icons.access_alarm_rounded), label: 'T I M E R'),
        BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded), label: 'R E P O R T'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded), label: 'P R O F I L E'),
      ],
    );
  }
}
