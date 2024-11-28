import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buy_sms_page.dart';
import 'report_page.dart';
import 'contacts_page.dart';
import '../services/database_service.dart';
import 'redeem_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isActionInProgress = false; // Prevent multiple taps
  final FocusNode _searchFocusNode = FocusNode(); // Add FocusNode for the search bar
  int _currentIndex = 1; // Default selected tab (message page)

  // Debounce function
Future<void> _performAction(Future<void> Function() action) async {
    FocusScope.of(context).unfocus(); // Remove focus before any action
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

  Future<void> _fetchMessages() async {
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
        'https://www.takeawayordering.com/appserver/appserver.php?tag=getmessages&employee_phone=$username&employee_pin=$password&shop_id=$shopId';

    try {
      final response = await http.get(Uri.parse(url));

if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 1) {
          setState(() {
            _messages = List<Map<String, dynamic>>.from(data['contactdetails'].values ?? []);
            _filteredMessages = _messages;
          });
        } else {
          _showErrorDialog('No messages found.');
        }
      } else {
        _showErrorDialog('Failed to fetch messages.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

Future<void> _editMessage(String smsId) async {
  final message = _messages.firstWhere((msg) => msg['id'] == smsId);
  final titleController = TextEditingController(text: message['sms_heading']);
  final detailsController = TextEditingController(text: message['sms_details']);
  final validityController =
      TextEditingController(text: message['sms_valid_for']);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Message'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Message Title'),
            ),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Message Details'),
              maxLines: 3,
            ),
            TextField(
              controller: validityController,
              decoration: const InputDecoration(labelText: 'Number of Days Valid'),
              keyboardType: TextInputType.number,
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
            Navigator.pop(context);
            final credentials = await _getStoredCredentials();
            final username = credentials['username'];
            final password = credentials['password'];
            final shopId = credentials['app_id'];

            final url =
                'https://www.takeawayordering.com/appserver/appserver.php?tag=editmessage&employee_phone=$username&employee_pin=$password&shop_id=$shopId&sms_details=${Uri.encodeComponent(detailsController.text)}&sms_heading=${Uri.encodeComponent(titleController.text)}&sms_type=${message['sms_type']}&sms_valid_for=${validityController.text}&sms_id=$smsId&sms_title=${Uri.encodeComponent(titleController.text)}';

            try {
              final response = await http.get(Uri.parse(url));
              final data = json.decode(response.body);

              if (data['success'] == 1) {
                _showInfoDialog('Message edited successfully!');
                _fetchMessages();
              } else {
                _showErrorDialog('Failed to edit message.');
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


  Future<void> _createMessage() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final validityController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Message Title'),
            ),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Message Details'),
              maxLines: 3,
            ),
            TextField(
              controller: validityController,
              decoration: const InputDecoration(labelText: 'Number of Days Valid'),
              keyboardType: TextInputType.number,
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
              Navigator.pop(context);
              final credentials = await _getStoredCredentials();
              final username = credentials['username'];
              final password = credentials['password'];
              final shopId = credentials['app_id'];

              final url =
                  'https://www.takeawayordering.com/appserver/appserver.php?tag=createmessage&employee_phone=$username&employee_pin=$password&shop_id=$shopId&sms_details=${Uri.encodeComponent(detailsController.text)}&sms_heading=${Uri.encodeComponent(titleController.text)}&sms_type=8&sms_valid_for=${validityController.text}&sms_title=${Uri.encodeComponent(titleController.text)}';

              try {
                print(url);
                final response = await http.get(Uri.parse(url));
                final data = json.decode(response.body);

                if (data['success'] == 1) {
                  _showInfoDialog('Message created successfully!');
                  _fetchMessages();
                } else {
                  _showErrorDialog('Failed to create message.');
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


// Search Functionality

// Search Functionality
void _filterMessages(String query) {
  setState(() {
    _filteredMessages = _messages.where((message) {
      final title = message['sms_heading']?.toLowerCase() ?? '';
      final details = message['sms_details']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          details.contains(query.toLowerCase());
    }).toList();
  });
}

// Clear Search Function
void _clearSearch() {
  setState(() {
    _searchController.clear();
    _filteredMessages = List.from(_messages); // Reset to all messages
  });
}

  Future<void> _activateMessage(String smsId) async {
    final credentials = await _getStoredCredentials();
    final username = credentials['username'];
    final password = credentials['password'];
    final shopId = credentials['app_id'];

    final url =
        'https://www.takeawayordering.com/appserver/appserver.php?tag=activatemessage&employee_phone=$username&employee_pin=$password&shop_id=$shopId&sms_id=$smsId&sms_status=1';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['success'] == 1) {
        _showInfoDialog('Message activated successfully!');
        _fetchMessages();
      } else {
        _showErrorDialog('Failed to activate message.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
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
      // Stay on MessagesPage
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RedeemPage()), // New redeem page
      );
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

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus(); // Remove focus and hide the keyboard
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF075E54),
        centerTitle: true, // Center the title
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createMessage,
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
                    focusNode: _searchFocusNode, // Attach FocusNode to TextField
                    onChanged: _filterMessages,
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: () {
                                _clearSearch();
                                _searchFocusNode.unfocus(); // Explicitly unfocus when clearing
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
                // Messages List
                Expanded(
                  child: _filteredMessages.isEmpty
                      ? const Center(child: Text('No messages found.'))
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            final message = _filteredMessages[index];
                            return Row(
                              children: [
                                // Left Side: Title and Details (Editable)
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: () => _performAction(() => _editMessage(message['id'])),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _highlightSearchText(
                                            message['sms_heading'] ?? 'No Heading',
                                            isTitle: true,
                                          ),
                                          const SizedBox(height: 4),
                                          _highlightSearchText(
                                            message['sms_details'] ?? 'No details',
                                            isTitle: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Right Side: Tick and Validity
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          message['sms_active'] == '1'
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          color: message['sms_active'] == '1'
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 28,
                                        ),
                                        onPressed: message['sms_active'] == '0'
                                            ? () => _performAction(() => _activateMessage(message['id']))
                                            : null,
                                      ),
                                      Text(
                                        '${message['sms_valid_for'] ?? 'N/A'} days',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Redeem'), // New item
    BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Buy'),
  ],
),
   ),
  );
}

Widget _highlightSearchText(String text, {bool isTitle = false}) {
  final query = _searchController.text.toLowerCase();
  if (query.isEmpty || !text.toLowerCase().contains(query)) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontWeight: isTitle ? FontWeight.bold : FontWeight.normal, // Bold only for titles
      ),
    );
  }

  final startIndex = text.toLowerCase().indexOf(query);
  final endIndex = startIndex + query.length;

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: text.substring(0, startIndex),
          style: TextStyle(
            color: Colors.black,
            fontWeight: isTitle ? FontWeight.bold : FontWeight.normal, // Bold only for titles
          ),
        ),
        TextSpan(
          text: text.substring(startIndex, endIndex),
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Colors.green, // Highlighted text
          ),
        ),
        TextSpan(
          text: text.substring(endIndex),
          style: TextStyle(
            color: Colors.black,
            fontWeight: isTitle ? FontWeight.bold : FontWeight.normal, // Bold only for titles
          ),
        ),
      ],
    ),
  );
}
}


