import 'package:book_voyage_demo/clubdetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookClubChatPage extends StatefulWidget {
  final String clubId;
  final String clubName;
  final String clubImageUrl;

  BookClubChatPage({super.key,
    required this.clubId,
    required this.clubName,
    required this.clubImageUrl,
  });

  @override
  _BookClubChatPageState createState() => _BookClubChatPageState();
}

class _BookClubChatPageState extends State<BookClubChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  // Function to send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return; // Prevent sending empty messages
    }

    String messageText = _messageController.text.trim();
    String senderId = _auth.currentUser!.uid;

    // Fetch the sender's name (optional)
    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(senderId).get();

    String senderName = userDoc.exists
        ? (userDoc.data() as Map<String, dynamic>)['username'] ?? "Unknown User"
        : "Unknown User";

    // Add the message to the Firestore collection
    DocumentReference messageRef = _firestore
        .collection('bookClubs')
        .doc(widget.clubId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'senderId': senderId,
      'senderName': senderName,
      'messageText': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });


    // Clear the message box immediately after sending
    _messageController.clear();

    // Ensure the list scrolls to the latest message
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('bookClubs')
          .doc(widget.clubId)
          .collection('messages')
          .doc(messageId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete message: $e")),
      );
    }
  }
  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Message"),
        content: Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _deleteMessage(messageId);
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Function to navigate to the club details page
  Future<void> _showBookClubDetails() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookClubDetailsPage(clubId: widget.clubId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFE8A391),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Color(0xFFECE2D0),
            title: GestureDetector(
              onTap: _showBookClubDetails,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.clubImageUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.clubName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('bookClubs')
                      .doc(widget.clubId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<DocumentSnapshot> messages = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> messageData = messages[index].data() as Map<String, dynamic>;
                        String messageId = messages[index].id;

                        bool showDateSeparator = false;
                        if (index == 0) {
                          showDateSeparator = true;
                        } else {
                          showDateSeparator = _isDifferentDay(
                              messages[index - 1], messages[index]);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(
                                  messageData['timestamp'] as Timestamp?),
                            _buildMessageBubble(messageData, messageId),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _buildMessageInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF9B2226),
            radius: 25,
            child: IconButton(
              icon: Icon(Icons.send, color: const Color(0xFFECE2D0),),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, String messageId) {
    bool isCurrentUser =
        messageData['senderId'] == _auth.currentUser!.uid;

    String formattedTime = "";
    if (messageData['timestamp'] != null) {
      DateTime messageTime = (messageData['timestamp'] as Timestamp).toDate();
      formattedTime = DateFormat('h:mm a').format(messageTime);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            if (isCurrentUser) {
              _confirmDeleteMessage(messageId);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? const Color(0xFF9B2226) : Color(0xFFECE2D0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: isCurrentUser ? Radius.circular(12) : Radius.zero,
                bottomRight: isCurrentUser ? Radius.zero : Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Text(
                    messageData['senderName'] ?? "Unknown User",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                Text(
                  messageData['messageText'] ?? "",
                  style: TextStyle(
                    fontSize: 16,
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to determine if two messages were sent on different days
  bool _isDifferentDay(
      DocumentSnapshot prevMessage, DocumentSnapshot currMessage) {
    Timestamp? prevTimestamp = prevMessage['timestamp'] as Timestamp?;
    Timestamp? currTimestamp = currMessage['timestamp'] as Timestamp?;

    if (prevTimestamp == null || currTimestamp == null) {
      return false;
    }

    DateTime prevDate = prevTimestamp.toDate();
    DateTime currDate = currTimestamp.toDate();

    return prevDate.day != currDate.day ||
        prevDate.month != currDate.month ||
        prevDate.year != currDate.year;
  }

  // Widget to build the date separator
  Widget _buildDateSeparator(Timestamp? timestamp) {
    if (timestamp == null) {
      return SizedBox.shrink();
    }

    DateTime date = timestamp.toDate();
    String formattedDate = DateFormat('MMMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formattedDate,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
