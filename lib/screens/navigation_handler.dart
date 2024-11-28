import 'package:flutter/material.dart';
import 'message_page.dart';
import 'contacts_page.dart';
import 'buy_sms_page.dart';
import 'report_page.dart';

class NavigationHandler extends StatefulWidget {
  final int initialIndex;

  const NavigationHandler({Key? key, required this.initialIndex})
      : super(key: key);

  @override
  State<NavigationHandler> createState() => _NavigationHandlerState();
}

class _NavigationHandlerState extends State<NavigationHandler> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    MessagePage(),
    ContactsPage(),
    BuySMSPage(),
    ReportPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF075E54),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Buy SMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
