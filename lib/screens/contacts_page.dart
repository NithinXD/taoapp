import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buy_sms_page.dart';
import 'report_page.dart';
import 'message_page.dart';
import 'redeem_page.dart';
import '../services/database_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isActionInProgress = false;
  final FocusNode _searchFocusNode = FocusNode();
  int _currentIndex = 0;

  Future<void> _performAction(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    if (_isActionInProgress) return;
    setState(() {
      _isActionInProgress = true;
    });
    try {
      await action();
    } finally {
      setState(() {
        _isActionInProgress = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getStoredCredentials() async {
    final credentials = await DatabaseHelper.instance.fetchCredentials();
    if (credentials.isNotEmpty) {
      return credentials.first;
    }
    return {};
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessagePage()),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RedeemPage()),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReportPage()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BuySMSPage()),
      );
      break;
    }
  }

  Future<void> _fetchContacts() async {
    final credentials = await _getStoredCredentials();
    if (credentials.isEmpty) {
      _showErrorDialog('No stored credentials found.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final username = credentials['username'];
    final password = credentials['password'];
    final shopId = credentials['app_id'];

    final url =
        'https://www.takeawayordering.com/appserver/appserver.php?tag=getcontacts&employee_phone=$username&employee_pin=$password&shop_id=$shopId';
    try {
      final response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 1) {
          final contactDetails = data['contactdetails'] as Map<String, dynamic>? ?? {};
          setState(() {
            _contacts = contactDetails.values.map((e) => Map<String, dynamic>.from(e)).toList();
            _filteredContacts = _contacts;
          });
        } else {
          _showErrorDialog('No contacts found.');
        }
      } else {
        _showErrorDialog('Failed to fetch contacts.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _editContact(String? contactId) async {
  if (contactId == null) {
    _showErrorDialog('Contact ID is missing.');
    return;
  }

  // Find the selected contact
  final contact = _contacts.firstWhere(
    (c) => c['id'] == contactId,
    orElse: () => {},
  );

  if (contact.isEmpty) {
    _showErrorDialog('Contact not found.');
    return;
  }

  // Initialize controllers with existing contact details
  final firstNameController =
      TextEditingController(text: contact['contact_firstname'] ?? '');
  final lastNameController =
      TextEditingController(text: contact['contact_lastname'] ?? '');
  final mobileController =
      TextEditingController(text: contact['contact_mobile'] ?? '');
  final emailController =
      TextEditingController(text: contact['contact_email'] ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          TextField(
            controller: firstNameController,
            decoration: const InputDecoration(labelText: 'First Name *'),
          ),
          TextField(
            controller: lastNameController,
            decoration: const InputDecoration(labelText: 'Last Name'),
          ),
          TextField(
            controller: mobileController,
            decoration: const InputDecoration(labelText: 'Phone Number *'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validation
            if (firstNameController.text.isEmpty || mobileController.text.isEmpty) {
              _showErrorDialog('First name and mobile number are required.');
              return;
            }

            Navigator.pop(context);

            // Get updated values
            final updatedFirstName = firstNameController.text;
            final updatedLastName = lastNameController.text;
            final updatedMobile = mobileController.text;
            final updatedEmail = emailController.text;

            // Call the API to update the contact
            final credentials = await _getStoredCredentials();
            final username = credentials['username'];
            final password = credentials['password'];
            final shopId = credentials['app_id'];

            final url =
                'https://www.takeawayordering.com/appserver/appserver.php?tag=editcontact'
                '&employee_phone=$username'
                '&employee_pin=$password'
                '&shop_id=$shopId'
                '&contact_id=$contactId'
                '&contact_firstname=${Uri.encodeComponent(updatedFirstName)}'
                '&contact_lastname=${Uri.encodeComponent(updatedLastName)}'
                '&contact_mobile=${Uri.encodeComponent(updatedMobile)}'
                '&contact_email=${Uri.encodeComponent(updatedEmail)}';

            try {
              final response = await http.get(Uri.parse(url));
              final data = json.decode(response.body);

              if (response.statusCode == 200 && data['success'] == 1) {
                _showInfoDialog('Contact edited successfully!');

                // Update the contact locally
                setState(() {
                  contact['contact_firstname'] = updatedFirstName;
                  contact['contact_lastname'] = updatedLastName;
                  contact['contact_mobile'] = updatedMobile;
                  contact['contact_email'] = updatedEmail;
                });

                _fetchContacts(); // Optional: Refresh the contacts list from the server
              } else {
                _showErrorDialog('Failed to edit contact. Reason: ${data['message'] ?? 'Unknown error.'}');
              }
            } catch (e) {
              _showErrorDialog('An error occurred: $e');
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> _showVoucherHistory(String contactId, String contactMobile) async {
  final url =
      'https://www.takeawayordering.com/appserver/appserver.php?tag=getcontactvoucher&employee_phone=spicebag&employee_pin=sp1ceb@g&shop_id=37&contact_id=$contactId&contact_mobile=$contactMobile';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == 1) {
        final voucherDetails = List<Map<String, dynamic>>.from(
            (data['contactdetails'] as Map<String, dynamic>).values);
        List<Map<String, dynamic>> filteredVouchers = List.from(voucherDetails);
        final TextEditingController searchController = TextEditingController();

        // Dialog with search and list view
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voucher History'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredVouchers = voucherDetails.where((voucher) {
                          final details =
                              voucher['sms_details']?.toLowerCase() ?? '';
                          final code =
                              voucher['voucher_code']?.toLowerCase() ?? '';
                          return details.contains(query.toLowerCase()) ||
                              code.contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search vouchers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  itemCount: filteredVouchers.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final voucher = filteredVouchers[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Voucher Code: ${voucher['voucher_code'] ?? 'N/A'}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text("Details: ${voucher['sms_details'] ?? 'N/A'}"),
                        Text("Discount: ${voucher['sms_discount_amount']}%"),
                        Text("Valid For: ${voucher['sms_valid_for']} days"),
                        Text(
                          "Status: ${voucher['sms_voucher_status'] == '1' ? 'Active' : 'Inactive'}",
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      } else {
        _showErrorDialog('No vouchers found for this contact.');
      }
    } else {
      _showErrorDialog('Failed to fetch voucher history.');
    }
  } catch (e) {
    _showErrorDialog('An error occurred while fetching voucher history: $e');
  }
}

Future<void> _createContact() async {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firstNameController,
            decoration: const InputDecoration(labelText: 'First Name *'),
          ),
          TextField(
            controller: lastNameController,
            decoration: const InputDecoration(labelText: 'Last Name'),
          ),
          TextField(
            controller: mobileController,
            decoration: const InputDecoration(labelText: 'Phone Number *'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validation
            if (firstNameController.text.isEmpty || mobileController.text.isEmpty) {
              _showErrorDialog('First name and mobile number are required.');
              return;
            }

            Navigator.pop(context);
            final credentials = await _getStoredCredentials();
            final username = credentials['username'];
            final password = credentials['password'];
            final shopId = credentials['app_id'];

            final url =
                'https://www.takeawayordering.com/appserver/appserver.php?tag=createcontact'
                '&employee_phone=$username'
                '&employee_pin=$password'
                '&shop_id=$shopId'
                '&contact_firstname=${Uri.encodeComponent(firstNameController.text)}'
                '&contact_lastname=${Uri.encodeComponent(lastNameController.text)}'
                '&contact_mobile=${Uri.encodeComponent(mobileController.text)}'
                '&contact_email=${Uri.encodeComponent(emailController.text)}';

            try {
              final response = await http.get(Uri.parse(url));
              final data = json.decode(response.body);

              if (data['success'] == 1) {
                _showInfoDialog('Contact created successfully!');
                _fetchContacts();
              } else {
                _showErrorDialog('Failed to create contact.');
              }
            } catch (e) {
              _showErrorDialog('An error occurred: $e');
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}


  Future<void> _sendSms(String contactId) async {
  final credentials = await _getStoredCredentials();
  if (credentials.isEmpty) {
    _showErrorDialog('No stored credentials found.');
    return;
  }

  final username = credentials['username'];
  final password = credentials['password'];
  final shopId = credentials['app_id'];

  final url =
      'https://www.takeawayordering.com/appserver/appserver.php?tag=sendsmscontact&employee_phone=$username&employee_pin=$password&shop_id=$shopId&contact_id=$contactId&contact_status=SENDSMS';

  try {
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == 1) {
      _showInfoDialog('SMS sent successfully!');
    } else {
      _showErrorDialog('Failed to send SMS. Reason: ${data['message'] ?? 'Unknown error.'}');
    }
  } catch (e) {
    _showErrorDialog('An error occurred while sending SMS: $e');
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

// Filters the contacts based on the search query
void _filterContacts(String query) {
  setState(() {
    _filteredContacts = _contacts.where((contact) {
      final name = '${contact['contact_firstname']} ${contact['contact_lastname']}'.toLowerCase();
      final phone = contact['contact_mobile']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || phone.contains(query.toLowerCase());
    }).toList();
  });
}

// Clears the search input and resets the filtered contacts
void _clearSearch() {
  setState(() {
    _searchController.clear();
    _filteredContacts = List.from(_contacts); // Reset to all contacts
  });
}


  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Contacts'),
      centerTitle: true, // Center the title
      backgroundColor: const Color(0xFF075E54),
      foregroundColor: Colors.white,
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _createContact,
      backgroundColor: const Color(0xFF075E54),
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => _filterContacts(value),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              _clearSearch();
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              // Contacts List
              Expanded(
                child: _filteredContacts.isEmpty
                    ? const Center(child: Text('No contacts found.'))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final name =
                              '${contact['contact_firstname']} ${contact['contact_lastname']}'.trim();
                          final phone = contact['contact_mobile'] ?? 'No Phone Number';
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: contact['contact_type'] == '1'
                                  ? Colors.yellow
                                  : contact['contact_type'] == '2'
                                      ? Colors.green
                                      : Colors.blue,
                            ),
                            title: Text(
                              phone.isNotEmpty ? phone : 'No Phone Number',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              name.isNotEmpty ? name : 'No Name',
                              style: const TextStyle(color: Colors.black),
                            ),
                            trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.history, color: Colors.blue),
      onPressed: () {
        final contactId = contact['id'];
        final contactMobile = contact['contact_mobile'];
        if (contactId != null && contactMobile != null) {
          _showVoucherHistory(contactId.toString(), contactMobile.toString());
        } else {
          _showErrorDialog('Contact ID or mobile number is missing.');
        }
      },
      tooltip: 'View Voucher History',
    ),
    IconButton(
      icon: const Icon(Icons.message, color: Colors.green),
      onPressed: () {
        final contactId = contact['id'];
        if (contactId != null) {
          _sendSms(contactId.toString());
        } else {
          _showErrorDialog('Contact ID is missing.');
        }
      },
      tooltip: 'Send Message',
    ),
  ],
),


                          );
                        },
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.black,
                          thickness: 1,
                          height: 1,
                        ),
                      ),
              ),
            ],
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