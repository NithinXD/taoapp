import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buy_sms_page.dart';
import 'report_page.dart';
import 'contacts_page.dart';
import '../services/database_service.dart';
import 'message_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voucher Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RedeemPage(),
    );
  }
}

class RedeemPage extends StatefulWidget {
  const RedeemPage({Key? key}) : super(key: key);

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filteredVouchers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _currentIndex = 2; // Default selected tab (redeem page)

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    const url =
        "https://www.takeawayordering.com/appserver/appserver.php?tag=getvouchers&employee_phone=spicebag&employee_pin=sp1ceb@g&shop_id=37";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 1) {
          setState(() {
            _vouchers = List<Map<String, dynamic>>.from(data['contactdetails'].values);
            _filteredVouchers = _vouchers;
            _isLoading = false;
          });
        } else {
          _showErrorDialog("No vouchers found.");
        }
      } else {
        _showErrorDialog("Failed to fetch vouchers.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    }
  }

  Future<void> _redeemVoucher(String voucherId, String contactMobile) async {
    final url =
        "https://www.takeawayordering.com/appserver/appserver.php?tag=redeemvoucher&employee_phone=spicebag&employee_pin=sp1ceb@g&shop_id=37&voucher_id=$voucherId&contact_mobile=$contactMobile";

    try {
      print(url);
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['success'] == 1) {
        _showInfoDialog("Voucher redeemed successfully!");
        _fetchVouchers();
      } else {
        _showErrorDialog("Failed to redeem voucher.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    }
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _filterVouchers(String query) {
    setState(() {
      _filteredVouchers = _vouchers.where((voucher) {
        final recipient = voucher['sms_recipient']?.toLowerCase() ?? '';
        final details = voucher['sms_details']?.toLowerCase() ?? '';
        return recipient.contains(query.toLowerCase()) ||
            details.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredVouchers = _vouchers;
    });
  }

  void _showRedeemVoucherDialog() {
    showDialog(
      context: context,
      builder: (_) => _RedeemVoucherDialog(onVoucherCreated: _fetchVouchers),
    );
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Navigate to respective pages
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
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BuySMSPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Voucher"),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _filterVouchers,
                    decoration: InputDecoration(
                      hintText: 'Search vouchers...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredVouchers.isEmpty
                      ? const Center(child: Text('No vouchers found.'))
                      : ListView.separated(
                          itemCount: _filteredVouchers.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final voucher = _filteredVouchers[index];
                            return ListTile(
                              title: Text(
                                "Phone: ${voucher['sms_recipient'] ?? 'N/A'}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Voucher: ${voucher['voucher_code'] ?? 'N/A'}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(voucher['sms_details'] ?? "No Details"),
                                ],
                              ),
                              trailing: IconButton(
  icon: Icon(
    Icons.check_circle,
    color: voucher['sms_voucher_status'] == '1' ? Colors.green : Colors.grey,
    size: 28, // Adjust the size of the icon as needed
  ),
   onPressed: () => _redeemVoucher(
      voucher['id'],
      voucher['sms_recipient'],
    ),
),

                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRedeemVoucherDialog,
        backgroundColor: const Color(0xFF075E54),
        child: const Icon(Icons.add),
      ),
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

class _RedeemVoucherDialog extends StatelessWidget {
  final VoidCallback onVoucherCreated;

  const _RedeemVoucherDialog({Key? key, required this.onVoucherCreated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController mobileController = TextEditingController();
    final TextEditingController voucherController = TextEditingController();

    void _redeemVoucher() {
      final mobile = mobileController.text.trim();
      final voucher = voucherController.text.trim();

      if (mobile.isEmpty || voucher.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Error"),
            content: Text("Please fill in both fields."),
          ),
        );
        return;
      }

      Navigator.pop(context);
      onVoucherCreated();
    }

    return AlertDialog(
      title: const Text("Redeem Voucher"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: mobileController,
            decoration: InputDecoration(
              labelText: "Mobile Number",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: voucherController,
            decoration: InputDecoration(
              labelText: "Voucher Code",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _redeemVoucher, child: const Text("Redeem")),
      ],
    );
  }
}
