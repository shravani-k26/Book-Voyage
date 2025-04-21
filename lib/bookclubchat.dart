import 'package:book_voyage_demo/clubdetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookClubChatPage extends StatefulWidget {
  final String clubId;
  final String clubName;
  final String clubImageUrl;
  final String userId;

  BookClubChatPage({super.key,
    required this.clubId,
    required this.clubName,
    required this.clubImageUrl,
    required this.userId
  });

  @override
  _BookClubChatPageState createState() => _BookClubChatPageState();
}

class _BookClubChatPageState extends State<BookClubChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  List<String> _clubMemberIds = [];

  void markMessagesAsRead(String userId, String clubId) async {
    final firestore = FirebaseFirestore.instance;
    final messages = await firestore
        .collection('bookClubs')
        .doc(clubId)
        .collection('messages')
        .where('readBy', whereNotIn: [userId])
        .get();
    for (var doc in messages.docs) {
      // Exclude the current user's own messages
      if (doc['senderId'] != userId) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }

  // Function to send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    String messageText = _messageController.text.trim();
    String senderId = _auth.currentUser!.uid;

    _messageController.clear();

    // Fetch the sender's name
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
      'deliveredTo': [],
      'readBy': [senderId],
    });


    // Clear the message box immediately after sending
    _messageController.clear();

    // Ensure the list scrolls to the latest message
    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
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
            child: Text("Cancel",style: TextStyle(color: Color(0xFFE07A5F),),),
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

  void _markMessagesAsDeliveredAndRead(List<DocumentSnapshot> messages) {
    String userId = _auth.currentUser!.uid;
    for (var doc in messages) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String messageId = doc.id;

      if (data['senderId'] == userId) continue;

      if (!(data['deliveredTo'] ?? []).contains(userId)) {
        _firestore
            .collection('bookClubs')
            .doc(widget.clubId)
            .collection('messages')
            .doc(messageId)
            .update({
          'deliveredTo': FieldValue.arrayUnion([userId]),
        });
      }

      if (!(data['readBy'] ?? []).contains(userId)) {
        _firestore
            .collection('bookClubs')
            .doc(widget.clubId)
            .collection('messages')
            .doc(messageId)
            .update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }
  void _fetchClubMembers() async {
    DocumentSnapshot clubDoc = await _firestore.collection('bookClubs').doc(widget.clubId).get();
    if (clubDoc.exists) {
      setState(() {
        _clubMemberIds = List<String>.from(clubDoc['members'] ?? []);
      });
    }
  }
  @override
  void initState() {
    super.initState();
    markMessagesAsRead(widget.userId, widget.clubId);
    _fetchClubMembers();
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

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markMessagesAsDeliveredAndRead(messages);
                    });

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
                            FadingMessageBubble(child: _buildMessageBubble(messageData, messageId)),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentUser ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(messageData),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Map<String, dynamic> messageData) {
    List deliveredTo = messageData['deliveredTo'] ?? [];
    List readBy = messageData['readBy'] ?? [];
    String senderId = messageData['senderId'];

    // Remove sender from members
    List<String> recipients = _clubMemberIds.where((id) => id != senderId).toList();

    bool allRead = recipients.every((id) => readBy.contains(id));
    bool anyDelivered = recipients.any((id) => deliveredTo.contains(id));

    if (allRead) {
      return Icon(Icons.done_all, size: 18, color: Colors.blue);
    } else if (anyDelivered) {
      return Icon(Icons.done_all, size: 18, color: Colors.grey);
    } else {
      return Icon(Icons.check, size: 18, color: Colors.grey);
    }
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
class FadingMessageBubble extends StatefulWidget {
  final Widget child;

  const FadingMessageBubble({required this.child, Key? key}) : super(key: key);

  @override
  _FadingMessageBubbleState createState() => _FadingMessageBubbleState();
}

class _FadingMessageBubbleState extends State<FadingMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

