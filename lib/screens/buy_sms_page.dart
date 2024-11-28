import 'package:flutter/material.dart';
import 'contacts_page.dart';
import 'message_page.dart';
import 'redeem_page.dart';
import 'report_page.dart';

class BuySMSPage extends StatefulWidget {
  const BuySMSPage({Key? key}) : super(key: key);

  @override
  State<BuySMSPage> createState() => _BuySMSPageState();
}

class _BuySMSPageState extends State<BuySMSPage> {
  int _currentIndex = 4; // Default selected tab for BuySMSPage

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ContactsPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MessagePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RedeemPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportPage()),
        );
        break;
      case 4:
        // Stay on Buy SMS Page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy SMS')),
      body: const Center(child: Text('Buy SMS Page Content')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        selectedItemColor: const Color(0xFF075E54),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Redeem'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Buy'),
        ],
      ),
    );
  }
}
